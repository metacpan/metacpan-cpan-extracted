use strict;
use warnings;
use Test::More;
use Git::Libgit2 qw( init_lib );
use Git::Native::Oid;

# from_hex/raw drive into libgit2's oid helpers, so the FFI must be attached.
init_lib();

# Unit tests for Git::Native::Oid - the value object every OID flows through.
# Until now it was only exercised indirectly (stringified inside roundtrip
# asserts), so its own contract went untested: hex<->raw conversions, the
# length guard, short(), and the overloaded '""' / 'eq' operators.

my $hex = 'da39a3ee5e6b4b0d3255bfef95601890afd80709';   # sha1 of empty input

# ---- from_hex / hex roundtrip ----
my $oid = Git::Native::Oid->from_hex($hex);
isa_ok $oid, 'Git::Native::Oid', 'from_hex returns an Oid';
is $oid->hex, $hex, 'hex round-trips from_hex input';
is length( $oid->raw ), 20, 'raw is 20 bytes';

# ---- from_raw roundtrip + length guard ----
my $oid2 = Git::Native::Oid->from_raw( $oid->raw );
is $oid2->hex, $hex, 'from_raw(raw) reproduces the same hex';
my $err = do { local $@; eval { Git::Native::Oid->from_raw('too short') }; $@ };
like $err, qr/20 bytes/, 'from_raw rejects a wrong-length blob';

# ---- short() ----
is $oid->short,     substr( $hex, 0, 7 ),  'short() defaults to 7 chars';
is $oid->short(10), substr( $hex, 0, 10 ), 'short($n) honours the requested width';
is length( $oid->short ), 7, 'short() really is 7 wide';

# ---- '""' overload ----
is "$oid", $hex, 'stringification yields full hex';

# ---- 'eq' overload: Oid<->Oid and Oid<->string ----
ok( $oid eq $oid2, 'two Oids built from the same hex compare equal' );
ok( $oid eq $hex,  'an Oid compares equal to its hex string' );
my $other = Git::Native::Oid->from_hex( '0' x 40 );
ok( !( $oid eq $other ), 'distinct Oids are not equal' );
ok( !( $oid eq '0' x 40 ), 'Oid is not equal to a different hex string' );

# ---- from_ptr guards against a null pointer ----
my $perr = do { local $@; eval { Git::Native::Oid->from_ptr(0) }; $@ };
like $perr, qr/null pointer/, 'from_ptr croaks on a null pointer';

done_testing;
