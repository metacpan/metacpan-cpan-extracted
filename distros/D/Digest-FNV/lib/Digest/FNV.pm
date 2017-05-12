package Digest::FNV;

use 5.010000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
#use Data::Dumper;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Digest::FNV ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw(
#	FNV0_32_INIT
#	FNV1A_64_LOWER
#	FNV1A_64_UPPER
#	FNV1_32A_INIT
#	FNV1_32_INIT
#	FNV1_64_LOWER
#	FNV1_64_UPPER
#) ] );

our @EXPORT_OK = (  );

our @EXPORT = qw( fnv  fnv32  fnv32a  fnv64  fnv64a );
#= qw(
#	FNV0_32_INIT
#	FNV1A_64_LOWER
#	FNV1A_64_UPPER
#	FNV1_32A_INIT
#	FNV1_32_INIT
#	FNV1_64_LOWER
#	FNV1_64_UPPER
#);

our $VERSION = '2.00';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Digest::FNV::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Digest::FNV', $VERSION);

# Preloaded methods go here.

sub fnv {
    my ($string) = @_;
    return fnv32($string);
}

sub fnv64 {
    my ($string) = @_;
    my @fnv_hash = fnv64_t($string);
    #print Dumper(\@fnv_hash); print "\n";

    my %hash = ();
    # This is a little test for what kind of system we're on, 32 or 64
    if ( (1 << 32) != 4294967296) {
        $hash{'bits'} = 32;
    }
    else {
        $hash{'bits'} = 64;
    }

    $hash{'longlong'} = ($fnv_hash[1] << 32) | $fnv_hash[0] + 0;
    $hash{'lower'} = $fnv_hash[0];
    $hash{'upper'} = $fnv_hash[1];

    use bigint;
    my $retval = ($fnv_hash[1] << 32) | $fnv_hash[0];
    $hash{'bigint'} = $retval;  # very likely a string

    return \%hash;
}

sub fnv64a {
    my ($string) = @_;
    my @fnv_hash = fnv64a_t($string);
    #print Dumper(\@fnv_hash); print "\n";

    my %hash = ();
    # This is a little test for what kind of system we're on, 32 or 64
    if ( (1 << 32) != 4294967296) {
        $hash{'bits'} = 32;
    }
    else {
        $hash{'bits'} = 64;
    }

    $hash{'longlong'} = ($fnv_hash[1] << 32) | $fnv_hash[0] + 0;
    $hash{'lower'} = $fnv_hash[0];
    $hash{'upper'} = $fnv_hash[1];

    use bigint;
    my $retval = ($fnv_hash[1] << 32) | $fnv_hash[0];
    $hash{'bigint'} = $retval;  # very likely a string

    return \%hash;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Digest::FNV - Perl extension for the Fowler/Noll/Vo (FNV) has

=head1 SYNOPSIS

  use Digest::FNV qw(fnv fnv32 fnv32a fnv64 fnv64a);

  my $fnv32hash = fnv("abc123");

  my $fnv32hash = fnv32("abc123"); # This does the same as the previous example

  my $hashref = fnv64("abc123");
  $hashref->{bits};     # 32 for 32 bit systems, 64 for 64 bit systems
  $hashref->{upper};    # Upper 32 bits
  $hashref->{lower};    # Lower 32 bits
  $hashref->{bigint}    # use bigint; version of this possibly large number
  $hashref->{longlong}; # 64 bit representation (i.e. (upper << 32) | lower)
                        # This value is useless on 32 bit systems

=head1 DESCRIPTION

FNV is a hashing algorithm for short to medium length strings.  It is best suited for strings that are typically around 1024 bytes or less (URLs, IP addresses, hostnames, etc).  This implementation is based on the code provided by Landon Curt Noll.

There are two slightly different algorithms.  One is called FNV-1, and the other is FNV-1a.  Both algorithms are provided for each of 32 and 64 bit hash values.

For full information on this algorithm please visit http://isthe.com/chongo/tech/comp/fnv/

The original Digest::FNV was written by Tan D Nguyen <tnguyen@cpan.org>.  This version is a drop-in replacement (all existing code should continue to work).  However, it is a complete rewrite.

This new version works on both 32 and 64 bit platforms.

=head1 CAVEATS

Part of the challenge of supporting this module are the differences between 32-bit and 64-bit architectures.

In practice the values returned by these algorithms are often further processed (further algorithms).  It is for that reason that the nature of what the fnv64/fnv64a functions return is exposed.  When trying to support both 64 and 32 bit architectures it is necessary.

You cannot rely on only $hashref->{bigint} if you plan to perform and further math on that value on 32 bit systems.  You also cannot rely on $hashref->{longlong} unless you know the architecture.

This module attempts to provide all of the necessary information to arrive at a true 64-bit value.  Often times you're passing values to other software (a database, for example), and that database probably provides 64-bit left shift operations.

=head1 ACKNOWLEDGEMENTS

Tan D Nguyen <tnguyen@cpan.org> who wrote the first Digest::FNV module.

The C code was based on the public domain FNV sources released by Landon Curt Noll (see below).

=head1 SEE ALSO

http://isthe.com/chongo/tech/comp/fnv/
http://en.wikipedia.org/wiki/Fowler_Noll_Vo_hash

=head1 AUTHOR

Jeffrey Webster, E<lt>jeff.webster@zogmedia.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Jeffrey Webster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
