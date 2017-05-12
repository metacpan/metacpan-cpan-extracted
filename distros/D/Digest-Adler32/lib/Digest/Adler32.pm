package Digest::Adler32;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.03';

require Digest::base;
@ISA=qw(Digest::base);

sub new
{
    my $class = shift;
    if (ref $class) {
	$$class = 1;  # reset
	return $class;
    }
    my $adler_state = 1;
    return bless \$adler_state, $class;
}

sub clone {
    my $self = shift;
    my $adler_state = $$self;
    return bless \$adler_state, ref($self);
}

# Based on RFC 1950 section 9

sub add {
    my $self = shift;
    my $s1 = $$self & 0x0000FFFF;
    my $s2 = ($$self >> 16) & 0x0000FFFF;
    for my $buf (@_) {
	for my $c (unpack("C*", $buf)) {
	    $s1 = ($s1 + $c ) % 65521;
	    $s2 = ($s2 + $s1) % 65521;
	}
    }
    $$self = ($s2 << 16) + $s1;
    return $self;
}

sub digest {
    my $self = shift;
    my $digest = pack("N", $$self);
    $$self = 1;  # reset
    return $digest;
}

1;

=head1 NAME

Digest::Adler32 - The Adler-32 checksum

=head1 SYNOPSIS

 use Digest::Adler32;
 $a32 = Digest::Adler32->new;

 # add stuff
 $a32->add($some_data);
 $a32->addfile(*STDIN);

 # get digest
 print "Adler32: ", $a32->hexdigest, "\n";


=head1 DESCRIPTION

The C<Digest::Adler32> module implements the Adler-32 checksum as
specified in RFC 1950.  The interface provided by this module is
specified in L<Digest>, but no functional interface is provided.

A binary digest will be 4 bytes long.  A hex digest will be 8
characters long.  A base64 digest will be 6 characters long.

=head1 SEE ALSO

L<Digest>, L<Digest::MD5>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

  Copyright 1996 L. Peter Deutsch and Jean-Loup Gailly
  Copyright 2001,2003 Gisle Aas

=cut
