#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use Dump::Krumo;
use Time::Piece;
use Devel::Peek;
use Getopt::Long;

my $debug = 0;
GetOptions(
	'debug' => \$debug,
);

$Dump::Krumo::debug = $debug;

###############################################################################
###############################################################################

my $item = $ARGV[0] || '';
my $t    = localtime();

my $var;
if (!$item || $item eq 'default') {
	my $str = "foobar";

	$var = { undef => undef,

    # strings
    str               => 'Jason',
    str_empty         => '',
    str_with_newlines => "Mark\nJason\rDominus\tKitten",

	str_quote        => '"foo"',
	str_single_quote => "foo'bar",

	scalar_ref => \$str,

	bool_true  => !!1,
	bool_false => !!0,

	int   => 4,
	float => 3.1415926,

	array       => [qw(Lorem Ipsum is simply "dummy" text 'of' the printing and typesetting industry. Lorem Ipsum)],
	array2      => [1, 2.2, "3", "a", "b", undef, [], 0, -1, -1.2],
	empty_array => [],

	hash       => {a=>1, b=>0, c=>[], d=>{}, e=>undef},
    empty_hash => {},

	obj1 => $t,
	obj2 => bless({a=>1, b=>2}, "Foo"),
	obj3 => bless(do{\(my $o = 1)}, "JSON::PP::Boolean"),

	bytes => "A\x01B\x02C\x03D\x04",

	coderef => \&color,

	glob => \*STDOUT,
	version => \v9.18.27,
};

} elsif ($item eq 'hash') {
	$var = { foo => [
        { name => 'Andi', dob => '1988-10-10', employee_id=>1, some_other_attribute => 'some value', },
        { name => 'Budi', dob => '1983-01-22', employee_id=>2, some_other_attribute => 'some value', },
		[qw(one two three four five six seven eight nine ten eleven)],
        "this one is not a hash",
    ],
};

} elsif ($item eq 'array') {
	$var = [qw(one two three four five six seven eight nine ten eleven twelve)];
} elsif ($item eq 'nesthash') {
	$var = { extended => [
			{
				ip => "65.182.224.220",
				ip_family => "ipv4",
				mac => "00:00:00:00:00:00",
				type => "static",
			}, # .[0]
			{
				ip => "65.182.224.218",
				ip_family => "ipv4",
				mac => "B8:27:EB:D5:98:37",
				type => "dhcp",
			},
		], # in this case, this line is not aligned with the matching "[" by DD
		int => "N91-1-1-1",
	};
} elsif ($item eq 'arrayref') {
	$var = {
		'long'  => [qw(one two three four five six seven eight nine ten eleven twelve)],
		'short' => [qw(one two three four five)],
	};
} elsif ($item eq 'class') {
	$var  = $t;
} elsif ($item eq 'bool') {
	# These are legacy compatible bools so we don't need to `use v5.40`
	$var = { true => !!1, false => !!0, num => 3 };
} elsif ($item eq 'regexp') {
	$var = qr/^(foo)bar.+?\z/,
} elsif ($item eq 'zero') {
	$var = 0;
} elsif ($item eq 'version') {
	$var = \v9.18.27;
}

kx($var);

###############################################################################
###############################################################################

sub trim {
	my ($s) = (@_, $_); # Passed in var, or default to $_
	if (!defined($s) || length($s) == 0) { return ""; }
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;

	return $s;
}

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
    my ($str, $txt) = @_;

    # If we're NOT connected to a an interactive terminal don't do color
    if (-t STDOUT == 0) { return $txt || ""; }

    # No string sent in, so we just reset
    if (!length($str) || $str eq 'reset') { return "\e[0m"; }

    # Some predefined colors
    my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
    $str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg;

    # Get foreground/background and any commands
    my ($fc,$cmd) = $str =~ /^(\d{1,3})?_?(\w+)?$/g;
    my ($bc)      = $str =~ /on_(\d{1,3})$/g;

    if (defined($fc) && int($fc) > 255) { $fc = undef; } # above 255 is invalid

    # Some predefined commands
    my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
    my $cmd_num = $cmd_map{$cmd // 0};

    my $ret = '';
    if ($cmd_num)      { $ret .= "\e[${cmd_num}m"; }
    if (defined($fc))  { $ret .= "\e[38;5;${fc}m"; }
    if (defined($bc))  { $ret .= "\e[48;5;${bc}m"; }
    if (defined($txt)) { $ret .= $txt . "\e[0m";   }

    return $ret;
}

sub file_get_contents {
	open(my $fh, "<", $_[0]) or return undef;
	binmode($fh, ":encoding(UTF-8)");

	my $array_mode = ($_[1]) || (!defined($_[1]) && wantarray);

	if ($array_mode) { # Line mode
		my @lines  = readline($fh);

		# Right trim all lines
		foreach my $line (@lines) { $line =~ s/[\r\n]+$//; }

		return @lines;
	} else { # String mode
		local $/       = undef; # Input rec separator (slurp)
		return my $ret = readline($fh);
	}
}

sub file_put_contents {
	my ($file, $data) = @_;

	open(my $fh, ">", $file) or return undef;
	binmode($fh, ":encoding(UTF-8)");
	print $fh $data;
	close($fh);

	return length($data);
}

# Creates methods k() and kd() to print, and print & die respectively
BEGIN {
	if (eval { require Data::Dump::Color }) {
		*k = sub { Data::Dump::Color::dd(@_) };
	} else {
		require Data::Dumper;
		*k = sub { print Data::Dumper::Dumper(\@_) };
	}

	sub kd {
		k(@_);

		printf("Died at %2\$s line #%3\$s\n",caller());
		exit(15);
	}
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
