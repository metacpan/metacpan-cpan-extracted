# Test constructor errors. Might be overkill?
use strict;
use warnings;
use Test::More;

use Gzip::RandomAccess;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed for exception tests" if $@;
}

plan tests => 9;

throws_ok {
    my $gzip = Gzip::RandomAccess->new();
} qr/Missing filename/;

throws_ok {
    my $gzip = Gzip::RandomAccess->new({});
} qr/Missing filename/;

throws_ok {
    my $gzip = Gzip::RandomAccess->new(undef);
} qr/Undefined filename/;
throws_ok {
    my $gzip = Gzip::RandomAccess->new({ file => undef });
} qr/Undefined filename/;

throws_ok {
    my $gzip = Gzip::RandomAccess->new({ index_file => 'foo' });
} qr/Missing filename/;

throws_ok {
    my $gzip = Gzip::RandomAccess->new([]);
} qr/Filename must be a scalar/;
throws_ok {
    my $gzip = Gzip::RandomAccess->new(file => []);
} qr/Filename must be a scalar/;

throws_ok {
    my $gzip = Gzip::RandomAccess->new('a', 'b', 'c');
} qr/Pass either a filename or a hash of arguments/;

throws_ok {
    my $gzip = Gzip::RandomAccess->new(file => 'a', foo => 1);
} qr/Invalid argument 'foo'/;
