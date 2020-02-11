package Dist::Zilla::Plugin::Data::Sah::Filter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-10'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Data-Sah-Filter'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Moose;
use namespace::autoclean;

use Dist::Zilla::File::InMemory;
use File::Slurper qw(read_binary);
use File::Spec::Functions qw(catfile);
use PMVersions::Util qw(version_from_pmversions);

with (
    'Dist::Zilla::Role::RequireFromBuild',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

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

    my $meta = $self->_get_meta($class);
    my $abstract = $meta->{summary};
    return unless $abstract;

    $self->zilla->abstract($abstract);
    return;
}

sub munge_files {
    no strict 'refs';
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
        next unless $file->name =~ m!\Alib/(Data/Sah/Filter/.+)\.pm\z!;
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
# ABSTRACT: Plugin to use when building Data::Sah::Filter::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Data::Sah::Filter - Plugin to use when building Data::Sah::Filter::* distribution

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::Data::Sah::Filter (from Perl distribution Dist-Zilla-Plugin-Data-Sah-Filter), released on 2020-02-10.

=head1 SYNOPSIS

In F<dist.ini>:

 [Data::Sah::Filter]

=head1 DESCRIPTION

This plugin is to be used when building C<Data::Sah::Filter::*> distribution. It
currently does the following:

=over

=item * Fill-in ABSTRACT from meta's summary

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Data-Sah-Filter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Filter>

L<Pod::Weaver::Plugin::Data::Sah::Filter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
