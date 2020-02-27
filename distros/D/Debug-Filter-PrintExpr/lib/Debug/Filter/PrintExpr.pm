package Debug::Filter::PrintExpr;

use strict;
use warnings;
 
use 5.010;
use Exporter::Tiny;
use Filter::Simple;
use Scalar::Util qw(isdual blessed);
use List::Util 'pairs';
use Data::Dumper;

our
$VERSION = '0.18';

our @EXPORT_OK = qw(isnumeric isstring);
our @ISA = qw(Exporter::Tiny);
our %EXPORT_TAGS = (
	debug => [],
	nofilter => [],
	all	=> [qw(isnumeric isstring)],
);

require XSLoader;
XSLoader::load('Debug::Filter::PrintExpr', $VERSION);

# Make Exporter::Tiny::import ours, so this will be called by Filter::Simple
BEGIN {*import = \&Exporter::Tiny::import;}

# variable is exposed and my be overwritten by caller
our $handle = *STDERR;

# generate a prefix containing line number or custom label
# consume first three args, return number of printed chars
# if no expression is present
sub _genprefix {
	my ($label, $line, $expr, $pos) = splice @_, 0, 3;
	local ($,, $\);
	printf $handle "%s%n", $label || "L$line:", $pos;
	print $handle $expr ? " $expr = " : " ";
	return $expr ? undef : $pos + 1;
}

# create representation of single value
sub _singlevalue {
	my ($val, $str, $num) = shift;
	my $isdual = isdual($val);
	my $isnumeric = isnumeric($val);
	$str = "$val" if defined $val;
	$num = $val + 0 if $isnumeric;
	if (!defined $val) {
		return 'undef';
	} elsif (my $class = blessed($val)) {
		return "blessed($class)";
	} elsif (ref($val)) {
		return $val;
	} elsif ($isdual) {
		return "dualvar($num, '$str')";
	} elsif ($isnumeric) {
		return $num;
	} else {
		return "'$str'";
	}
}

# print out an expression in scalar context
sub _valuescalar {
	local ($,, $\);
	print $handle _singlevalue($_[0]);
}

# print out an expression in list context
sub _valuearray {
	local ($,, $\);
	print $handle '(', join(', ',
		map({_singlevalue($_)} @_)), ");\n";
}

# print out an expression as key-value pairs
sub _valuehash {
	local ($,, $\);
	print $handle '(', join(", ",
		map(
		{"'$_->[0]' => " . _singlevalue($_->[1])}
		pairs(@_))), ");\n";
}

# process a scalar debug statement
sub _print_scalar {
	local ($,, $\);
	unless (&_genprefix) {
		_valuescalar($_[0]);
		print $handle ';';
	}
	print $handle "\n";
}

# process a string scalar debug statement
sub _print_str {
	my $val = $_[3];
	splice @_, 3, 1, "$val";
	goto &_print_scalar;
}

# process a numeric scalar debug statement
sub _print_num {
	no warnings qw(numeric);
	my $val = $_[3];
	splice @_, 3, 1, $val + 0;
	goto &_print_scalar;
}

# process an array debug statement
sub _print_array {
	&_genprefix;
	goto &_valuearray;
}

# process a hash debug statement
sub _print_hash {
	&_genprefix;
	goto &_valuehash;
}

# process a reference debug statement
sub _print_ref {
	my $expr = splice @_, 2, 1, undef;
	my $skip = &_genprefix;
	local ($,, $\);
	print $handle "dump($expr);\n";
	print $handle 
		Data::Dumper->new([@_], [map("_[$_]", (0 .. $#_))])
		->Pad(' ' x $skip)->Dump;
}

# type classifications: print function suffix + is scalar
my %type_defs = (
	'$' => ['scalar', 1],
	'"' => ['str', 1],
	'#' => ['num', 1],
	'@' => ['array', 0],
	'%' => ['hash', 0],
	'\\' => ['ref', 0],
);

# process a debug statement, runs in filter context
sub _gen_print {
	my ($type, $label, $expr) = map $_ // '', @_;
	my $val = $_[2] // '()';
	my ($ptype, $scalar) = @{$type_defs{$type}};
	my $print = __PACKAGE__ . "::_print_$ptype";
	return qq[{$print("$label", __LINE__, q{$expr}, ] .
		($scalar ? qq[scalar($val)] : qq[$val]) .
		q[)}];
}

# source code processing happens here
FILTER {
	my ($self, @args) = @_;
	my ($nofilter, $debug);
	if (ref($_[1]) eq 'HASH') {
		my $global = $_[1];
		$debug = $global->{debug};
		$nofilter = $global->{nofilter};
	}
	$debug ||= grep /^-debug$/, @args;
	$nofilter ||= grep /^-nofilter$/, @args;
	s/
		^\h*+\#
		(?<type>[%@\$\\#"])
		\{\h*+
		(?<label>[[:alpha:]_]\w*+:)?
		\h*+
		(?<expr>\V*[^\s])?\h*
		\}\h*+\r?$
	/ _gen_print($+{type}, $+{label}, $+{expr}) /gmex
		unless $nofilter;
	print STDERR if $debug;
};

1;

__END__

=encoding utf8

=head1 NAME

Debug::Filter::PrintExpr - Convert comment lines to debug print statements

=head1 SYNOPSIS

	use Debug::Filter::PrintExpr;

	my $s = 'a scalar';
	my @a = qw(this is an array);
	my %h = (key1 => 'value1', key2 => 'value2', '' => 'empty', undef => undef);
	my $ref = \%h;
	

	#${$s}
	#@{@a}
	#%{ %h }
	#${ calc: @a * 2 }
	#\{$ref}

This produces an output like:

	L13: $s = 'a scalar';
	L14: @a = ('this', 'is', 'an', 'array');
	L15: %h = ('' => 'empty', 'key1' => 'value1', 'key2' => 'value2', 'undef' => undef);
	calc: @a * 2 = 8;
	L17: dump($ref);
	     $_[0] = {
	               '' => 'empty',
	               'key1' => 'value1',
	               'key2' => 'value2',
	               'undef' => undef
	             };

=head1 DESCRIPTION

=head2 The Problem

Providing debug output often results in a couple of print statements that
display the value of some expression and some kind of description.
When the program development is finished, these statements must be
made conditional on some variable or turned into comments.

Often the contents of arrays or hashes need to be presented in a
readable way, leading to repeated lines of similar code.

C programmers use the preprocessor to solve this problem.
As Perl has it's own filter mechanism for preprocessing,
this leads to a similar solution in Perl.

=head2 A Solution

The L<Filter::Simple> module by Damian Conway provides a convenient way
of implementing Perl filters.

C<Debug::Filter::PrintExpr> makes use of L<Filter::Simple>
to transform specially formed comment lines into print statements
for various debugging purposes.
(Besides, there is L<Smart::Comments> from Damian, that does something
very similar but more advanced.)

Just by removing the "use" of C<Debug::Filter::PrintExpr> completely,
disabling it partially by

	no Debug::Filter::PrintExpr;

or making the usage conditional (e.g. on an environment variable)
by

	use if $ENV{DEBUG}, 'Debug::Filter::PrintExpr';

all these lines (or a part of them) lose their magic and remain
simple comments.

The comment lines to be transformed must follow this format:

# I<sigil> { [I<label>:] [I<expression>] }

or more formally must be matched by the following regexp:
	
 qr{
	^\h*\#
	(?<type>[%@\$\\"#])
	\{\h*
	(?<label>[[:alpha:]_]\w*:)?
	\h*
	(?<expr>\V+)?
	\}\h*$
 }x

where C<type> represents the sigil, C<label> an optional label and
C<expr> an optional expression.

If the label is omitted, it defaults to C<LI<n>:>, where n is the
line number in the program.

The sigil determines the evaluation context for the given expression
and the output format of the result:

=over 4

=item C<$>

The expression is evaluated in scalar context. Strings are printed
inside single quotes, integer and floating point numbers are
printed unquoted and dual valued variables are shown in the form
C<dualvar(I<numval>, 'I<stringval>')>.
Undefined values are represented by the unquoted string C<undef>.
Hash and array references are shown in their usual string representation
as e.g. C<ARRAY(0x19830d0)> or C<HASH(0xccba88)>.
Blessed references are shown by the class they are belong to as
C<< blessed(class) >>.

=item C<">

The expression is evaluated in scalar context as a string.

=item C<#>

The expression is evaluated in scalar context as a numeric value.

=item C<@>

The expression is evaluated in list context and the elements of the
list are printed like single scalars, separated by commas and gathered
in parentheses.

=item C<%>

The expression is evaluated as a list of key-value pairs
and is presented in the form 'key' => I<value>,... inside parentheses.
I<value> is formatted like a single scalar.

=item C<\>

The expression shall evaluate to a list of references.
These will be evaluated using L<Data::Dumper> and named
like parameters in a subroutine, i.e. C<$_[I<n>]>.

=back

The usage and difference between C<#${}>, C<#"{}> and C<##{}> is
best described by example:

	my $dt = DateTime->now;
	#${$dt}		# Ln: $dt = blessed(DateTime);
	#"{$dt}		# Ln: $dt = '2019-10-27T15:54:28';

	my $num = ' 42 ';
	#${$num}	# Ln: $num = ' 42 ';
	$num + 0;
	#${$num}	# Ln: $num = dualvar(42, ' 42 ');
	#"{$num}	# Ln: $num = ' 42 ';
	##{$num}	# Ln: $num = 42;


The forms #${}, #"{}, ##{} and #@{} may be used for any type of expression
and inside the #%{} form, arrays are permitted too.
With the varibles $s, @a and %h as defined above, it is possible
to use:
	
	#@{scalar_as_array: $s}
	#${array_as_scalar :@a}
	#@{hash_as_array: %h}

and produce these results:

	scalar_as_array: $s = ('this is a scalar');
	array_as_scalar: @a = 4;
	hash_as_array: %h = ('k1', 'v1', 'k2', 'v2');
	
Regular expressions may be evaluated too:

	#@{"a<b>c<d><e>f<g>h" =~ /\w*<(\w+)>/g}

gives:

	Ln: "a<b>c<d><e>f<g>h" =~ /\w*<(\w+)>/g = ('b', 'd', 'e', 'g');

If the expression is omitted, only the label will be printed.
The sigil C<$> should be used in this case.

Requirements for the expression are:

=over 4

=item *

It must be a valid Perl expression.

=item *

In case of the #%{}-form, it must evaluate to a list of pairs, e.g.
a hash.

=back

A PrintExpr will be resolved to a block and therefore may be located
anywhere in the program where a block is valid. 
Do not put it in a place, where a block is required (e.g. after a
conditional) as this would break the code when running without the
filter.

As a code snippet of the form C<{label: expr}> is a valid perl
expression and the generated code will result in a 
braced expression, a simple consistency check can be done by removing
hash and sigil from the PrintExpr line:
The resulting code must still be valid and should only emit a warning
about a useless use of something in void context.

=head2 Usage

The C<use> statement for C<Debug::Filter::PrintExpr> may contain
arguments as described in L<Exporter::Tiny::Manual::Importing>.
Importable functions are C<isnumeric> and C<isstring> as well
as the import tag C<:all> for both of them.

The (optional) global options hash may contain
these module specific entries:

=over 4

=item debug => 1

This option causes the resulting source code after comment
transformation to be written to C<STDERR>.
This option may also be specified as C<-debug> in the
C<use> statement.

=item nofilter => 1

This options disables source code filtering if only the import
of functions is desired.
This option may also be specified as C<-nofilter> in the
C<use> statement.

=back

=head2 Functions

=over

=item C<isstring(I<$var>)>

This function returns true if the "string slot" of I<$var> has a value.
This is the case when a string value was assigned to the variable,
the variable has been used (recently) in a string context
or when the variable is dual-valued.

It will return false for undefined variables, references and
variables with a numeric value that have never been used in a
string context.

=item C<isnumeric(I<$var>)>

This function returns true if the "numeric slot" if I<$var> has a
value.
This is the case when a numeric value (integer or floating point) was
assigned to the variable, the variable has been used (recently) in a
numeric context or when the variable is dual-valued.

It will return false for undefined variables, references and variables
with a string value that have never been used in numeric context.

=back

=head2 Variables

=over 4

=item C<$Debug::Filter::PrintExpr::handle>

The filehandle that is referenced by this variable is used for
printing the generated output.
The default is STDERR and may be changed by the caller.

=back


=head1 SEE ALSO

Damian Conway's module L<Smart::Comments> provides something similar
and more advanced.

While L<Smart::Comments> has lots of features for visualizing the
program flow, this module focuses on data representation.
The main requirements for this module were:

=over

=item *

Always print the source line number or a user provide label.

=item *

Always print the literal expression along with its evaluation.

=item *

Give a defined context where the expression is evaluated.
Especially provide scalar and list context or perform an iteration
over the key-value pairs of a hash.
The usage of L<Data::Dumper> was adopted later from Damian's
implementation.

=item *
	
Trailing whitespace in values should be clearly visible.

=item *

Distinguish between the numeric and string value of a variable.

=item *

undefined values should be clearly distinguishable from empty values.

=back

The first three requirements are not met by L<Smart::Comments> as there is
an extra effort needed to display a line number,
the display of a label and the literal expression are mutual exclusive
and a specific context is not enforced by the module.

All in all, the module presented here is not much more than a
programming exercise.

Importing the functions C<isstring> and C<isnumeric> is done
by L<Exporter::Tiny>.
For extended options see L<Exporter::Tiny::Manual::Importing>.

Other related modules: L<Scalar::Util>, L<Data::Dumper>

=head1 AUTHOR

Jörg Sommrey

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018-2020, Jörg Sommrey. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
