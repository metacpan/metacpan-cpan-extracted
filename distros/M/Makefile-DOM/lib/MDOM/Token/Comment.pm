package MDOM::Token::Comment;

=pod

=head1 NAME

MDOM::Token::Comment - A comment in Makefile source code

=head1 INHERITANCE

  MDOM::Token::Comment
  isa MDOM::Token
      isa MDOM::Element

=head1 SYNOPSIS

  # This is a MDOM::Token::Comment

  foo: bar # So is this one
  	echo 'hello'

=head1 DESCRIPTION

In MDOM, comments are represented by C<MDOM::Token::Comment> objects.

These come in two flavours, line comment and inline comments.

A C<line comment> is a comment that stands on its own line. These comments
hold their own newline and whitespace (both leading and trailing) as part
of the one C<MDOM::Token::Comment> object.

An inline comment is a comment that appears after some code, and
continues to the end of the line. This does B<not> include whitespace,
and the terminating newlines is considered a separate
L<MDOM::Token::Whitespace> token.

This is largely a convenience, simplifying a lot of normal code relating
to the common things people do with comments.

Most commonly, it means when you C<prune> or C<delete> a comment, a line
comment disappears taking the entire line with it, and an inline comment
is removed from the inside of the line, allowing the newline to drop
back onto the end of the code, as you would expect.

It also means you can move comments around in blocks much more easily.

For now, this is a suitably handy way to do things. However, I do reserve
the right to change my mind on this one if it gets dangerously
anachronistic somewhere down the line.

=head1 METHODS

Only very limited methods are available, beyond those provided by our
parent L<MDOM::Token> and L<MDOM::Element> classes.

=cut

use strict;
use base 'MDOM::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.008';
}

### XS -> MDOM/XS.xs:_MDOM_Token_Comment__significant 0.900+
sub significant { '' }

=pod

=head2 line

The C<line> accessor returns true if the C<MDOM::Token::Comment> is a
line comment, or false if it is an inline comment.

=cut

sub line {
	# Entire line comments have a newline at the end
	$_[0]->{content} =~ /\n$/ ? 1 : 0;
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
