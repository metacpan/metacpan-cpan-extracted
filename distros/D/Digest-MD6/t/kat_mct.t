#!perl

use strict;
use warnings;

use Digest::MD6;
use File::Spec;
use LWP::Simple qw( mirror is_success status_message $ua );

use Test::More;

plan skip_all => 'Set DIGEST_MD6_SLOW_TESTS to enable'
 unless $ENV{DIGEST_MD6_SLOW_TESTS};

use constant BASE =>
 'http://groups.csail.mit.edu/cis/md6/revision-2009-04-15/KAT_MCT';
use constant CACHE => 'kat_mct';

-d CACHE or mkdir CACHE or die "Can't create ", CACHE, ": $!\n";

for my $name ( 'ExtremelyLongMsgKAT', 'LongMsgKAT', 'ShortMsgKAT' ) {
  for my $bits ( 224, 256, 384, 512 ) {
    my $src = fetch( BASE, "${name}_${bits}.txt" );
    my @case = load_cases( $src, $bits );
    for my $c ( @case ) {
      test( $c );
    }
  }
}

done_testing();

sub test {
  my $case = shift;
  local $Digest::MD6::HASH_LENGTH = $case->{_bits};
  my $md = Digest::MD6->new;
  if ( exists $case->{Len} && exists $case->{Msg} ) {
    $md->add_bits( pack( 'H*', $case->{Msg} ), $case->{Len} );
  }
  elsif ( exists $case->{Repeat} && exists $case->{Text} ) {
    $md->add( $case->{Text} ) for 1 .. $case->{Repeat};
  }
  else {
    die sprintf "%s, line %d: Unrecognised test case\n",
     $case->{_file}, $case->{_line};
  }
  is lc $md->hexdigest, lc $case->{MD},
   sprintf "%s, line %d: hash matches", $case->{_file}, $case->{_line};
}

sub fetch {
  my ( $base, $name ) = @_;
  my $url = "${base}/${name}";
  my $file = File::Spec->catfile( CACHE, $name );
  diag "Fetching $url as $file";
  my $rc = mirror( $url, $file );
  die status_message( $rc )
   unless is_success( $rc ) || $rc == 304;
  return $file;
}

sub load_cases {
  my ( $ref, $bits ) = @_;

  my @case = ();
  my $rec  = {};
  open my $fh, '<', $ref or die "Can't read $ref: $!\n";
  while ( <$fh> ) {
    chomp;
    next if /^\s*$/;
    next if /^#/;
    die "Bad line: $_\n" unless /^(\w+)\s*=\s*(.*)$/;
    my ( $k, $v ) = ( $1, $2 );
    $rec->{$k} = $v;
    if ( $k eq 'MD' ) {
      $rec->{_file} = $ref;
      $rec->{_line} = $.;
      $rec->{_bits} = $bits;
      push @case, $rec;
      $rec = {};
    }
  }
  return @case;
}

# vim:ts=2:sw=2:et:ft=perl

