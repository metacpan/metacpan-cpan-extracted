use 5.14.0;
use strict;
use warnings;

package Dist::Zilla::MintingProfile::Iller::CSSON;

# ABSTRACT: Minting profile
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0102';

use Moose;
with 'Dist::Zilla::Role::MintingProfile';
use File::ShareDir;
use Path::Class;
use Carp;
use namespace::autoclean;

sub profile_dir {
    my $self = shift;
    my $profile_name = shift;

    my $dist_name = 'Dist-Zilla-MintingProfile-Iller-CSSON';
    my $profile_dir = dir(File::ShareDir::dist_dir($dist_name))->subdir($profile_name);

    return $profile_dir if -d $profile_dir;

    confess "Can't find profile $profile_name in $profile_dir";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Iller::CSSON - Minting profile



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.14+-blue.svg" alt="Requires Perl 5.14+" />
<img src="https://img.shields.io/badge/coverage-100.0%25-brightgreen.svg" alt="coverage 100.0%" />
<a href="https://github.com/Csson/p5-Dist-Zilla-MintingProfile-Iller-CSSON/actions?query=workflow%3Amakefile-test"><img src="https://img.shields.io/github/workflow/status/Csson/p5-Dist-Zilla-MintingProfile-Iller-CSSON/makefile-test" alt="Build status at Github" /></a>
</p>

=end html

=head1 VERSION

Version 0.0102, released 2020-12-28.

=head1 SYNOPSIS

    dzil new -P Iller::CSSON New::Module

=head1 DESCRIPTION

This mints a new distribution prepared for L<Dist::Zilla> via L<Dist::Iller> and L<Dist::Iller::Config::Author::CSSON>.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-MintingProfile-Iller-CSSON>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-MintingProfile-Iller-CSSON>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
