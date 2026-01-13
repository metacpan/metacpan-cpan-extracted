use Test2::V0;
use Test2::Require::Module 'HTTP::Tiny';
use Data::Dumper;

BEGIN {
	package My::HTTP;
	use Marlin -sloppy, -base => 'HTTP::Tiny', qw( flibble );
};

my $ua = My::HTTP->new( max_redirect => 3, flibble => 42 );

isa_ok($ua, 'My::HTTP');
isa_ok($ua, 'HTTP::Tiny');

is( $ua->max_redirect, 3 );
is( $ua->flibble, 42 );

done_testing;
