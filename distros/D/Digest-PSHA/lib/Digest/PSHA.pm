package Digest::PSHA;

# $Id: PSHA.pm,v 1.2 2014-10-23 12:21:56 swaj Exp $

use 5.0008;
use strict;
use warnings;
use Carp;
use Digest::SHA;
use Digest::HMAC qw / hmac /;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw / p_sha1 p_sha256 /;
our $VERSION = '0.51';

sub p_sha1
{ 
    my ($secret, $salt, $bytes, $offset) = @_;
    $bytes = 128 unless defined $bytes;
    substr ( _digest ($secret, $salt, $bytes, $offset, \&Digest::SHA::sha1, length(Digest::SHA::sha1(q{}) ) ),
             $offset/8, $bytes/8);
}

sub p_sha256
{
    my ($secret, $salt, $bytes, $offset) = @_;
    $bytes = 256 unless defined $bytes;
    substr ( _digest ($secret, $salt, $bytes, $offset, \&Digest::SHA::sha256, length(Digest::SHA::sha256(q{}) ) ),
             $offset/8, $bytes/8);
}

sub _digest
{
    my ($secret, $salt, $bytes, $offset, $hash_func, $func_hash_len ) = @_;
    my ($buf1, $buf2, $t);
    $offset = 0 unless defined $offset;

    if ($offset % 8 || $bytes % 8 ) {
        carp  "Wrong parameters length [$bytes] and/or offset [$offset], they are in bits!";
        return undef;
    }

    my $bytes_tot = ($offset + $bytes) / 8 ;
    $buf1 = $salt;
    my $buf = q{};
    for ( my $i=0; $i < $bytes_tot ;) {
        $buf2 = $buf1 = hmac($buf1, $secret, $hash_func);
        substr($buf2, $func_hash_len) = $salt;
        $t = hmac($buf2, $secret, $hash_func);
        for (my $x = 0; $x < length($t); $x++) {
            last if ( $i >= $bytes_tot );
            substr($buf, $i++, 1, substr($t, $x, 1) );
        }
    }
    return $buf;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Digest::PSHA - Perl implementation of P_SHA-1 and P_SHA256
digests (pseudorandom functions) described in RFC 4346 and RFC 5246.

=head1 SYNOPSIS

  use Digest::PSHA qw / p_sha1 p_sha256 /;

  my $secret = ' 55 aa eb f9 51 b3 ed ef 84 c6 02 c5 f1 72 c1 aa ';
  my $salt   = ' 13 e6 db 5d c1 23 5c f6 4f 89 ce 70 41 0c 52 8d ';

  $_ = $secret;
  s/\s//g;
  my $secret_bin = pack ("H*" , $_ );

  $_ = $salt;
  s/\s//g;
  my $salt_bin = pack ("H*" , $_ );


  # Get 128 bit key
  my $key1 = p_sha1 ($secret_bin, $salt_bin, 128, 0);

  # Get 256 bit key
  $secret_bin .= $secret_bin;
  $salt_bin .= $salt_bin; 
  my $key2 = p_sha256 ($secret_bin, $salt_bin, 256, 0);

=head1 DESCRIPTION

Digest::PSHA - Perl implementation of P_SHA-1 and P_SHA256
digests (pseudorandom functions) described in RFC 4346 and RFC 5246.

=head2 EXPORT

None by default.

=head1 SEE ALSO

RFC 4346, RFC 5246

=head1 AUTHOR

The I<Digest::PSHA> module was written by Alexey Semenoff,
F<swaj@swaj.net>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 by Alexey Semenoff [http://swaj.net].

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.008 or,
at your option, any later version of Perl 5 you may have available.

=cut
