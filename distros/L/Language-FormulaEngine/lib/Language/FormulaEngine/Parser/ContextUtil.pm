package Language::FormulaEngine::Parser::ContextUtil;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK= qw( calc_text_coordinates format_context_string format_context_multiline );

# ABSTRACT: utility methods for parsers
our $VERSION = '0.07'; # VERSION


sub calc_text_coordinates {
	my ($buf, $pos, $line, $col)= @_;
	$line ||= 0;
	$col ||= 0;
	# If there are any newlines from the start of the buffer to the given position...
	my $line_end= rindex($buf, "\n", $pos-1);
	if ($line_end >= 0) {
		# ...then add up the number of newlines and re-calculate the column
		$line+= (substr($buf, 0, $line_end+1) =~ /\n/);
		$col= $pos - ($line_end+1);
	}
	else {
		$col += $pos;
	}
	return ($line, $col);
}


sub format_context_string {
	my ($buf, $start, $limit, $line, $col)= @_;
	# If we don't have a buffer, there's nothing to show, so print "end of input".
	defined $buf and length $buf > $start
		or return '(end of input)';
	my $context= substr($buf, $start, 20);
	$context =~ s/\n.*//s; # remove subsequent lines
	($line, $col)= calc_text_coordinates($buf, $start, $line, $col);
	return sprintf '"%s" at line %d char %d', $context, $line+1, $col+1;
}


sub format_context_multiline {
	my ($self, $buf, $start, $limit, %args)= @_;
	my ($prefix, $token, $suffix)= ('','','');
	my $line= $args{buffer_line} || 0;
	my $col=  $args{buffer_col} || 0;
	my $max_width= $args{max_width} || 78;
	my $min_token= $args{min_token} || 30;
	
	# Make sure both start and limit are defined, defaulting to equal
	$start ||= $limit || 0;
	$limit ||= $start;
	# If they are identical, move limit over one
	$limit++ if $start == $limit;
	# If we don't have a buffer, there's nothing to show, so print "end of input".
	if (!length($buf)) {
		$suffix= '(end of input)';
	}
	else {
		$prefix= substr($buf, 0, $start);
		$token=  substr($buf, $start, $limit-$start);
		$suffix= substr($buf, $limit);
	}
	
	# Truncate prefix and suffix at line breaks
	$prefix =~ s/.*\n//s;
	$suffix =~ s/\n.*//s;
	# Limit lengths of prefix and suffix and token
	if (length($prefix) + length($token) > $max_width) {
		$min_token= min(length($token), $min_token);
		# truncate prefix, or token, or both
		if (length($prefix) > $max_width - $min_token) {
			substr($prefix, 0, -($max_width - $min_token))= '';
		}
		if (length($prefix) + length($token) > $max_width) {
			substr($token, -($max_width - length($prefix) - length($token)))= ''; 
		}
	}
	if (length($prefix) + length($token) + length($suffix) > $max_width) {
		substr($suffix, -($max_width - length($prefix) - length($token)))= '';
	}
	($line, $col)= calc_text_coordinates($buf, $start, $line, $col);
	return sprintf "%s%s%s\n%s%s\n (line %d char %d)\n",
		$prefix, $token, $suffix,
		' ' x length($prefix), '^' x (length($token) || 1),
		$line+1, $col+1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Parser::ContextUtil - utility methods for parsers

=head1 VERSION

version 0.07

=head1 EXPORTED FUNCTIONS

=head2 calc_text_coordinates

  my ($line, $col)= calc_text_coordinates( $buffer, $pos );
  my ($line, $col)= calc_text_coordinates( $buffer, $pos, $buffer_line, $buffer_col );

Returns the 0-based line number and character number of an offset within
a buffer.  The line/column of the start of the buffer can be given as
additional arguments.

=head2 format_context_string

  my $message= format_context_string( $buffer, $token_start, $token_limit, $buffer_line, $buffer_col );
  # "'blah blah' on line 15, char 12"

Returns a single-string view of where the token occurs in the buffer.
This is useful for single-line "die" messages.

=head2 format_context_multiline

  my $tty_text= format_context_multiline( $buffer, $token_start, $token_limit, \%args );
  
  #   "blah blah blah token blah blah\n"
  #  ."               ^^^^^\n"
  #  ." (line 15, char 16)\n";

More advanced view of the input string, printed on three lines with the second
marking the token within its context and third listing the line/column.
This is only useful with a fixed-width font in a multi-line context.

This method also supports various options for formatting.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
