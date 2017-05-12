#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "YAML is required for testing" unless eval { require YAML };
	plan "no_plan";
}

use utf8;

use ok 'Devel::StringInfo';

my $o = Devel::StringInfo->new;

my %strings = (
	ascii => "foo",
	uni_heb => "שלום",
	uni_fr => "Français",
);

my @core = keys %strings;

@strings{map { "${_}_utf8" }  @core} = map { Encode::encode(utf8  => $_) } @strings{@core};
@strings{map { "${_}_utf16" } @core} = map { Encode::encode(utf16 => $_) } @strings{@core};

@strings{qw(ascii_latin1 uni_fr_latin1)} = map { Encode::encode(latin1 => $_) } @strings{qw(ascii uni_fr)};

foreach my $str ( keys %strings ) {
	my $dump = $o->dump_info($strings{$str}, name => $str);

	like( $dump, qr/\Q$strings{$str}/, "contains string" );

	my $is_utf8 = 0+utf8::is_utf8($strings{$str});
	like( $dump, qr/is_utf8:\s*$is_utf8/, "is utf8 = $is_utf8" );

	like( $dump, qr/utf-16/i, "encoding guessed" ) if $str =~ /utf16/;
}
