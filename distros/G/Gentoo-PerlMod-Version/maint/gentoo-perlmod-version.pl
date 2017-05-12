#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;

package Gentoo::PerlMod::Version::Tool;

our $VERSION = '0.8.1';

# PODNAME: gentoo-perlmod-version.pl

# ABSTRACT: Command line utility for translating CPAN versions to Gentoo equivalents.

# AUTHORITY

## no critic (ProhibitPunctuationVar)
use Gentoo::PerlMod::Version qw( gentooize_version );
use Carp qw( croak );

for (@ARGV) {
  if (/\A--?h/msx) {
    die <<"EOF";

    gentoo-perlmod-version.pl 1.4 1.5 1.6
    gentoo-perlmod-version.pl --lax=1 1.4_5 1.5_6
    gentoo-perlmod-version.pl --lax=2 1.4.DONTDOTHISPLEASE432

    echo 1.4 | gentoo-perlmod-version.pl
    echo 1.4-5 | gentoo-perlmod-version.pl --lax=1
    echo 1.4.NOOOOO | gentoo-perlmod-version.pl --lax=2

    SOMEVAR="\$(  gentoo-perlmod-version.pl --oneshot 1.4 )"
    SOMEVAR="\$(  gentoo-perlmod-version.pl --oneshot 1.4 1.5 )" # Invalid, dies
    SOMEVAR="\$(  gentoo-perlmod-version.pl --oneshot 1.4_5 )" # Invalid, dies
    SOMEVAR="\$(  gentoo-perlmod-version.pl --lax=1 --oneshot 1.4_5 )" # Ok


See perldoc for Gentoo::PerlMod::Version for more information.

    perldoc Gentoo::PerlMod::Version

EOF

  }
}

my $lax     = 0;
my $oneshot = 0;

for ( 0 .. $#ARGV ) {
  next unless $ARGV[$_] =~ /\A--lax=(\d+)\z/msx;
  $lax = 0 + $1;
  splice @ARGV, $_, 1, ();
  last;
}
for ( 0 .. $#ARGV ) {
  next unless '--oneshot' eq $ARGV[$_];
  $oneshot = 1;
  splice @ARGV, $_, 1, ();
  last;
}

if ($oneshot) {
  croak 'Too many versions given to --oneshot mode' if $#ARGV > 0;
  my $v = gentooize_version( $ARGV[0], { lax => $lax } );
  print $v or croak "Print Error $!";
  exit 0;
}

if (@ARGV) {
  for (@ARGV) {
    map_version( $_, $lax );
  }
}
else {
  while (<>) {
    chomp;
    map_version( $_, $lax );
  }
}

sub map_version {
  my ( $version, $laxness ) = @_;
  print "$version => " . gentooize_version( $version, { lax => $laxness } ) or croak "Print error $!";
  print "\n" or croak "Print error $!";
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

gentoo-perlmod-version.pl - Command line utility for translating CPAN versions to Gentoo equivalents.

=head1 VERSION

version v0.8.1

=head1 SYNOPSIS

    gentoo-perlmod-version.pl 1.4 1.5 1.6
    gentoo-perlmod-version.pl --lax=1 1.4_5 1.5_6
    gentoo-perlmod-version.pl --lax=2 1.4.DONTDOTHISPLEASE432

    echo 1.4 | gentoo-perlmod-version.pl
    echo 1.4-5 | gentoo-perlmod-version.pl --lax=1
    echo 1.4.NOOOOO | gentoo-perlmod-version.pl --lax=2

    SOMEVAR="$(  gentoo-perlmod-version.pl --oneshot 1.4 )"
    SOMEVAR="$(  gentoo-perlmod-version.pl --oneshot 1.4 1.5 )" # Invalid, dies
    SOMEVAR="$(  gentoo-perlmod-version.pl --oneshot 1.4_5 )" # Invalid, dies
    SOMEVAR="$(  gentoo-perlmod-version.pl --lax=1 --oneshot 1.4_5 )" # Ok

See C<perldoc> for L<< C<Gentoo::PerlMod::Versions> documentation|Gentoo::PerlMod::Version >> for more information.

    perldoc Gentoo::PerlMod::Version

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
