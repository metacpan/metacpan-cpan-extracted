#!perl -T

use 5.014;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok( 'Mail::Qmail::Filter::Util', qw(addresses_to_hash match_address) );
}

is_deeply addresses_to_hash('Martin@Sluka.DE'),
  { 'sluka.de' => { martin => '' } }, 'single address';
is_deeply my $hash =
  addresses_to_hash( [qw(Martin@Sluka.DE fany@checkts.net checkts.net)] ),
  { 'checkts.net' => '', 'sluka.de' => { martin => '' } },
  'mixed list';
ok( match_address( $hash, 'martin@sluka.de' ),    'address match 1' );
ok( match_address( $hash, 'Martin@Sluka.de' ),    'address match 2' );
ok( match_address( $hash, 'martin@checkts.net' ), 'address match 3' );
ok( !match_address( $hash, 'fany@cpan.org' ), 'wrong address' );
