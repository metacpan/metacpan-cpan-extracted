package Debug::Filter::PrintExpr;

use strict;
use warnings;
 
use Filter::Simple;
use Data::Dumper;

our
$VERSION = '0.02';

# variable is exposed and my be overwritten by caller
our $handle = *STDERR;

# generate a prefix containing line number or custom label
sub genprefix {
	my ($self, $label, $line, $expr, $value) = @_;
	print $handle $label ? $label : "line $line:";
	print $handle " $expr = " if $expr;
}

# print out an expression in scalar context
sub valuescalar {
	my $value = shift;
	print $handle (defined($value) ?
		(ref($value) ? $value : ("'", $value, "'")) :
		'undef');
}

# print out an expression in list context
sub valuearray {
	my (@value) = @_;
	print $handle join(', ', map({defined($_) ? "'$_'" : 'undef'} @value));
}

# print out an key-value pair, prefixed by a seperator
sub valuehash {
	our $sep;
	local *sep = \$_[0];
	shift;
	my ($key, $value) = @_;
	print $handle $sep || '',
		"'$key' => ", defined($value) ?  "'$value'" : 'undef';
	$sep = ', ';
}

# print opening before list/hash data
sub genopen {
	print $handle '(';
}

# print closing after list/hash data
sub genclose {
	print $handle ");\n";
}

# process a complete scalar debug statement
sub printscalar {
	my ($self, $label, $line, $expr, $value) = @_;
	genprefix @_;
	valuescalar($value) if $value;
	print $handle ';' if $value;
	print $handle "\n";
}

# process a complete array debug statement
sub printarray {
	my ($self, $label, $line, $expr, @value) = @_;
	genprefix @_;
	genopen;
	valuearray @value;
	genclose;
}

# start a hash debug statement
sub printhashopen {
	my ($self, $label, $line, $expr) = @_;
	genprefix @_;
	genopen;
}

# process a single iteration of a key-value pair
sub printhashitem {
	my ($sep, $key, $value) = @_;
	valuehash @_;
}

# end a hash debug statement
sub printhashclose {
	genclose;
}

# process a complete reference debug statement
sub printref {
	my ($self, $label, $line, $expr, @value) = @_;
	print $handle $label ? $label : "line $line:", " ";
	my $d = Data::Dumper->new([@value]);
	my $dump =  $d->Dump;
	if (scalar(@value) <= 1) {
		$dump =~ s/^\$VAR1/$expr/;
	} else {
		$dump =~ s/^\$VAR(\d+)/"($expr)[" . ($1 - 1) . "]"/meg;
	}
	print $handle "\n", $dump;
}

# process a debug statement
sub gen_print {
	my ($self, $type, $label, $expr) = @_;
	$label ||= '';
	if ($type eq '$') {
		my $print = $self . "::printscalar";
		$expr ||= '';
		return qq[{$print("$self", "$label", __LINE__, q{$expr}, scalar(($expr)));}];
	} elsif ($type eq '@') {
		my $print = $self . "::printarray";
		return qq[{$print("$self", "$label", __LINE__, q{$expr}, $expr);}];
	} elsif ($type eq '%') {
		my $printopen = $self . '::printhashopen';
		my $printitem = $self . '::printhashitem';
		my $printclose = $self . '::printhashclose';
		my $sep = '$' . $self . '::sep';
		my $pair = '@' . $self . '::pair';
		my $stmt = qq[{local ($sep, $pair); ];
		$stmt .= qq[$printopen("$self", "$label", __LINE__, q{$expr}); ];
		$stmt .= qq[$printitem($sep, $pair) ];
		$stmt .= qq[while $pair = each($expr); ];
		$stmt .= qq[$printclose;}];
		return $stmt;
	} elsif ($type eq '\\') {
		my $print = $self . "::printref";
		return qq[{$print("$self", "$label", __LINE__, q{$expr}, $expr);}];
	} else {
		return '# type unknown';
	}
}

# source code processing happens here
FILTER {
	my ($self, %opt) = @_;
	s/
		^\h*\#
		(?<type>[%@\$\\])
		\{\h*
		(?<label>[[:alpha:]_]\w*:)?
		\h*
		(?<expr>\V+)?
		\}\h*\r?$
	/ gen_print($self, $+{type}, $+{label}, $+{expr}) /gmex;
	print STDERR if $opt{-debug};
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
	my %h = (key1 => 'value1', key2 => 'value2');
	my $ref = \%h;

	#${$s}
	#@{@a}
	#%{%h}
	#${ calc: @a * 2 }
	#\{$ref}

This program produces an output like this:

	line 13: $s = 'a scalar';
	line 14: @a = ('this', 'is', 'an', 'array');
	line 15: %h = ('key1' => 'value1', 'key2' => 'value2');
	calc: @a * 2  = '8';
	line 17:
	$ref = {
          'undef' => undef,
          'a' => 1,
          '' => 'empty',
          'b' => 2
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

The C<Filter::Simple> module by Damian Conway provides a convenient way
of implementing Perl filters.

C<Debug::Filter::PrintExpr> makes use of C<Filter::Simple>
to transform specially formed comment lines into print statements
for various debugging purposes.
(Besides, there is C<Smart::Comments> from Damian, that does something
very similar but more advanced.)

Just by removing the "use" of Debug::Filter::PrintExpr completely
or disabling it partially by

	no Debug::Filter::PrintExpr;

all these lines (or a part of them) lose their magic and remain
simple comments.

The comment lines to be transformed must follow this format:

# I<sigil> { [I<label>:] [I<expression>] }

or more formally must be matched by the following regexp:
	
 qr{
	^\h*\#
	(?<type>[%@\$\\])
	\{\h*
	(?<label>[[:alpha:]_]\w*:)?
	\h*
	(?<expr>\V+)?
	\}\h*$
 }x

where C<type> represents the sigil, C<label> an optional label and
C<expr> an optional expression.

If the label is omitted, it defaults to C<line nnn:>, where nnn is the
line number in the program.

The sigil determines the evaluation context for the given expression
and the output format of the result:

=over 4

=item $

The expression is evaluated in scalar context and printed inside
single quotes;

=item @

The expression is evaluated in list context and the elements of the
list are printed inside single quotes, separated by commas and gathered
in parentheses.

=item %

The expression is used as argument in a while-each loop and the output
consists of pairs of the form 'key' => 'value' inside parentheses.

=item \\

The expression shall be a list of references.
These will be evaluated using C<Data::Dumper>.

=back

Undefined values are presented by the (unquoted) String C<undef>.
References are presented unquoted in their native representation
e.g. as ARRAY(0x19830d0).

The forms #${} and #@{} may be used for any type of expression
and inside the #%{} form, arrays are permitted too.
With the varibles $s, @a and %h as defined above, it is possible
to use:
	
	#@{scalar_as_array: $s}
	#${array_as_scalar :@a}
	#@{hash_as_array: %h}
	#%{array_as_hash: @a}

and produce these results:

	scalar_as_array: $s = ('this is a scalar');
	array_as_scalar: @a = '4';
	hash_as_array: %h = ('k1', 'v1', 'k2', 'v2');
	array_as_hash: @a = ('0' => 'this', '1' => 'is', '2' => 'an', '3' => 'array');
	
Regular expressions may be evaluated too:

	#@{"a<b>c<d><e>f<g>h" =~ /\w*<(\w+)>/g}

gives:

	line nn: "a<b>c<d><e>f<g>h" =~ /\w*<(\w+)>/g = ('b', 'd', 'e', 'g');

If the expression is omitted, only the label will be printed.
The sigil C<$> should be used in this case.

Requirements for the expression are:

=over 4

=item *

It must be a valid Perl expression.

=item *

In case of the #%{}-form, it must be a valid argument to the
each() builtin function, i.e. it should resolve to an array or hash.

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

=head2 Arguments to Debug::Filter::PrintExpr

The use-statement for C<Debug::Filter::PrintExpr> may contain
a hash of options:

	use Debug::Filter::PrintExpr (-debug => 1);

=over 4

=item -debug

When this option is set to true, the resulting source code after
comment transformation is written to the default output file handle.
Only the parts of source where Debug::Filter::PrintExpr is in effect
are printed out.

=back

=head2 Variables

=over 4

=item C<$Debug::Filter::PrintExpr::handle>

The filehandle that is referenced by this variable is used for
printing the generated output.
The default is STDERR and may be changed by the caller.

=back


=head1 SEE ALSO

Damian Conway's module C<Smart::Comments> provides something similar
and more advanced.

While C<Smart::Comments> has lots of features for visualizing the
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
over a while-each-loop.
The usage of C<Data::Dumper> was adopted later from Damian's
implementation.

=item *
	
Trailing whitespace in values should be clearly visible.

=item *

undefined values should be clearly distinguishable from empty values.

=back

The first three requirements are not met by C<Smart::Comments> as there is
an extra efford needed to display a line number,
the display of a label and the literal expression are mutual exclusive
and a specific context is not enforced by the module.

All in all, the module presented here is not much more than a
programming exercise.

=head1 AUTHOR

Jörg Sommrey

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018-2019, Jörg Sommrey. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut
