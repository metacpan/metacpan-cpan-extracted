use 5.008001; use strict; use warnings; use utf8;

package Lingua::EN::Titlecase::Simple;

our $VERSION = '1.004';

our @SMALL_WORD
	= qw/ (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? /;

my $apos = q/ (?: ['’] [[:lower:]]* )? /;

sub titlecase {
	my @str = @_ or return;

	for ( @str ) {
		s{\A\s+}{}, s{\s+\z}{};

		$_ = lc $_ unless /[[:lower:]]/;

		s{
			\b (_*) (?:
				( (?<=[ ][/\\]) [[:alpha:]]+ [-_[:alpha:]/\\]+ |   # file path or
				[-_[:alpha:]]+ [@.:] [-_[:alpha:]@.:/]+ $apos |    # URL, domain, or email or
				[0-9] [0-9,._ ]+ $apos )                           # a numeric literal
				|
				( (?i) ${\join '|', @SMALL_WORD} $apos )           # or small word (case-insensitive)
				|
				( [[:alpha:]] [[:lower:]'’()\[\]{}]* $apos )       # or word w/o internal caps
				|
				( [[:alpha:]] [[:alpha:]'’()\[\]{}]* $apos )       # or some other word
			) (?= _* \b )
		}{
			$1 .
			( defined $2 ? $2         # preserve URL, domain, or email
			: defined $3 ? lc $3      # lowercase small word
			: defined $4 ? ucfirst $4 # capitalize lower-case word
			: $5 )                    # preserve other kinds of word
		}exgo;

		# exceptions for small words: capitalize at start and end of title
		s{
			( \A [[:punct:]]*          # start of title...
			|  [:.;?!][ ]+             # or of subsentence...
			|  [ ]['"“‘(\[][ ]*     )  # or of inserted subphrase...
			( ${\join '|', @SMALL_WORD} ) \b  # ... followed by small word
		}{$1\u\L$2}xigo;

		s{
			\b ( ${\join '|', @SMALL_WORD} )  # small word...
			(?= [[:punct:]]* \Z   # ... at the end of the title...
			|   ['"’”)\]] [ ] )   # ... or of an inserted subphrase?
		}{\u\L$1}xigo;
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
It may be changed before the first call to the C<titlecase> function.
Any changes after that will have no effect.

=head1 SEE ALSO

L<Lingua::EN::Titlecase> provides a much more heavyweight, modular solution
for the same problem. If you seriously disagree with the style rules in this
module somewhere, you may be happier with that one.

=head1 AUTHORS

=over 4

=item *

John Gruber <http://daringfireball.net/2008/05/title_case>

=item *

Aristotle Pagaltzis <pagaltzis@gmx.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by John Gruber, Aristotle Pagaltzis.

This is free software, licensed under:

  The MIT (X11) License

=cut
