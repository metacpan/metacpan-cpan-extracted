#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use Scalar::Util;

package Dump::Krumo;

use Exporter 'import';
our @EXPORT  = qw(kx kxd);

# https://blogs.perl.org/users/grinnz/2018/04/a-guide-to-versions-in-perl.html
our $VERSION = 'v0.1.2';

our $use_color     = 1; # Output in color
our $return_string = 0; # Return a string instead of printing it
our $hash_sort     = 1; # Sort hash keys before output
our $debug         = 0; # Low level developer level debugging
our $disable       = 0; # Disable Dump::Krumo
our $indent_spaces = 2; # Number of spaces to use for each level of indent

# Global var to track how many levels we're indented
my $current_indent_level = 0;
# Global var to track the indent to the right end of the most recent hash key
my $left_pad_width       = 0;

our $COLORS = {
	'string'       => 230, # Standard strings
	'control_char' => 226, # the `\n`, `\r`, and `\t` inside strings
	'undef'        => 196, # undef
	'hash_key'     => 208, # hash keys on the left of =>
	'integer'      => 33,  # integers
	'float'        => 51,  # things that look like floating point
	'class'        => 118, # Classes/Object names
	'binary'       => 111, # Strings that contain non-printable chars
	'scalar_ref'   => 225, # References to scalar variables
	'boolean'      => 141, # Native boolean types
	'regexp'       => 164, # qr() style regexp variables
	'glob'         => 40,  # \*STDOUT variables
	'coderef'      => 168, # code references
	'vstring'      => 153, # Version strings
	'empty_braces' => 15,  # Either [] or {}
};

my $WIDTH = get_terminal_width();
$WIDTH  ||= 100;

###############################################################################
###############################################################################

# Dump the variable information
sub kx {
	my @arr = @_;

	if ($disable) { return -1; }

	my @items    = ();
	my $cnt      = scalar(@arr);
	my $is_array = 0;

	# If someone passes in a real array (not ref) we fake it out
	if ($cnt > 1 || $cnt == 0) {
		@arr      = (\@_); # Convert to arrayref
		$is_array = 1;
	}

	# Loop through each item and dump it out
	foreach my $item (@arr) {
		push(@items, __dump($item));
	}

	if (!@items) {
		@items = ("UNKNOWN TYPE");
	}

	my $str = join(", ", @items);

	# If it's a real array we remove the false [ ] added by __dump()
	if ($is_array) {
		my $len = length($str) - 2;
		$str    = substr($str, 1, $len);
	}

	if ($cnt > 1 || $cnt == 0) {
		$str = "($str)";
	}

	if ($return_string) {
		return "$str";
	} else {
		print "$str\n";
	}
}

# Dump the variable and die and output file/line
sub kxd {
	kx(@_);

	my @call = caller();
	my $file = $call[1];
	my $line = $call[2];

	printf("\nDump::Krumo called from %s line %s\n", color('white', $file), color(194, "#$line"));
	exit(15);
}

# Generic dump that handles each type appropriately
sub __dump {
	my $x     = shift();
	my $type  = ref($x);
	my $class = Scalar::Util::blessed($x) || "";

	my $ret;

	if ($type eq 'ARRAY') {
		$ret = __dump_array($x);
	} elsif ($type eq 'HASH') {
		$ret = __dump_hash($x);
	} elsif ($type eq 'SCALAR') {
		$ret = color($COLORS->{scalar_ref}, '\\' . quote_string($$x));
	} elsif (!$type && is_bool_val($x)) {
		$ret = __dump_bool($x);
	} elsif (!$type && is_integer($x)) {
		$ret = __dump_integer($x);
	} elsif (!$type && is_float($x)) {
		$ret = __dump_float($x);
	} elsif (!$type && is_string($x)) {
		$ret = __dump_string($x);
	} elsif (!$type && is_undef($x)) {
		$ret = __dump_undef();
	} elsif ($class eq "Regexp") {
		$ret = __dump_regexp($class, $x);
	} elsif ($type eq "GLOB") {
		$ret = __dump_glob($class, $x);
	} elsif ($type eq "CODE") {
		$ret = __dump_coderef($class, $x);
	} elsif ($type eq "VSTRING") {
		$ret = __dump_vstring($x);
	} elsif ($class) {
		$ret = __dump_class($class, $x);
	} else {
		$ret = "Unknown variable type: '$type'";
	}

	return $ret;
}

################################################################################
# Each variable type gets it's own dump function
################################################################################

sub __dump_bool {
	my $x = shift();
	my $ret;

	if ($x) {
		$ret = color($COLORS->{boolean}, "true");
	} else {
		$ret = color($COLORS->{boolean}, "false");
	}

	return $ret;
}

sub __dump_regexp {
	my ($class, $x) = @_;

	my $ret = color($COLORS->{regexp}, "qr$x");

	return $ret;
}

sub __dump_coderef {
	my ($class, $x) = @_;

	my $ret = color($COLORS->{coderef}, "sub { ... }");

	return $ret;
}

sub __dump_glob {
	my ($class, $x) = @_;

	my $ret = color($COLORS->{glob}, "\\" . $$x);

	return $ret;
}

sub __dump_class {
	my ($class, $x) = @_;

	my $ret      = '"' . color($COLORS->{class}, $class) . "\" :: ";
	my $reftype  = Scalar::Util::reftype($x);
	my $y;

	# We need an unblessed copy of the data so we can display it
	if ($reftype eq 'ARRAY') {
		$y = [@$x];
	} elsif ($reftype eq 'HASH') {
		$y = {%$x};
	} elsif ($reftype eq 'SCALAR') {
		$y = $$x;
	} else {
		$y = "Unknown class?";
	}

	$ret .= __dump($y);

	return $ret;
}

sub __dump_integer {
	my $x   = shift();
	my $ret = color($COLORS->{integer}, $x);

	return $ret;
}

sub __dump_float {
	my $x   = shift();
	my $ret = color($COLORS->{float}, $x);

	return $ret;
}

sub __dump_vstring {
	my $x   = shift();

	my @parts = unpack("C*", $$x);
	my $str   = "\\v" .(join ".", @parts);

	my $ret = color($COLORS->{vstring}, $str);

	return $ret;
}

sub __dump_string {
	my $x = shift();

	if (length($x) == 0) {
		return color($COLORS->{empty_braces}, "''"),
	}

	my $printable = is_printable($x);

	# Convert all \n to printable version
	my $slash_n = color($COLORS->{control_char}, '\\n') . color($COLORS->{string});
	my $slash_r = color($COLORS->{control_char}, '\\r') . color($COLORS->{string});
	my $slash_t = color($COLORS->{control_char}, '\\t') . color($COLORS->{string});

	my $ret = '';

	# For short strings we show the unprintable chars as \x{00} escapes
	if (!$printable && (length($x) < 20)) {
		my @p = unpack("C*", $x);

		my $str  = '';
		foreach my $x (@p) {
			my $is_printable = is_printable(chr($x));

			if ($is_printable) {
				$str .= chr($x);
			} else {
				$str .= '\\x{' . sprintf("%02X", $x) . '}';
			}
		}

		$ret = color($COLORS->{binary}, "\"$str\"");
	# Longer unprintable stuff we just spit out the raw HEX
	} elsif (!$printable) {
		$ret = color($COLORS->{binary}, 'pack("H*", ' . bin2hex($x) . ")");
	# If it's a simple string we single quote it
	} elsif ($x =~ /^[\w .,":;?!#\$%^*&\/=-]*$/g) {
		$ret = "'" . color($COLORS->{string}, "$x") . "'";
	# Otherwise we clean it up and then double quote it
	} else {
		# Do some clean up here?
		$ret = '"' . color($COLORS->{string}, "$x") . '"';
	}

	$ret =~ s/\n/$slash_n/g;
	$ret =~ s/\r/$slash_r/g;
	$ret =~ s/\t/$slash_t/g;

	return $ret;
}

sub __dump_undef {
	my $ret = color($COLORS->{undef}, 'undef');

	return $ret;
}

sub __dump_array {
	my $x = shift();

	# If it's only a single element we return the stringified version of that
	if (ref($x) ne 'ARRAY') {
		return __dump("$x");
	}

	$current_indent_level++;

	my $cnt = scalar(@$x);
	if ($cnt == 0) {
		$current_indent_level--;
		return color($COLORS->{empty_braces}, '[]'),
	}

	# See if we need to switch to column mode to output this array
	my $column_mode = needs_column_mode($x);

	my $ret = '';
	my @items = ();
	foreach my $z (@$x) {
		push(@items, __dump($z));
	}

	if ($column_mode) {
		$ret = "[\n";
		my $pad = " " x ($current_indent_level * $indent_spaces);
		foreach my $x (@items ) {
			$ret .= $pad . "$x,\n";
		}

		$pad = " " x (($current_indent_level - 1) * $indent_spaces);
		$ret .= $pad . "]";
	} else {
		$ret = '[' . join(", ", @items) . ']';
	}

	$current_indent_level--;

	return $ret;
}

sub __dump_hash {
	my $x = shift();
	$current_indent_level++;

	my $ret;
	my @items = ();
	my @keys  = keys(%$x);
	my @vals  = values(%$x);
	my $cnt   = scalar(@keys);

	# There may be some weird scenario where we do NOT want to sort
	if ($hash_sort) {
		@keys = sort(@keys);
	}

	if ($cnt == 0) {
		$current_indent_level--;
		return color($COLORS->{empty_braces}, '{}'),
	}

	# See if we need to switch to column mode to output this array
	my $max_length  = max_length(@keys);
	$left_pad_width = $max_length;
	my $column_mode = needs_column_mode($x);

	# If we're not in column mode there is no need to compensate for this
	if (!$column_mode) {
		$max_length = 0;
	}

	# Check to see if any of the array keys need to be quoted
	my $keys_need_quotes = 0;
	foreach my $key (@keys) {
		if ($key =~ /\W/) {
			$keys_need_quotes = 1;
			last;
		}
	}

	# Loop through each key and build the appropriate string for it
	foreach my $key (@keys) {
		my $val = $x->{$key};

		my $key_str = '';
		if ($keys_need_quotes) {
			$key_str = "'" . color($COLORS->{hash_key}, $key) . "'";
		} else {
			$key_str = color($COLORS->{hash_key}, $key);
		}

		# Align the hash keys
		if ($column_mode) {
			my $raw_len     = length($key);
			my $append_cnt  = $max_length - $raw_len;

			# Sometimes this goes negative?
			if ($append_cnt < 0) {
				$append_cnt = 0;
			}

			$key_str .= " " x $append_cnt;
		}

		push(@items, $key_str . ' => ' . __dump($val));
	}

	# If we're too wide for the screen we drop to column mode
	if ($column_mode) {
		$ret = "{\n";

		foreach my $x (@items) {
			my $pad = " " x ($current_indent_level * $indent_spaces);
			$ret .= $pad . "$x,\n";
		}

		my $pad = " " x (($current_indent_level - 1) * $indent_spaces);
		$ret .= $pad . "}";
	} else {
		$ret = '{ ' . join(", ", @items) . ' }';
	}

	$current_indent_level--;

	return $ret;
}

################################################################################
# Various helper functions
################################################################################

# Calculate the length of the longest string in an array
sub max_length {
	my $max = 0;

	foreach my $item (@_) {
		my $len = length($item);
		if ($len > $max) {
			$max = $len;
		}
	}

	return $max;
}

# Calculate the length in chars of this array
sub array_str_len {
	my @arr = @_;

	my $len = 0;
	foreach my $x (@arr) {
		if (!defined($x)) {
			$len += 5; # The string "undef"
		} elsif (ref $x eq 'ARRAY') {
			$len += array_str_len(@$x);
		} elsif (ref $x eq 'HASH') {
			$len += array_str_len(%$x);
		} else {
			$len += length($x);
			$len += 2; # For the quotes around the string
		}

		# We stop counting after we hit $WIDTH so we don't
		# waste a bunch of CPU cycles counting something we
		# won't ever use (useful in big nested objects)
		if ($len > $WIDTH) {
			return $WIDTH + 999;
		}
	}

	return $len;
}

# Calculate if this data structure will wrap the screen and needs to be in column mode instead
sub needs_column_mode {
	my $x = shift();

	my $ret  = 0;
	my $len  = 0;
	my $type = ref($x);

	if ($type eq "ARRAY") {
		my $cnt = scalar(@$x);

		$len += array_str_len(@$x);
		$len += 2;        # For the '[' on the start/end
		$len += 2 * $cnt; # ', ' for each item
	} elsif ($type eq "HASH") {
		my @keys = keys(%$x);
		my @vals = values(%$x);
		my $cnt  = scalar(@keys);

		$len += array_str_len(@keys);
		$len += array_str_len(@vals);
		$len += 4;        # For the '{ ' on the start/end
		$len += 6 * $cnt; # ' => ' and the ', ' for each item
	# This is a class/obj
	} elsif ($type) {
		my $cnt = scalar(@$x);

		$len += array_str_len(@$x);
		$len += 2;        # For the '[' on the start/end
		$len += 2 * $cnt; # ' => ' and the ', ' for each item
	}

	my $content_len = $len;

	# Current number of spaces we're indented from the left
	my $left_indent  = ($current_indent_level - 1) * $indent_spaces;
	# Where the ' => ' in the hash key ends
	my $pad_width    = $left_pad_width + 4; # For the ' => '

	# Add it all together
	$len = $left_indent + $pad_width + $len;

	# If we're too wide for the screen we drop to column mode
	# Our math isn't 100% down the character so we use 97% to give
	# ourselves some wiggle room
	if ($len > ($WIDTH * .97)) {
		$ret = 1;
	}

	# This math is kinda gnarly so if we turn on debug mode we can
	# see each array/hash and how we calculate the length
	if ($debug) {
		state $first = 1;

		if ($first) {
			printf("Screen width: %d\n\n", $WIDTH * .97);
			printf("Left Indent | Hash Padding | Content | Total\n");
			$first = 0;
		}
		printf("%8d    +    %6d    +  %4d   = %4d    (%d)\n", $left_indent, $pad_width, $content_len, $len, $ret);
	}

	return $ret;
}

# Convert raw bytes to hex for easier printing
sub bin2hex {
	my $bytes = shift();
	my $ret   = uc(unpack("H*", $bytes));

	return $ret;
}

################################################################################
# Test functions to determine what type of variable something is
################################################################################

# Does the string contain only printable characters
sub is_printable {
	my ($str) = @_;

	if (length($str) == 1 && (ord($str) >= 127)) {
		return 0;
	}

	my $ret = 0;
	if (defined($str) && $str =~ /^[[:print:]\n\r\t]*$/) {
		$ret = 1;
	}

	return $ret;
}

sub is_undef {
	my $x = shift();

	if (!defined($x)) {
		return 1;
	} else {
		return 0;
	}
}

# Veriyf this
sub is_nan {
	my $x   = shift();
	my $ret = 0;

	if ($x != $x) {
		$ret = 1;
	}

	return $ret;
}

# Veriyf this
sub is_infinity {
	my $x   = shift();
	my $ret = 0;

	if ($x * 2 == $x) {
		$ret = 1;
	}

	return $ret;
}

sub is_string {
    my ($value) = @_;
    return defined($value) && $value !~ /^-?\d+(?:\.\d+)?$/;
}

sub is_integer {
    my ($value) = @_;
    return defined($value) && $value =~ /^-?\d+$/;
}

sub is_float {
    my ($value) = @_;
    #my $ret     = defined($value) && $value =~ /^-?\d+\.\d+$/;
    my $ret     = defined($value) && $value =~ /^-?\d+\.\d+(e[+-]\d+)?$/;

	return $ret;
}

# Borrowed from builtin::compat
sub is_bool_val {
	my $value = shift;

	# Make sure the variable is defined, is not a reference and is a dualval
	if (!defined($value))              { return 0; }
	if (length(ref($value)) != 0)      { return 0; }
	if (!Scalar::Util::isdual($value)) { return 0; }

	# Make sure the string and integer versions match
	if ($value == 1 && $value eq '1')  { return 1; }
	if ($value == 0 && $value eq '')   { return 1; }

	return 0;
}

################################################################################

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
    my ($str, $txt) = @_;

    # If we're NOT connected to a an interactive terminal don't do color
    if (!$use_color || -t STDOUT == 0) { return $txt // ""; }

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

sub get_terminal_width {
	# If there is no $TERM then tput will bail out
	if (!$ENV{TERM} || -t STDOUT == 0) {
		return 0;
	}

	my $tput = `tput cols`;

	my $width = 0;
	if ($tput) {
		$width = int($tput);
	} else {
		print color('orange', "Warning:") . " `tput cols` did not return numeric input\n";
		$width = 80;
	}

	return $width;
}

# See also B::perlstring as a possible alternative
sub quote_string {
	my ($s) = @_;

	# Use single quotes if no special chars
	if ($s !~ /[\'\\\n\r\t\f\b\$@"]/ ) {
		return "'$s'";
	}

	# Otherwise, escape for double quotes
	(my $escaped = $s) =~ s/([\\"])/\\$1/g;
	$escaped =~ s/\n/\\n/g;
	$escaped =~ s/\r/\\r/g;
	$escaped =~ s/\t/\\t/g;
	$escaped =~ s/\f/\\f/g;
	$escaped =~ s/\b/\\b/g;

	return "\"$escaped\"";
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

################################################################################
################################################################################
################################################################################

=encoding utf8

=head1 NAME

Dump::Krumo - Fancy, colorful, human readable dumps of your data

=head1 SYNOPSIS

    use Dump::Krumo;

    my $data = { one => 1, two => 2, three => 3 };
    kx($data);

    my $list = ['one', 'two', 'three', 'four'];
    kxd($list);

=head1 DESCRIPTION

Colorfully dump your data to make debugging variables easier. C<Dump::Krumo>
focuses on making your data human readable and easily parseable.

=begin markdown

# SCREENSHOTS

<img width="1095" height="878" alt="dk-ss" src="https://github.com/user-attachments/assets/b7138f3d-3144-4b1a-a063-9ca445dd34d4" />

=end markdown

=head1 METHODS

=over 4

=item B<kx($var)>

Debug print C<$var>.

=item B<kxd($var)>

Debug print C<$var> and C<die()>. This outputs file and line information.

=back

=head1 OPTIONS

=over 4

=item C<$Dump::Krumo::use_color = 1>

Turn on/off color

=item C<$Dump::Krumo::return_string = 0>

Return a string instead of printing out

=item C<$Dump::Krumo::indent_spaces = 2>

Number of spaces to indent each level

=item C<$Dump::Krumo::disable = 0>

Disable all output from C<Dump::Krumo>. This allows you to leave all of your
debug print statements in your code, and disable them at runtime as needed.

=back

=head1 SEE ALSO

=over

=item *
L<Data::Dumper>

=item *
L<Data::Dump>

=item *
L<Data::Dump::Color>

=item *
L<Data::Printer>

=back

=head1 AUTHOR

Scott Baker - L<https://www.perturb.org/>

=cut

1;

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
