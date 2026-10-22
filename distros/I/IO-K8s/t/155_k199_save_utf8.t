#!/usr/bin/env perl

# k199: save($file) printed the to_yaml character string to a handle without an
# encoding layer. Non-ASCII text below U+0100 landed as Latin-1 (invalid UTF-8,
# load_yaml reads something else back, kubectl reads garbage); anything above
# U+00FF made Perl warn 'Wide character in print'. The assertions look at the
# raw bytes on disk and at the save -> load_yaml round trip.

use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Temp qw( tempdir );
use IO::K8s;

my $k8s = IO::K8s->new;
my $dir = tempdir( CLEANUP => 1 );

sub slurp_bytes {
  my ( $file ) = @_;
  open my $fh, '<:raw', $file or die "Cannot read $file: $!";
  local $/;
  return scalar <$fh>;
}

sub save_quietly {
  my ( $obj, $file ) = @_;
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  $obj->save($file);
  return @warn;
}

sub cm {
  my (%data) = @_;
  return $k8s->new_object( 'ConfigMap',
    metadata => { name => 'x', annotations => { note => $data{note} // 'plain' } },
    data     => { a => $data{a} },
  );
}

# --- raw bytes on disk
{
  my $file  = "$dir/gruen.yaml";
  my @warn  = save_quietly( cm( a => "gr\x{fc}n" ), $file );
  my $bytes = slurp_bytes($file);
  like $bytes, qr/gr\xc3\xbcn/, 'gruen is 67 72 c3 bc 6e on disk';
  unlike $bytes, qr/gr\xfcn/, 'no Latin-1 byte fc left in the file';
  is_deeply \@warn, [], 'no warning on a Latin-1-range value';
}

# --- wide characters: no warning, UTF-8 bytes
{
  my $file  = "$dir/wide.yaml";
  my @warn  = save_quietly( cm( a => "\x{20ac}\x{4e2d}\x{1f600}" ), $file );
  my $bytes = slurp_bytes($file);
  like $bytes, qr/\xe2\x82\xac/,     'euro sign is e2 82 ac';
  like $bytes, qr/\xe4\xb8\xad/,     'CJK char is e4 b8 ad';
  like $bytes, qr/\xf0\x9f\x98\x80/, 'U+1F600 is f0 9f 98 80';
  is_deeply \@warn, [], 'no Wide character warning';
}

# --- round trips
my %cases = (
  'latin1 (u, e, n)' => "gr\x{fc}n caf\x{e9} ma\x{f1}ana",
  'euro'             => "price \x{20ac}5",
  'cjk'              => "\x{4e2d}\x{6587}\x{65e5}\x{672c}",
  'emoji'            => "ok \x{1f600}",
  'mixed'            => "gr\x{fc}n \x{20ac} \x{4e2d} \x{1f600}",
);
for my $name ( sort keys %cases ) {
  my $v    = $cases{$name};
  my $file = "$dir/rt.yaml";
  my @warn = save_quietly( cm( a => $v, note => $v ), $file );
  is_deeply \@warn, [], "$name: no warning on save";
  my $back = $k8s->load_yaml($file)->[0];
  is $back->data->{a}, $v, "$name: ConfigMap data survives save -> load_yaml";
  is $back->metadata->annotations->{note}, $v, "$name: annotation survives save -> load_yaml";
}

# --- unwritable path
{
  my $file = "$dir/no/such/dir/x.yaml";
  throws_ok { cm( a => 'x' )->save($file) } qr/Cannot write to \Q$file\E/,
    'save into a missing directory dies naming the file';
  ok !-e $file, 'nothing was created';
}

# --- chaining still works
{
  my $obj = cm( a => 'x' );
  is $obj->save("$dir/chain.yaml"), $obj, 'save returns the object';
}

done_testing;
