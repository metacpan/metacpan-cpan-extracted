package Dist::Zilla::Plugin::Sorter;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Moose;
use namespace::autoclean;

use File::Spec::Functions qw(catfile);

with (
    #'Dist::Zilla::Role::RequireFromBuild', # not ready at before-build phase?
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

# AUTHOR
our $DATE = '2024-04-24'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Sorter'; # DIST
our $VERSION = '0.001'; # VERSION

sub _get_meta {
    my ($self, $pkg) = @_;

    $self->require_from_build($pkg);
    $pkg->meta;
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
    #open my $fh, '<', $filename or die "File ${filename} cannot open: $!";

    my ($meta, $abstract);
    #$meta = $self->_get_meta($class);
    {
        local @INC = ("lib", @INC);
        (my $mod = $name) =~ s/-/::/g;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        $meta = $mod->meta;
    }
    $abstract = $meta->{summary};

    unless ($abstract) {
        $self->log_debug("meta does not contain summary, skipping setting Abstract from meta's summary");
        return;
    }

    $self->log("Setting Abstract from meta's summary: $abstract");
    $self->zilla->abstract($abstract);
    return;
}

sub munge_files {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my $self = shift;

    local @INC = ("lib", @INC);

    # gather dist modules
    my %distmodules;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!\Alib/(.+)\.pm\z!;
        my $mod = $1; $mod =~ s!/!::!g;
        $distmodules{$mod}++;
    }

    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!\Alib/(Sort/Sub/.+)\.pm\z!;
        (my $pkg = $1) =~ s!/!::!g;
        my $meta = $self->_get_meta($pkg);

        # fill-in ABSTRACT from scenario's summary
        {
            my $content = $file->content;
            my $abstract = $meta->{summary};
            last unless $abstract;
            $content =~ s{^#\s*ABSTRACT:.*}{# ABSTRACT: $abstract}m
                or die "Can't insert abstract for " . $file->name;
            $self->log(["inserting abstract for %s (%s)",
                        $file->name, $abstract]);

            $file->content($content);
        }
    } # foreach file
    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building Sorter::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Sorter - Plugin to use when building Sorter::* distribution

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::Sorter (from Perl distribution Dist-Zilla-Plugin-Sorter), released on 2024-04-24.

=head1 SYNOPSIS

In F<dist.ini>:

 [Sorter]

=head1 DESCRIPTION

This plugin is to be used when building C<Sorter::*> distribution. It
currently does the following:

=over

=item * Fill-in ABSTRACT from meta's summary

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Sorter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Sorter>.

=head1 SEE ALSO

L<Sorter>

L<Pod::Weaver::Plugin::Sorter>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Sorter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
