#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;

use_ok( 'ExtUtils::Typemaps::STL::List' );
use_ok( 'ExtUtils::Typemaps::STL' );
use_ok( 'ExtUtils::Typemaps::Default' );

# Test ExtUtils::Typemaps::STL::List directly
my $lmap = ExtUtils::Typemaps::STL::List->new();
isa_ok($lmap, 'ExtUtils::Typemaps::STL::List');

my $lstr = $lmap->as_string;
ok(defined $lstr && length($lstr) > 0, "Typemap string generated");

# Count av_extend calls: 3 numeric types * 2 (val/ptr) + 2 std::string (val/ptr) + 2 cstring (val/ptr) = 10
my @all_av_extend = ($lstr =~ /(av_extend\s*\([^)]+\);)/g);
is(scalar(@all_av_extend), 10, "Found exactly 10 av_extend calls in List typemaps");

# Count guarded av_extend calls: if (len)\s+av_extend(av, len-1);
my @guarded = ($lstr =~ /if\s*\(\s*len\s*\)\s*\n\s*av_extend\s*\(\s*av\s*,\s*len-1\s*\);/g);
is(scalar(@guarded), 10, "All 10 av_extend calls are guarded with 'if (len)' (CVE-2026-107794)");

# Ensure there are no unguarded av_extend calls (all av_extend are guarded)
is(scalar(@guarded), scalar(@all_av_extend), "No unguarded av_extend found in List typemaps");

# Verify CSTRING list output typemaps increment index i (av_store(av, i++, ...))
my @c_stores = ($lstr =~ /av_store\s*\(\s*av\s*,\s*i\+\+\s*,\s*newSVpv/g);
cmp_ok(scalar(@c_stores), '>=', 2, "C-string list stores use i++ increment");

# Verify merged ExtUtils::Typemaps::STL
my $stl = ExtUtils::Typemaps::STL->new();
my $stl_str = $stl->as_string;
my @stl_guarded = ($stl_str =~ /if\s*\(\s*len\s*\)\s*\n\s*av_extend\s*\(\s*av\s*,\s*len-1\s*\);/g);
cmp_ok(scalar(@stl_guarded), '>=', 12, "STL merged typemap has guarded av_extend for both Vector and List");

# Verify merged ExtUtils::Typemaps::Default
my $def = ExtUtils::Typemaps::Default->new();
my $def_str = $def->as_string;
my @def_guarded = ($def_str =~ /if\s*\(\s*len\s*\)\s*\n\s*av_extend\s*\(\s*av\s*,\s*len-1\s*\);/g);
cmp_ok(scalar(@def_guarded), '>=', 12, "Default merged typemap has guarded av_extend for both Vector and List");

# Check version is 1.07
is($ExtUtils::Typemaps::STL::List::VERSION, '1.07', "ExtUtils::Typemaps::STL::List version is 1.07");
is($ExtUtils::Typemaps::Default::VERSION, '1.07', "ExtUtils::Typemaps::Default version is 1.07");
