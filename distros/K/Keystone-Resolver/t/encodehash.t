# $Id: encodehash.t,v 1.1 2007-05-24 21:38:46 mike Exp $

use strict;
use Test;
use Data::Dumper;

use vars qw(@hashes);
BEGIN {
    @hashes = (
	       {},
	       { foo => 34 },
	       { foo => 34, bar => "baz" },
	       { foo => "" },
	       { "" => "baz" },
	       { foo => "", "" => "baz" },
	       { "foo=bar" => "baz&fish" },
	       { "foo=bar" => "baz&fish", "baz&fish" => "foo=bar" },
	       { "foo?bar=baz&quux=thricken" => "the story+of%61 BAe" },
	       { a => 42, b => 43, c => 44, d => 45, e => 46, f => 47,
		 g => 48, h => 49, i => 50, j => 51, k => 52, l => 53,
		 m => 54, n => 55, o => 56, p => 57, q => 58, r => 59,
		 s => 60, t => 61, u => 62, v => 63, w => 64, x => 65,
		 y => 66, z => 67 },
	       { foo => "S\xf8nderberg" },
	       { foo => "S\x{f8}nderberg" },
	       { foo => "S\x{1234}nderberg" },
	       );

    plan tests => 1 + 2*scalar(@hashes);
};

use Keystone::Resolver::Utils qw(encode_hash decode_hash);
ok(1); # If we made it this far, we're ok.

foreach my $hash (@hashes) {
    my $s1 = encode_hash(%$hash);
    my %h2 = decode_hash($s1);
    ok(equal_hashes($hash, \%h2), 1,
       "hashes differ for '$s1' :" . Dumper([ $hash, \%h2 ]));
    my $s2 = encode_hash(%h2);
    ok($s1, $s2, "'$s1' != '$s2'");
}


# Return 1 if hashes are equal, 2 if not
sub equal_hashes {
    my($ref1, $ref2) = @_;

    my %h1 = %$ref1;
    my %h2 = %$ref2;
    foreach my $key (sort keys %h1) {
	my $d1 = defined $h1{$key};
	my $d2 = defined $h2{$key};
	return 0 if $d1 != $d2 || ($d1 && $h1{$key} ne $h2{$key});
	delete $h2{$key};
    }

    return 0 if %h2;
    return 1;
}
