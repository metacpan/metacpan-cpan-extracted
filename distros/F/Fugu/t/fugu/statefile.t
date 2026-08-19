#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use Fugu::File;
use Fugu::Log;

use_ok('Fugu::StateFile');

# The store reports recoverable failures through the default logger.
Fugu::Log->set_default( Fugu::Log->new( mode => 'quiet' ) );

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

sub next_path()
{
	return sprintf '%s/state-%d.json', $dir, ++$n;
}

subtest 'set, get and persist' => sub {
	my $path  = next_path();
	my $store = Fugu::StateFile->new( path => $path )->load;

	is( $store->get('missing'), undef, 'an unset key is undef' );

	ok( $store->set( 'count', 3 ), 'set reports success' );
	is( $store->get('count'), 3, 'get returns it' );

	# A second object over the same file sees the same state
	my $reader = Fugu::StateFile->new( path => $path )->load;
	is( $reader->get('count'), 3, 'another reader sees it' );

	ok( $store->set( 'nested', { a => [ 1, 2 ] } ), 'a structure stores' );
	is_deeply(
		Fugu::StateFile->new( path => $path )->load->get('nested'),
		{ a => [ 1, 2 ] },
		'and comes back whole'
	);

	ok( $store->delete('count'), 'delete reports success' );
	is( Fugu::StateFile->new( path => $path )->load->get('count'),
		undef, 'and the key is gone from the file' );
};

subtest 'a stored undef is still a stored answer' => sub {
	my $path  = next_path();
	my $store = Fugu::StateFile->new( path => $path )->load;

	$store->set( 'seen', undef );
	is( $store->get('seen'), undef, 'the value is undef' );
	ok( exists $store->data->{seen}, 'but the key is stored' );
};

subtest 'load tolerates a missing and a corrupt file' => sub {
	my $missing = Fugu::StateFile->new( path => "$dir/never-written.json" );
	ok( $missing->load,          'load succeeds on a missing file' );
	is( $missing->get('any'),    undef, 'and the state is empty' );
	is( $missing->error,         undef, 'with no error' );

	# A crash can leave a truncated file. The program that would
	# rewrite it must not be the one that refuses to start.
	my $path = next_path();
	Fugu::File->write( $path, '{"count": 3' );

	my $corrupt = Fugu::StateFile->new( path => $path );
	ok( $corrupt->load, 'load survives a corrupt file' );
	is( $corrupt->get('count'), undef, 'the state is empty' );
	like( $corrupt->error, qr/Cannot read state/, 'and it says so' );

	# The store recovers by writing over it
	ok( $corrupt->set( 'count', 1 ), 'a write repairs the file' );
	is( Fugu::StateFile->new( path => $path )->load->get('count'),
		1, 'and the new state reads back' );

	# A file that holds JSON, but not an object, is corrupt too
	Fugu::File->write( $path, '[1, 2, 3]' );
	my $wrong = Fugu::StateFile->new( path => $path )->load;
	is( $wrong->get('count'), undef, 'a JSON array is not state' );
	ok( defined $wrong->error, 'and it says so' );
};

subtest 'save is atomic' => sub {
	my $path  = next_path();
	my $store = Fugu::StateFile->new( path => $path )->load;
	$store->set( 'good', 'value' );

	# A save that cannot finish must leave the previous file whole,
	# and must leave no partial file behind. A value that no encoder
	# can represent fails inside the call.
	my $unencodable = Fugu::StateFile->new( path => $path )->load;
	$unencodable->data->{code} = sub { 1 };

	is( $unencodable->save, undef, 'the save fails' );
	like( $unencodable->error, qr/Cannot write state/, 'and says so' );

	is( Fugu::StateFile->new( path => $path )->load->get('good'),
		'value', 'the previous state is intact' );

	opendir my $dh, $dir or die "opendir $dir: $!";
	my @partial = grep { /^\./ && !/^\.\.?$/ } readdir $dh;
	closedir $dh;
	is_deeply( \@partial, [], 'no partial file remains' );
};

subtest 'the mode keeps the state private' => sub {
	my $path = next_path();
	Fugu::StateFile->new( path => $path )->load->set( 'secret', 'value' );
	is( ( stat $path )[2] & 07777, 0600, 'the default mode is 0600' );

	my $open = next_path();
	Fugu::StateFile->new( path => $open, mode => 0644 )->load
	    ->set( 'public', 'value' );
	is( ( stat $open )[2] & 07777, 0644, 'the mode is configurable' );
};

subtest 'data gives the whole state for a batch change' => sub {
	my $path  = next_path();
	my $store = Fugu::StateFile->new( path => $path )->load;

	$store->data->{a} = 1;
	$store->data->{b} = 2;
	ok( $store->save, 'one save for two changes' );

	my $reader = Fugu::StateFile->new( path => $path )->load;
	is( $reader->get('a'), 1, 'the first change persisted' );
	is( $reader->get('b'), 2, 'and the second' );
};

subtest 'a missing path is a programming error' => sub {
	ok( !eval { Fugu::StateFile->new; 1 },              'new needs a path' );
	ok( !eval { Fugu::StateFile->new( path => '' ); 1 }, 'and a real one' );
};

done_testing();
