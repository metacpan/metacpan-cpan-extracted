#!/usr/bin/perl

package Debian::Packages;
use Moose;

=head1 NAME

Debian::Packages - An interface to a Debian Packages file

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

use Debian::Packages;

# create object and pass a Packages file
my $packages_file = DebianPackages->new(filename => '/var/www/apt/dists/sid/main/binary-i386/Packages');
my @packages_array = $packages_file->read;
print "First found package is $packages_array[0]\n";

=cut

has 'file' => ( is => 'ro', isa => 'Str', default => 0 );

=head2 read

Read our Packages file, place into an array of newlines.

=cut

sub read {
  use Perl6::Slurp;
  my ($self) = @_;
  slurp $self->{filename}, {irs => qr/\n\n/xms};
}

=head1 DESCRIPTION

DebianPackages is an interface to a Debian Packages file. The Debian Packages file is a list of packages
included in a Debian, or Debian based, distribution. This is the file used by APT and other tools to 
query and install packages on a Debian system. The Packages file is usually created by one of the tools
that manages a debian package repository, like reprepro or dak for example. It has limited use for end users
since apt and aptitude are better and more complete tools.

=head1 AUTHOR 

Jeremiah C. Foster, E<lt>jeremiah@jeremiahfoster.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeremiah C. Foster, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Parse::Debian::Packages (Does roughly the same thing, but is unmaintained.)_

=cut

1;  # End of Debian::Packages
