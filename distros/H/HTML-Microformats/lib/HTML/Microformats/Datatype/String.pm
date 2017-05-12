=head1 NAME

HTML::Microformats::Datatype::String - text in a particular language

=head1 SYNOPSIS

 my $string = HTML::Microformats::Datatype::String
                ->new('Bonjour', 'fr');
 print "$string\n";

=cut

package HTML::Microformats::Datatype::String;

use strict qw(subs vars); no warnings;
use overload '""'=>\&to_string, '.'=>\&concat, 'cmp'=>\&compare;

use base qw(Exporter HTML::Microformats::Datatype);
our @EXPORT    = qw(ms isms);
our @EXPORT_OK = qw(ms isms concat compare);

use Encode;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Datatype::String::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Datatype::String::VERSION   = '0.105';
}

=head1 DESCRIPTION

=head2 Constructor

=over 4

=item C<< $str = HTML::Microformats::Datatype::String->new($text, [$lang]) >>

Creates a new HTML::Microformats::Datatype::String object.

=back

=cut

sub new
{
	my $class = shift;
	my $rv    = {};
	
	$rv->{'string'} = shift;
	$rv->{'lang'}   = shift;
	
	bless $rv, $class;
}

=head2 Public Methods

=over 4

=item C<< $str->lang >>

Return the language code.

=cut

sub lang
{
	my $this = shift;
	return $this->{'lang'};
}

=item C<< $str->to_string >>

Return a plain (scalar) string.

=back

=cut

sub to_string
{
	my $this = shift;
	return $this->{'string'};
}

sub TO_JSON
{
	my $this = shift;
	return $this->{'string'};
}

=head2 Functions

=over 4

=item C<< $str = ms($text, [$element]) >>

Construct a new HTML::Microformats::Datatype::String object from a
scalar, plus XML::LibXML::Element. If $element is undef, then returns
the plain (scalar) string itself.

This function is exported by default.

(Note: the name 'ms' originally stood for 'Magic String'.)

=cut

sub ms
{
	my ($rv, $dom);

	$rv->{string} = shift;
	$dom          = shift || return $rv->{string};
	
	$rv->{lang}   = $dom->getAttribute('data-cpan-html-microformats-lang');
	$rv->{xpath}  = $dom->getAttribute('data-cpan-html-microformats-nodepath');
	$rv->{xml}    = $dom->toString;
	$rv->{dom}    = $dom;
	
	bless $rv, __PACKAGE__;
}

=item C<< isms($str) >>

Returns true iff $str is blessed as a HTML::Microformats::Datatype::String
object.

This function is exported by default.

=cut

sub isms
{
	my $this = shift;
	return (__PACKAGE__ eq ref $this);
}

=item C<< $c = concat($a, $b, [$reverse]) >>

Concatenates two strings.

If the language of string $b is null or the same as $a, then the
resultant string has the same language as $a. Otherwise the result
has no language.

If $reverse is true, then the strings are concatenated with $b
preceding $a.

This function is not exported by default.

Can also be used as a method:

 $c = $a->concat($b);

=cut

sub concat
{
	my $a   = shift;
	my $b   = shift;
	my $rev = shift;
	
	if ($rev)
	{
		($a, $b) = ($b, $a);
	}

	unless (ref $a)
		{ $a = { string => $a }; }
	unless (ref $b)
		{ $b = { string => $b }; }
	
	my $rv = {};
	$rv->{string} = $a->{string}.$b->{string};

	if (!$b->{lang} || (lc($a->{lang}) eq lc($b->{lang})))
	{
		$rv->{lang} = $a->{lang};
	}
	
	bless $rv, __PACKAGE__;
}

=item C<< compare($a, $b) >>

Compares two strings alphabetically. Language is ignored.

Return values are as per 'cmp' (see L<perlfunc>).

This function is not exported by default.

Can also be used as a method:

 $a->compare($b);

=back

=cut

sub compare
{
	my $a = shift;
	my $b = shift;
	return "$a" cmp "$b";
}

1;

__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Datatype>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
