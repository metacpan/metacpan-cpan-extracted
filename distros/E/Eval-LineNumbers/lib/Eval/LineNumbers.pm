
package Eval::LineNumbers;

use warnings;
use strict;

use Exporter 5.57 'import';
our @EXPORT_OK = qw(eval_line_numbers);

our $VERSION = 0.34;

sub eval_line_numbers
{
	my(undef, $file, $line) = caller(
		# Optional first arg is the caller level
		$_[0] =~ /^[0-9]+$/ ? (shift) : 0
	);
	$line++;
	return join('', qq{#line $line "$file"\n}, @_)
}
1;

__END__

=head1 NAME

Eval::LineNumbers - Add line numbers to heredoc blocks that contain perl source code

=head1 SYNOPSIS

 use Eval::LineNumbers qw(eval_line_numbes);

 eval eval_line_numbers(<<END_HEREIS);
   code
 END_HEREIS

 eval eval_line_numbers($caller_level, $code)

=head1 DESCRIPTION

Add a C<#line "this-file" 392> comment to heredoc/hereis text that is going
to be eval'ed so that error messages will point back to the right place.

Please note: when you embed C<\n> in your code, it gets expanded in
double-quote hereis documents so it will mess up your line numbering.
Use C<\\n> instead when you can.

=head2 Caller Level Example

The second form of eval_line_numbers where a caller-level is provided
is for the situation where the code is generated in one place and 
eval'ed in another place.  The caller level should be the number of
stack levels between where the heredoc was created and where it is
eval'ed.

 sub example {
   return <<END_HEREIS
     code
END_HEREIS
 }

 eval eval_line_numbers(1, example())

=head1 LICENSE

Copyright (C) 2009 David Muir Sharnoff.
Copyright (C) 2013 Google, Inc.

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

