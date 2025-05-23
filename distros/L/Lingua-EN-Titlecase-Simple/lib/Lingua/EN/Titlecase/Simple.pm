use 5.008001; use strict; use warnings; use utf8;

package Lingua::EN::Titlecase::Simple;

our $VERSION = '1.015';

our @SMALL_WORD
	= qw/ (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? /;

my $apos = q/ (?: ['’] [[:lower:]]* )? /;

sub titlecase {
	my @str = @_ or return;

	my $small_re = join '|', @SMALL_WORD;

	for ( @str ) {
		s{\A\s+}{}, s{\s+\z}{};

		$_ = lc $_ if not /[[:lower:]]/;

		s{
			\b (_*) (?:
				( (?<=[ ][/\\]) [[:alpha:]]+ [-_[:alpha:]/\\]+ |   # file path or
				[-_[:alpha:]]+ [@.:] [-_[:alpha:]@.:/]+ $apos |    # URL, domain, or email or
				[0-9] [0-9,._ ]+ $apos )                           # a numeric literal
				|
				( (?i: $small_re ) $apos )                         # or small word (case-insensitive)
				|
				( [[:alpha:]] [[:lower:]'’()\[\]{}]* $apos )       # or word w/o internal caps
				|
				( [[:alpha:]] [[:alpha:]'’()\[\]{}]* $apos )       # or some other word
			) (_*) \b
		}{
			$1 . (
			defined $2 ? $2         # preserve URL, domain, or email
			: defined $3 ? "\L$3"     # lowercase small word
			: defined $4 ? "\u\L$4"   # capitalize word w/o internal caps
			: $5                      # preserve other kinds of word
			) . $6
		}xeg;


		# Exceptions for small words: capitalize at start and end of title
		s{
			(  \A [[:punct:]]*         # start of title...
			|  [:.;?!][ ]+             # or of subsentence...
			|  [ ]['"“‘(\[][ ]*     )  # or of inserted subphrase...
			( $small_re ) \b           # ... followed by small word
		}{$1\u\L$2}xig;

		s{
			\b ( $small_re )      # small word...
			(?= [[:punct:]]* \Z   # ... at the end of the title...
			|   ['"’”)\]] [ ] )   # ... or of an inserted subphrase?
		}{\u\L$1}xig;

		# Exceptions for small words in hyphenated compound words
		## e.g. "in-flight" -> In-Flight
		s{
			\b
			(?<! -)					# Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (in-flight)
			( $small_re )
			(?= -[[:alpha:]]+)		# lookahead for "-someword"
		}{\u\L$1}xig;

		## # e.g. "Stand-in" -> "Stand-In" (Stand is already capped at this point)
		s{
			\b
			(?<!…)					# Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (stand-in)
			( [[:alpha:]]+- )		# $1 = first word and hyphen, should already be properly capped
			( $small_re )           # ... followed by small word
			(?!	- )					# Negative lookahead for another '-'
		}{$1\u$2}xig;
	}

	wantarray ? @str : ( @str > 1 ) ? \@str : $str[0];
}

sub import {
	my ( $class, $pkg, $file, $line ) = ( shift, caller );
	die "Unknown symbol: $_ at $file line $line.\n" for grep 'titlecase' ne $_, @_;
	no strict 'refs';
	*{ $pkg . '::titlecase' } = \&titlecase if @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::EN::Titlecase::Simple - John Gruber's headline capitalization script

=head1 SYNOPSIS

 use Lingua::EN::Titlecase::Simple 'titlecase';

 print titlecase 'Small word at end is nothing to be afraid of';
 # output:        Small Word at End Is Nothing to Be Afraid Of

 print titlecase 'IF IT’S ALL CAPS, FIX IT';
 # output:        If It’s All Caps, Fix It

=head1 DESCRIPTION

This module capitalizes English text suitably for use as a headline, based on
traditional editorial rules from I<The New York Times Manual of Style>.

=head1 INTERFACE

There are no default exports.

=head2 C<titlecase>

Takes one or more strings as arguments, each representing one headline to capitalize.

When given a single string, returns a scalar.
When given several strings, returns a list in list context, but an arrayref in scalar context.
When given nothing, returns nothing in list context or undef in scalar context.

This function can be exported on request.

Note that the arrayref return is problematic because it depends on the number
of arguments. If you have a variable number of arguments to pass, and that
number can sometimes be less than 2, you will sometimes get a plain scalar or
an undefined value instead of the arrayref you expected. Passing multiple
strings in scalar context is therefore L<discouraged|perlpolicy/discouraged>.

=head2 C<@SMALL_WORD>

Contains the list of words to avoid capitalizing.

=head1 SEE ALSO

L<Lingua::EN::Titlecase> provides a much more heavyweight, modular solution
for the same problem. If you seriously disagree with the style rules in this
module somewhere, you may be happier with that one.

=head1 AUTHOR

John Gruber <http://daringfireball.net/2008/05/title_case>

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by John Gruber, Aristotle Pagaltzis.

This is free software, licensed under:

  The MIT (X11) License

=cut
