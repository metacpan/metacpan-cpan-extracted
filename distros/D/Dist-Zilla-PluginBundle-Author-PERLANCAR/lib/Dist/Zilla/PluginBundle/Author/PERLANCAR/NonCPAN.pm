package Dist::Zilla::PluginBundle::Author::PERLANCAR::NonCPAN;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-27'; # DATE
our $DIST = 'Dist-Zilla-PluginBundle-Author-PERLANCAR'; # DIST
our $VERSION = '0.603'; # VERSION

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::PluginBundle::Filter;

sub configure {
    my $self = shift;

    $self->add_bundle(Filter => {
        -bundle => '@Author::PERLANCAR',
        -remove => [qw/PERLANCAR::Authority ConfirmRelease UploadToCPAN::WWWPAUSESimple/],
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
# ABSTRACT: Dist::Zilla like PERLANCAR when you build your non-CPAN dists

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::PERLANCAR::NonCPAN - Dist::Zilla like PERLANCAR when you build your non-CPAN dists

=head1 VERSION

This document describes version 0.603 of Dist::Zilla::PluginBundle::Author::PERLANCAR::NonCPAN (from Perl distribution Dist-Zilla-PluginBundle-Author-PERLANCAR), released on 2020-09-27.

=head1 SYNOPSIS

 # dist.ini
 [@Author::PERLANCAR::NonCPAN]

is equivalent to:

 [@Filter]
 bundle=@Author::PERLANCAR
 remove=PERLANCAR::Authority
 remove=ConfirmRelease
 remove=UploadToCPAN

(Authority is removed so you can conveniently use this bundle and add the
Authority plugin separately again and set C<authority>, instead of having to
@Filter this bundle and remove Authority only to add it later to customize the
authority.)

=head1 DESCRIPTION

=for Pod::Coverage ^(configure)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-PluginBundle-Author-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
