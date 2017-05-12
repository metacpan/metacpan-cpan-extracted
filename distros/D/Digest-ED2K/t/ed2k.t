use common::sense;
use Test::More tests => 14;

use Digest::ED2K qw(ed2k ed2k_hex ed2k_base64);
BEGIN { *CHUNK_SIZE = *Digest::ED2K::CHUNK_SIZE }

use constant BIN => {
	aaa => pack('H*', '918d7099b77c7a06634c62ccaf5ebac7'),
};

use constant HEX => {
	aaa => '918d7099b77c7a06634c62ccaf5ebac7',
};

use constant B64 => {
	aaa => 'kY1wmbd8egZjTGLMr166xw',
};

# OO
is(Digest::ED2K->new->add('aaa')->digest, BIN->{aaa}, 'OO ed2k ok');
is(Digest::ED2K->new->add('aaa')->hexdigest, HEX->{aaa}, 'OO ed2k_hex ok');
is(Digest::ED2K->new->add('aaa')->b64digest, B64->{aaa}, 'OO ed2k_b64 ok');

# Functional
is((ed2k 'aaa'), BIN->{aaa}, 'functional ed2k ok');
is((ed2k_hex 'aaa'), HEX->{aaa}, 'functional ed2k_hex ok');
is((ed2k_base64 'aaa'), B64->{aaa}, 'functional ed2k_base64 ok');

# Functional with @ prototypes
is ed2k(qw(a a a)), BIN->{aaa}, 'functional ed2k @ ok';
is ed2k_hex(qw(a a a)), HEX->{aaa}, 'functional ed2k_hex @ ok';
is ed2k_base64(qw(a a a)), B64->{aaa}, 'functional ed2k_base64 @ ok';

# Test the tricky CHUNK_SIZE multiples.
# http://wiki.anidb.net/w/Ed2k-hash#How_is_an_ed2k_hash_calculated_exactly.3F
my $zero_chunk = Digest::ED2K->new->add("\x00" x CHUNK_SIZE)->hexdigest;
isnt $zero_chunk, 'd7def262a127cd79096a108e7a9fc138', 'The blue method is not in use for ==CHUNK_SIZE';
is $zero_chunk, 'fc21d9af828f92a8df64beac3357425d', 'The red method is in use for ==CHUNK_SIZE';

my $zero_2chunk = Digest::ED2K->new->add("\x00" x (CHUNK_SIZE * 2))->hexdigest;
isnt $zero_2chunk, '194ee9e4fa79b2ee9f8829284c466051', 'The blue method is not in use for ==CHUNK_SIZE*2';
is $zero_2chunk, '114b21c63a74b6ca922291a11177dd5c', 'The red method is in use for ==CHUNK_SIZE*2';

# Clone
my $original = Digest::ED2K->new->add('abc123');
is $original->clone->hexdigest, $original->hexdigest, 'cloning works';
