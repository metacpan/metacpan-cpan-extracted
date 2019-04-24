#!/usr/bin/perl -w

use strict;


BEGIN {
    require Test::More;
    unless (eval "no warnings 'experimental::signatures'; 1") {
	Test::More->import(skip_all => "No signatures");
    }
    # Ho ho, this is going to need a better implementation once they are no
    # longer experimental.
    Test::More->import();
}

no warnings "experimental::signatures";
use feature "signatures";

use Devel::Size qw(total_size);

my $warn_count;

$SIG{__WARN__} = sub {
    return if $_[0] eq "Devel::Size: Can't size up perlio layers yet\n";
    ++$warn_count;
    warn @_;
};

# This is mostly a test for the benifit of taunting ASAN and the warnings code.

cmp_ok(total_size(sub ($foo) {}), '>', 0, "basic signature");
cmp_ok(total_size(sub ($bar = "x" x 1024) {}), '>', 1024, "signature with default");
cmp_ok(total_size(sub ($foo, @bar) {}), '>', 0, "more signature");
cmp_ok(total_size(sub (%baz) {}), '>', 0, "more slurpy");

is($warn_count, undef, 'No warnings emitted');

done_testing();
