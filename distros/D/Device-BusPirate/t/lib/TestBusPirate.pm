package TestBusPirate;

use strict;
use warnings;

use Carp;

use Future::AsyncAwait;

use Exporter 'import';
our @EXPORT = qw(
   expect_write
   expect_read
   check_and_clear
);

my $builder = Test::Builder->new;

my @expectations;

sub expect_write
{
   push @expectations, [ write => $_[0] ];
}

sub expect_read
{
   push @expectations, [ read => $_[0] ];
}

sub check_and_clear
{
   my ( $name ) = @_;

   $builder->ok( !@expectations, "$name: all methods called" );
   @expectations = ();
}

require Device::BusPirate;
require Future::IO;
require Test::Future::Deferred;

no warnings 'redefine';

sub _stringify { sprintf "%v02X", $_[0] }

*Future::IO::syswrite_exactly = async sub {
   shift;
   my ( undef, $bytes ) = @_;
   my $e = $expectations[0];

   $e and $e->[0] eq "write" or
      croak "Unexpected syswrite(\"${\_stringify $bytes}\")";

   my $want_bytes = substr( $e->[1], 0, length $bytes );
   $want_bytes eq $bytes or
      croak "Expected syswrite(\"${\_stringify $want_bytes}\"), got (\"${\_stringify $bytes}\")";

   substr( $e->[1], 0, length $bytes ) = "";
   shift @expectations if !length $e->[1];

   return length $bytes;
};

*Future::IO::sysread_exactly = async sub {
   shift;
   my ( undef, $length ) = @_;

   await Test::Future::Deferred->done_later;

   my $e = $expectations[0];

   $e and $e->[0] eq "read" or
      croak "Unexpected sysread($length)";

   length $e->[1] or
      croak "No bytes for sysread($length)";

   my $ret = substr( $e->[1], 0, $length, "" );
   shift @expectations if !length $e->[1];

   return $ret;
};

0x55AA;
