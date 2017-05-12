package MDOM::Token::Whitespace;

=pod

=head1 NAME

MDOM::Token::Whitespace - Tokens representing ordinary white space

=head1 INHERITANCE

  MDOM::Token::Whitespace
  isa MDOM::Token
      isa MDOM::Element

=head1 DESCRIPTION

As a full "round-trip" parser, MDOM records every last byte in a
file and ensure that it is included in the L<MDOM::Document> object.

This even includes whitespace. In fact, Perl documents are seen
as "floating in a sea of whitespace", and thus any document will
contain vast quantities of C<MDOM::Token::Whitespace> objects.

For the most part, you shouldn't notice them. Or at least, you
shouldn't B<have> to notice them.

This means doing things like consistently using the "S for significant"
series of L<MDOM::Node> and L<MDOM::Element> methods to do things.

If you want the nth child element, you should be using C<schild> rather
than C<child>, and likewise C<snext_sibling>, C<sprevious_sibling>, and
so on and so forth.

=head1 METHODS

Again, for the most part you should really B<not> need to do anything
very significant with whitespace.

But there are a couple of convenience methods provided, beyond those
provided by the parent L<MDOM::Token> and L<MDOM::Element> classes.

=cut

use strict;
use base 'MDOM::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.008';
}

=pod

=head2 null

Because MDOM sees documents as sitting on a sort of substrate made of
whitespace, there are a couple of corner cases that get particularly
nasty if they don't find whitespace in certain places.

Imagine walking down the beach to go into the ocean, and then quite
unexpectedly falling off the side of the planet. Well it's somewhat
equivalent to that, including the whole screaming death bit.

The C<null> method is a convenience provided to get some internals
out of some of these corner cases.

Specifically it create a whitespace token that represents nothing,
or at least the null string C<''>. It's a handy way to have some
"whitespace" right where you need it, without having to have any
actual characters.

=cut

sub null { $_[0]->new('') }

### XS -> MDOM/XS.xs:_MDOM_Token_Whitespace__significant 0.900+
sub significant { '' }

=pod

=head2 tidy

C<tidy> is a convenience method for removing unneeded whitespace.

Specifically, it removes any whitespace from the end of a line.

Note that this B<doesn't> include POD, where you may well need
to keep certain types of whitespace. The entire POD chunk lives
in its own L<MDOM::Token::Pod> object.

=cut

sub tidy {
	my $self = shift;
	$self->{content} =~ s/^\s+?(?>\n)//;
	1;
}

1;

=pod

=head1 SUPPORT

See the L<support section|MDOM/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
