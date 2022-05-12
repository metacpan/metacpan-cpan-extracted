package Dist::Zilla::Plugin::Acme::CPANModules;

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

use File::Spec::Functions qw(catfile);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-04-01'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Acme-CPANModules'; # DIST
our $VERSION = '0.005'; # VERSION

# either provide filename or filename+filecontent
sub _get_abstract_from_list_summary {
    my ($self, $filename, $filecontent) = @_;

    local @INC = @INC;
    unshift @INC, 'lib';

    unless (defined $filecontent) {
        $filecontent = do {
            open my($fh), "<", $filename or die "Can't open $filename: $!";
            local $/;
            ~~<$fh>;
        };
    }

    unless ($filecontent =~ m{^#[ \t]*ABSTRACT:[ \t]*([^\n]*)[ \t]*$}m) {
        $self->log_debug(["Skipping %s: no # ABSTRACT", $filename]);
        return undef; ## no critic: ProhibitExplicitReturnUndef
    }

    my $abstract = $1;
    if ($abstract =~ /\S/) {
        $self->log_debug(["Skipping %s: Abstract already filled (%s)", $filename, $abstract]);
        return $abstract;
    }

    my $pkg;
    if (!defined($filecontent)) {
        (my $mod_p = $filename) =~ s!^lib/!!;
        require $mod_p;

        # find out the package of the file
        ($pkg = $mod_p) =~ s/\.pm\z//; $pkg =~ s!/!::!g;
    } else {
        eval $filecontent; ## no critic: ProhibitStringyEval
        die if $@;
        if ($filecontent =~ /\bpackage\s+(\w+(?:::\w+)*)/s) {
            $pkg = $1;
        } else {
            die "Can't extract package name from file content";
        }
    }

    no strict 'refs'; ## no critic: ProhibitNoStrict
    my $list = ${"$pkg\::LIST"};

    return $list->{summary} if $list->{summary};
}

# dzil also wants to get abstract for main module to put in dist's
# META.{yml,json}
sub before_build {
   my $self  = shift;
   my $name  = $self->zilla->name;
   my $class = $name; $class =~ s{ [\-] }{::}gmx;
   my $filename = $self->zilla->_main_module_override ||
       catfile( 'lib', split m{ [\-] }mx, "${name}.pm" );

   $filename or die 'No main module specified';
   -f $filename or die "Path ${filename} does not exist or not a file";
   my $abstract = $self->_get_abstract_from_list_summary($filename);
   return unless $abstract;

   $self->zilla->abstract($abstract);
   return;
}

sub munge_files {
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;

    unless ($file->isa("Dist::Zilla::File::OnDisk")) {
        $self->log_debug(["skipping %s: not an ondisk file, currently generated file is assumed to be OK", $file->name]);
        return;
    }

    $self->log_debug(["Processing %s ...", $file->name]);

    my $pkg = do {
        my $pkg = $file->name;
        $pkg =~ s!^lib/!!;
        $pkg =~ s!\.pm$!!;
        $pkg =~ s!/!::!g;
        $pkg;
    };

    if ($pkg =~ /\AAcme::CPANModules::/) {

        my $abstract = $self->_get_abstract_from_list_summary($file->name, $file->content);

        my $list;
        {
            no strict 'refs'; ## no critic: ProhibitNoStrict
            $list = ${"$pkg\::LIST"};
        }

      CHECK_LIST: {
            $self->log_fatal("List does not have 'entries' property")
                unless $list->{entries};
            $self->log_fatal("List does not have any entries")
                unless @{ $list->{entries} };

            $self->log_fatal("List does not have 'summary'")
                unless $list->{summary};
            $self->log("WARNING: Summary does not begin 'List of ' (it's recommended to begin the summary with 'List of ')")
                unless $list->{summary} =~ /^List of /;
        } # CHECK_LIST

      ADD_PREREQS:
        {
            my %mentioned_mods;
            my %listed_mods;
            for my $entry (@{ $list->{entries} }) {
                $mentioned_mods{ $entry->{module} }++;
                $listed_mods{ $entry->{module} }++;
                for (@{ $entry->{alternate_modules} || [] }) {
                    $mentioned_mods{ $_ }++;
                }
                for (@{ $entry->{related_modules} || [] }) {
                    $mentioned_mods{ $_ }++;
                }
            }
            for my $mod (keys %listed_mods) {
                $self->zilla->register_prereqs(
                    {phase=>'x_lists', type=>'x_lists'}, $mod, 0);
            }
            for my $mod (keys %mentioned_mods) {
                $self->zilla->register_prereqs(
                    {phase=>'x_mentions', type=>'x_mentions'}, $mod, 0);
            }
        } # ADD_X_MENTIONS_PREREQS

      SET_ABSTRACT:
        {
            last unless $abstract;
            $content =~ s{^#\s*ABSTRACT:.*}{# ABSTRACT: $abstract}m
                or die "Can't insert abstract for " . $file->name;
            $self->log(["inserting abstract for %s (%s)", $file->name, $abstract]);
            $file->content($content);
        } # SET_ABSTRACT

    } else {
    }

}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building Acme::CPANModules::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Acme::CPANModules - Plugin to use when building Acme::CPANModules::* distribution

=head1 VERSION

This document describes version 0.005 of Dist::Zilla::Plugin::Acme::CPANModules (from Perl distribution Dist-Zilla-Plugin-Acme-CPANModules), released on 2022-04-01.

=head1 SYNOPSIS

In F<dist.ini>:

 [Acme::CPANModules]

=head1 DESCRIPTION

This plugin is to be used when building C<Acme::CPANModules::*> distribution. It
currently does the following.

For each F<Acme/CPANModules/*.pm> file:

=over

=item * Check the list

=over

=item * Abort the build if there are no entries in $LIST

=item * Abort the build if list does not have 'summary'

=item * Warn if list summary does not begin with 'List of '

=back

=item * Fill the Abstract from list's summary

=item * Add prereq to the listed modules (phase=x_lists, relationship=x_lists)

Listed modules are modules that are specified in the C<module> key of each
entry.

=item * Add prereq to the mentioned modules (phase=x_mentions, relationship=x_mentions)

Mentioned modules are modules that are specified in the C<module> key of each
entry, as well as the C<alternate_modules> and C<related_modules> keys.

=back

For each F<Acme/CPANModulesBundle/*.pm> file:

=over

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Acme-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Acme-CPANModules>.

=head1 SEE ALSO

L<Acme::CPANModules>

L<Pod::Weaver::Plugin::Acme::CPANModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Acme-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
