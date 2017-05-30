#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

use Hash::Normalize qw<normalize get_normalization>;

my %h;
is get_normalization(%h), undef, 'brand new hash is not normalized';

normalize %h;
is get_normalization(%h), 'NFC', 'composed normalization by default';

normalize %h, 'nfd';
is get_normalization(%h), 'NFD', 'switch normalization to NFD';

normalize %h, 'd';
is get_normalization(%h), 'NFD', 'reapply the same normalization';

normalize %h, 'kc';
is get_normalization(%h), 'NFKC', 'switch normalization to NFKC';

normalize %h, 'NFkd';
is get_normalization(%h), 'NFKD', 'switch normalization to NFKD';

normalize %h, 'fCc';
is get_normalization(%h), 'FCC', 'switch normalization to FCC';

normalize %h, 'FcD';
is get_normalization(%h), 'FCD', 'switch normalization to FCD';

eval { normalize %h, 'XYZ' };
like $@, qr/^Invalid normalization /, 'invalid normalization croaks';
