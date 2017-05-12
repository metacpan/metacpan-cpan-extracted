use strict;
use warnings;

use Test::More (tests => 34);

BEGIN { use_ok("Linux::Ext2::Attributes", qw(:flags)) or exit; }

sub test_set {
	my ($attrs, $value, $flags, $string) = @_;
	
	$attrs->set($value);
	
	my $ok = is($attrs->flags, $flags, "Attributes->set($value): Attributes->flags");
	
	my $expect_string = join("", sort { $a cmp $b } split(//, $string));
	my $got_string    = join("", sort { $a cmp $b } split(//, $attrs->string));
	
	return is($got_string, $expect_string, "Attributes->set($value): Attributes->string") && $ok;
}

SKIP: {
	my $attrs = Linux::Ext2::Attributes->new;
	
	isa_ok($attrs, "Linux::Ext2::Attributes", "Attributes->new()")
		or skip("Parent test failed", 2);
	
	is($attrs->flags, 0, "Attributes->flags");
	is($attrs->string, "", "Attributes->string");
}

SKIP: {
	my $attrs = Linux::Ext2::Attributes->new(EXT2_NOATIME_FL);
	
	isa_ok($attrs, "Linux::Ext2::Attributes", "Attributes->new(EXT2_NOATIME_FL)")
		or skip("Parent test failed", 10);
	
	is($attrs->flags, EXT2_NOATIME_FL, "Attributes->new(EXT2_NOATIME_FL): Attributes->flags")
		or skip("Parent test failed", 9);
	
	is($attrs->string, "A", "Attributes->new(EXT2_NOATIME_FL): Attributes->string")
		or skip("Parent test failed", 8);
	
	# Test ->flags and ->string returns expected values after using ->set
	
	SKIP: {
		test_set($attrs, "+ac", EXT2_NOATIME_FL | EXT2_COMPR_FL | EXT2_APPEND_FL, "Aca")
			or skip("Parent test failed", 6);
		
		test_set($attrs, "-A", EXT2_COMPR_FL | EXT2_APPEND_FL, "ac")
			or skip("Parent test failed", 4);
		
		test_set($attrs, "-c+Ai", EXT2_APPEND_FL | EXT2_NOATIME_FL | EXT2_IMMUTABLE_FL, "aAi")
			or skip("Parent test failed", 2);
	}
	
	test_set($attrs, "c", EXT2_COMPR_FL, "c");
}

sub test_flag_func {
	my ($func, $name, $flags) = @_;
	
	my $attrs = Linux::Ext2::Attributes->new();
	
	SKIP: {
		ok($func->($attrs, 1) && $attrs->flags == $flags, "Attributes->$name(1)")
			or skip("Test failed", 3);
		
		ok($func->($attrs), "Attributes->$name - pre true");
		
		SKIP: {
			ok(!$func->($attrs, 0) && $attrs->flags == 0, "Attributes->$name(0)")
				or skip("Test failed", 1);
			
			ok(!$func->($attrs), "Attributes->$name - pre false");
		}
	}
}

test_flag_func(\&Linux::Ext2::Attributes::immutable, "immutable", EXT2_IMMUTABLE_FL);
test_flag_func(\&Linux::Ext2::Attributes::append_only, "append_only", EXT2_APPEND_FL);

sub test_flag {
	my ($flag, $expect_flag) = @_;
	
	my $attrs = Linux::Ext2::Attributes->new();
	
	SKIP: {
		ok($attrs->flag($flag, 1) && $attrs->flags == $expect_flag, "Attributes->flag($flag, 1)")
			or skip("Test failed", 3);
		
		ok($attrs->flag($flag), "Attributes->flag($flag) - pre true");
		
		SKIP: {
			ok(!$attrs->flag($flag, 0) && $attrs->flags == 0, "Attributes->flag($flag, 0)")
				or skip("Test failed", 1);
			
			ok(!$attrs->flag($flag), "Attributes->flag($flag) - pre false");
		}
	}
}

test_flag(EXT2_APPEND_FL, EXT2_APPEND_FL);
test_flag("i", EXT2_IMMUTABLE_FL);

sub test_strip {
	my ($flags, $stripped_flags) = @_;
	
	my $attrs = Linux::Ext2::Attributes->new($flags)->strip;
	
	is($attrs->flags, $stripped_flags, "Attributes->strip ($flags)");
}

test_strip(EXT2_NOATIME_FL, EXT2_NOATIME_FL);
test_strip(EXT2_NOATIME_FL | EXT4_EXTENTS_FL, EXT2_NOATIME_FL);
test_strip(EXT4_EXTENTS_FL | EXT2_NOCOMP_FL, 0);
