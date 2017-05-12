package Dist::Zilla::Plugin::Lump;

our $DATE = '2016-02-14'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileFinderUser' =>
        {default_finders=>[':InstallModules']},
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::MetaProvider',
);

use Data::Dmp;
use App::lcpan::Call qw(call_lcpan_script);
use File::Slurper qw(read_binary);
use Module::Path::More qw(module_path);

#has lump_module => (is=>'rw');
has lump_dist => (is=>'rw');
has lump_dist_and_deps => (is=>'rw');
has include_author => (is=>'rw');

sub mvp_multivalue_args { qw(include_author lump_dist lump_dist_and_deps) }

use namespace::autoclean;

sub gather_files {
    use experimental 'smartmatch';

    my $self = shift;

    my @lump_mods; # to be added in our dist
    my %dep_mods;  # to stay as deps

    ## lump_module
    #{
    #    last unless $self->lump_module;
    #    for my $mod (@{ $self->lump_module }) {
    #        push @lump_mods, $mod unless $mod ~~ @lump_mods;
    #    }
    #}

    # lump_dist
    {
        last unless $self->lump_dist;
        my @mods = @{ $self->lump_dist };
        for (@mods) {
            s/-/::/g;
        }
        my $res = call_lcpan_script(
            argv=>["mods-from-same-dist", "--latest", @mods]);
        $self->log_fatal(["Can't lcpan mods-from-same-dist: %s - %s", $res->[0], $res->[1]])
            unless $res->[0] == 200;
        for my $mod (@{$res->[2]}) {
            push @lump_mods, $mod unless $mod ~~ @lump_mods;
        }
    }

    # lump_dist_and_deps
    {
        last unless $self->lump_dist_and_deps;
        my @mods1 = @{ $self->lump_dist_and_deps };
        for (@mods1) {
            s/-/::/g;
        }
        my $res = call_lcpan_script(
            argv=>["mods-from-same-dist", "--latest", @mods1]);
        $self->log_fatal(["Can't lcpan mods-from-same-dist: %s - %s", $res->[0], $res->[1]])
            unless $res->[0] == 200;
        my @mods2 = @{$res->[2]};
        $res = call_lcpan_script(argv => ['deps', '-R', @$res]);
        $self->log_fatal(["Can't lcpan deps: %s - %s", $res->[0], $res->[1]])
            unless $res->[0] == 200;
        my @mods3;
        for my $rec (@{$res->[2]}) {
            my $lump = 0;
            my $mod = $rec->{module};
            $mod =~ s/\A\s+//;

            # decide whether we should lump this module or not
          DECIDE:
            {
                if ($self->include_author && @{ $self->include_author }) {
                    last DECIDE unless $rec->{author} ~~ @{ $self->include_author };
                }
                $lump = 1;
            }

            if ($lump) {
                push @mods3, $mod;
            } else {
                $dep_mods{$mod} = $rec->{version};
            }
        }
        $res = call_lcpan_script(argv => ['mods-from-same-dist', '--latest', @mods3]);
        $self->log_fatal(["Can't lcpan mods-from-same-dist: %s - %s", $res->[0], $res->[1]])
            unless $res->[0] == 200;
        my @mods4 = @{$res->[2]};

        for my $mod (@mods2, @mods4) {
            push @lump_mods, $mod unless $mod ~~ @lump_mods;
        }
    }
    @lump_mods = sort @lump_mods;

    my @lump_dists;
    {
        last unless @lump_mods;
        my $res = call_lcpan_script(argv => ['mod2dist', @lump_mods]);
        $self->log_fatal(["Can't lcpan mod2dist: %s - %s", $res->[0], $res->[1]])
            unless $res->[0] == 200;
        if (@lump_mods == 1) {
            push @lump_dists, $res->[2];
        } else {
            for (values %$res) {
                push @lump_dists, $_ unless $_ ~~ @lump_dists;
            }
        }
    }
    @lump_dists = sort @lump_dists;

    $self->log_debug(["modules to lump into dist: %s", \@lump_mods]);
    $self->log_debug(["dists lumped into dist: %s", \@lump_dists]);
    $self->log_debug(["modules to add as deps: %s", \%dep_mods]);

    $self->{_lump_mods} = \@lump_mods;
    $self->{_lump_dists} = \@lump_dists;

    my $meta_no_index = {};

    for my $mod (@lump_mods) {
        my $path = module_path(module => $mod);
        $self->log_fatal(["Can't find path for module %s, make sure the module is installed", $mod])
            unless $path;

        my $mod_pm = $mod;
        $mod_pm =~ s!::!/!g;
        $mod_pm .= ".pm";

        my $ct = read_binary($path);

      MUNGE:
        {
            # adjust dist name
            $ct =~ s/^(=head1 VERSION\s+[^\n]+from Perl distribution )[\w-]+(?: version [^)\s]+)*/
                $1 . $self->zilla->name . " version " . $self->zilla->version/ems;
        }

        my $file_path = "lib/$mod_pm";
        my $file = Dist::Zilla::File::InMemory->new(
            name    => $file_path,
            content => $ct,
        );
        push @{ $meta_no_index->{file} }, $file_path;

        $self->add_file($file);
    }
    $self->{_meta_no_index} = $meta_no_index;

    for my $mod (keys %dep_mods) {
        $self->zilla->register_prereqs($mod => $dep_mods{$mod});
    }
}

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;

    my $content = $file->content;
    my $munged = 0;

    $munged++ if $content =~ s/^(#\s*LUMPED_MODULES)$/"our \@LUMPED_MODULES = \@{" . dmp($self->{_lump_mods} ) . "}; $1"/em;
    $munged++ if $content =~ s/^(#\s*LUMPED_DISTS)$/  "our \@LUMPED_DISTS   = \@{" . dmp($self->{_lump_dists}) . "}; $1"/em;
    $munged++ if $content =~ s/^(#\s*LUMPED_MODULES_POD)$/"=over\n\n" . join("", map { "=item * $_\n\n" } @{ $self->{_lump_mods}  }) . "=back\n\n"/em;
    $munged++ if $content =~ s/^(#\s*LUMPED_DISTS_POD)$/  "=over\n\n" . join("", map { "=item * $_\n\n" } @{ $self->{_lump_dists} }) . "=back\n\n"/em;
    $file->content($content) if $munged;
}

sub metadata {
    my $self = shift;

    { no_index => $self->{_meta_no_index} };
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Lump other modules/dists together into dist

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Lump - Lump other modules/dists together into dist

=head1 VERSION

This document describes version 0.10 of Dist::Zilla::Plugin::Lump (from Perl distribution Dist-Zilla-Plugin-Lump), released on 2016-02-14.

=head1 SYNOPSIS

In C<dist.ini>:

 ; it is recommended that the name of lump dist ends with '-Lumped'
 name=Perinci-CmdLine-Any-Lumped

 version=0.01

 ; you should use minimal plugins and avoid those that munge files (e.g.
 ; OurVersion, PodWeaver, etc)
 [@Basic]

 [PERLANCAR::AddDeps]
 ; lump all modules from a single dist
 lump_dist = Perinci::CmdLine::Any
 ; lump all modules from a single dist and their recursive dependencies
 lump_dist_and_deps = Perinci::CmdLine::Any
 ; filter by author
 include_author = PERLANCAR

 ; all the lump_* and include_* configurations can be specified multiple times

In your main module, e.g. L<lib/Perinci/CmdLine/Any/Lumped.pm>:

 package Perinci::CmdLine::Any::Lumped;

 our $VERSION = 0.01;
 # LUMPED_MODULES
 # LUMPED_DISTS

 ...

And in the built version the directives will be replaced with:

 our @LUMPED_MODULES = (...); # LUMPED_MODULES
 our @LUMPED_DISTS = (...); # LUMPED_DISTS

You can also add in the POD area:

 =head1 LIST OF LUMPED MODULES

 # LUMPED_MODULES_POD

 =head1 LIST OF LUMPED DISTS

 # LUMPED_DISTS_POD

And in the built version they will become:

 =head1 LIST OF LUMPED MODULES

 =over

 =item * ...

 =item * ...

 ...

 =back

 =head1 LIST OF LUMPED DISTS

 =over

 =item * ...

 =item * ...

 ...

 =back

=head1 DESCRIPTION

B<WARNING: EXPERIMENTAL>

This plugin will lump (add together) one or more module files to your dist
during building. When done carefully, this can reduce the number of dists that
users need to download and install because they are already included in your
dists.

The module file(s) to be added must be indexed on (your local) CPAN and
installed on your local Perl installation, as they will be copied from the
installed version on your local installation. They will thus be contained in
their original distributions as well as on your lump dist. To avoid conflict,
the lumped files on your lump dist will be excluded from indexing (using
C<no_index> <file> in CPAN META) so PAUSE does not index them.

=head2 How it works

1. Gather the module files to be added as specified in L<lump_dist> and
L<lump_dist_and_deps>. To get a list of modules in a dist, or to get list of
(recursive) dependencies, L<lcpan> is used. Make sure you have C<lcpan>
installed and your local CPAN mirror is sufficiently up-to-date (use C<lcpan
update> regularly to keep it up-to-date).

2. Do some minimal munging on the files to be added:

=over

=item *

If the POD indicates which dist the module is in, will replace it with our dist.
For example if there is a VERSION section with this content:

 This document describes version 0.10 of Perinci::CmdLine::Any (from Perl
 distribution Perinci-CmdLine-Any), released on 2015-04-12.

then the text will be replaced with:

 This document describes version 0.10 of Perinci::CmdLine::Any (from Perl
 distribution Perinci-CmdLine-Any-Lumped version 0.01), released on 2015-05-15.

=back

3. Add all files into no_index metadata, so they don't clash with the original
dists.

4. For all the dependencies found in #1 but excluded (not lumped), express them
as dependencies.

=head2 Other caveats/issues

=over

=item *

Only module files from each distribution are included. This means other stuffs
are not included: scripts/binaries, shared files, C<.pod> files, etc. This is
because PAUSE currently only index packages (~ modules). We have C<.packlist>
though, and can use it in the future when needed.

=item *

Currently all the dependency dists must be installed on your local Perl
installation. (This is purely out of my coding laziness though. It could/should
be extracted from the release file in local CPAN index though.)

=item *

Aside from adding the module files, your main module (which should be named
Something::Lumped) should contain these directives:

 # LUMPED_MODULES
 # LUMPED_DISTS

During building, the plugin will replace those directives with:

 our @LUMPED_MODULES = (...); # LUMPED_MODULES
 our @LUMPED_DISTS = (...); # LUMPED_DISTS

The C<@LUMPED_MODULES> array contains all the modules (packages) that are lumped
in this lump dist. The purpose of this variable is to help tools like
L<lint-prereqs>. C<Lint-prereqs> is a tool to warn if you
underspecify/overspecify prereqs in C<dist.ini>. If you put a lump module (e.g.
C<Something::Lumped>) as a prereq, L<lint-prereqs> can load the module and read
the C<@LUMPED_MODULES> variable to see what other modules are lumped together in
the lump dist. When you also specify one of those modules as prereqs,
C<lint-prereqs> can warn you that it is not necessary, since that module has
already been included in the lump dist.

Similarly, C<@LUMPED_DISTS> array contains all the dists that are lumped in this
lump dist. The purpose of this variable is to help tools like
L<Dist::Zilla::Plugin::PERLANCAR::CheckDepDists>. This plugin will look for all
lump dists on the local installation (via searching for modules ending with
C<::Lumped>). If one of the dists specified in C<@LUMPED_DISTS> is the dist
currently being built, then the plugin will issue a notification that the
corresponding lump dist will need to be rebuilt.

=item *

If the lump dist is to be converted into a package-manager-based package (e.g.
deb or RPM), the package should have a Provides to all the dists that are lumped
(C<@LUMPED_DISTS>) so they can conflict with the original distribution's
packages. This is because the files do conflict.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Lump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-PERLANCAR-AddDeps>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Lump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
