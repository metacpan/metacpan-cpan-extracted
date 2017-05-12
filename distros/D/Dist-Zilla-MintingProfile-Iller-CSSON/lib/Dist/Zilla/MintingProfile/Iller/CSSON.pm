use strict;
use warnings;
package Dist::Zilla::MintingProfile::Iller::CSSON;

our $VERSION = '0.0101'; # VERSION:
# ABSTRACT: Minting profile

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



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg" alt="Requires Perl 5.10.1+" /> <a href="https://travis-ci.org/Csson/p5-Dist-Zilla-MintingProfile-Iller-CSSON"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-MintingProfile-Iller-CSSON.svg?branch=master" alt="Travis status" /></a> </p>

=end HTML


=begin markdown

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-MintingProfile-Iller-CSSON.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-MintingProfile-Iller-CSSON) 

=end markdown

=head1 VERSION

Version 0.0101, released 2016-01-20.

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
