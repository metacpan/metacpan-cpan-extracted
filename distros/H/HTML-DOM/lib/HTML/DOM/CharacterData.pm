package HTML::DOM::CharacterData;

# This contains those methods that are shared both by comments and  text
# nodes.

use warnings;
use strict;

use HTML::DOM::Exception qw'INDEX_SIZE_ERR';
use Scalar::Util qw'blessed weaken';

require HTML::DOM::Node;

our @ISA = 'HTML::DOM::Node';
our $VERSION = '0.058';


sub   surrogify($);
sub desurrogify($);


# ~comment and ~text pseudo-elements (see HTML::Element) store the
# character data in the 'text' attribute.
sub data {
	my $old = (my $self = shift)->attr('text');
	if(@_) {
		$self->attr(text => my $strung = "$_[0]");
		$self->_modified($old,$strung);
	}
	$old
}

sub length {
	length $_[0]->attr('text');
}

sub length16 {
	CORE::length surrogify $_[0]->attr('text');
}

sub substringData { # obj, offset, length
	# Throwing exceptions in these cases is really dumb, but what can I
	# do? I'm trying to follow standards.
	my($self,$off,$len) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'substringData cannot take a negative offset')
		if $off <0;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'substringData cannot take a negative substring length')
		if $len && $len <0;
	my $text = $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "substringData: $off is greater than the length of the text")
		if $off > CORE::length $text;
	defined $len ? substr( $text, $off, $len) : substr $text, $off, ;
}

sub substringData16 { # obj, offset, length
	my($self,$off,$len) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'substringData cannot take a negative offset')
		if $off <0;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'substringData cannot take a negative substring length')
		if $len && $len<0;
	my $text = surrogify $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "substringData: $off is greater than the length of the text")
		if $off > CORE::length $text;
	desurrogify defined $len
		? substr($text, $off, $len)
		: substr $text, $off, ;
}

sub appendData {
	my $old = $_[0]->attr(text => my $new = $_[0]->attr('text').$_[1]);
	$_[0]->_modified($old, $new);
	return # nothing
}

sub insertData { # obj, offset, string to insert
	my ($self,$off,$insert) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'insertData cannot take a negative offset')
		if $off <0;
	my $text = $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "insertData: $off is greater than the length of the text")
		if $off > CORE::length $text;
	substr($text, $off, 0) = $insert;	
	my $old = $self->attr(text => $text);
	$self->_modified($old,$text);
	return # nothing
}

sub insertData16 { # obj, offset, string to insert
	my ($self,$off,$insert) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'insertData cannot take a negative offset')
		if $off <0;
	my $text = surrogify $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "insertData: $off is greater than the length of the text")
		if $off > CORE::length $text;
	substr($text, $off, 0) = $insert;	
	my $old = $self->attr(text => desurrogify $text);
	$self->_modified($old,$text);
	return # nothing
}

sub deleteData { # obj, offset, length
	my ($self,$off,$len) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'deleteData cannot take a negative offset')
		if $off <0;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'deleteData cannot take a negative substring length')
		if $len && $len <0;
	my $text = $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "deleteData: $off is greater than the length of the text")
		if $off > CORE::length $text; 
	no warnings; # Silence nonsensical warnings
	undef(defined $len
		? substr( $text, $off, $len)
		: substr $text, $off, );	
	my $old = $_[0]->attr(text => $text);
	$self->_modified($old,$text);
	return # nothing
}

sub deleteData16 { # obj, offset, length
	my ($self,$off,$len) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'deleteData cannot take a negative offset')
		if $off <0;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'deleteData cannot take a negative substring length')
		if $len && $len <0;
	my $text = surrogify $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "deleteData: $off is greater than the length of the text")
		if $off > CORE::length $text;
	no warnings; # Silence nonsensical warnings
	undef( defined $len
		? substr( $text, $off, $len)
		: substr $text, $off, );
	my $old = $self->attr(text => desurrogify $text);
	$self->_modified($old,$text);
	return # nothing
}

sub replaceData { # obj, offset, length, replacement
	my ($self,$off,$len,$subst) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'replaceData cannot take a negative offset')
		if $off <0;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'replaceData cannot take a negative substring length')
		if $len <0;
	my $text = $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "replaceData: $off is greater than the length of the text")
		if $off > CORE::length $text;
	substr($text, $off, $len) = $subst;
	my $old = $self->attr(text => $text);
	$self->_modified($old,$text);
	return # nothing
}

sub replaceData16 { # obj, offset, length, replacement
	my ($self,$off,$len,$subst) = @_;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'replaceData cannot take a negative offset')
		if $off <0;
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
		'replaceData cannot take a negative substring length')
		if $len <0;
	my $text = surrogify $self->attr('text');
	die HTML::DOM::Exception->new(INDEX_SIZE_ERR,
	    "replaceData: $off is greater than the length of the text")
		if $off > CORE::length $text;
	substr($text, $off, $len) = $subst;
	my $old = $self->attr(text => desurrogify $text);
	$self->_modified($old,$text);
	return # nothing
}

sub _modified {
	my $self = shift;
	$_[0] eq $_[1] or $self->trigger_event(
		'DOMCharacterDataModified',
		prev_value => $_[0],
		new_value => $_[1],
	);
};

#------- UTILITY FUNCTIONS ---------#

# ~~~ Should these be exported?

sub surrogify($) { # copied straight from JE::String
	my $ret = shift;

	no warnings 'utf8';

	$ret =~ s<([^\0-\x{ffff}])><
		  chr((ord($1) - 0x10000) / 0x400 + 0xD800)
		. chr((ord($1) - 0x10000) % 0x400 + 0xDC00)
	>eg;
	$ret;
}

sub desurrogify($) { # copied straight from JE::String (with length changed
                     # to CORE::length)
	my $ret = shift;
	my($ord1, $ord2);
	for(my $n = 0; $n < CORE::length $ret; ++$n) {  # really slow
		($ord1 = ord substr $ret,$n,1) >= 0xd800 and
		 $ord1                          <= 0xdbff and
		($ord2 = ord substr $ret,$n+1,1) >= 0xdc00 and
		$ord2                            <= 0xdfff and
		substr($ret,$n,2) =
		chr 0x10000 + ($ord1 - 0xD800) * 0x400 + ($ord2 - 0xDC00);
	}

	# In perl 5.8.8, if there is a sub on the call stack that was
	# triggered by the overloading mechanism when the object with the 
	# overloaded operator was passed as the only argument to 'die',
	# then the following substitution magically calls that subroutine
	# again with the same arguments, thereby causing infinite
	# recursion:
	#
	# $ret =~ s/([\x{d800}-\x{dbff}])([\x{dc00}-\x{dfff}])/
	# 	chr 0x10000 + (ord($1) - 0xD800) * 0x400 +
	#		(ord($2) - 0xDC00)
	# /ge;
	#
	# 5.9.4 still has this bug.
	# (fixed in 5.9.5--don't know which patch)

	$ret;
}

sub nodeValue { $_[0]->data(@_[1..$#_]); }


1 __END__ 1


=head1 NAME

HTML::DOM::CharacterData - A base class shared by HTML::DOM::Text and ::Comment

=head1 VERSION

Version 0.058

=head1 DESCRIPTION

This class provides those methods that are shared both by comments and  text
nodes in an HTML DOM tree.

=head1 METHODS

=head2 Attributes

The following DOM attributes are supported:

=over 4

=item data

The textual data that the node contains.

=item length

The number of characters in C<data>.

=item length16

A standards-compliant version of C<length> that counts UTF-16 bytes instead
of characters.

=back

=head2 Other Methods

=over 4

=item substringData ( $offset, $length )

Returns a substring of the data. If C<$length> is omitted, all characters
from C<$offset> to the end of the data are returned.

=item substringData16

A UTF-16 version of C<substringData>.

=item appendData ( $str )

Appends C<$str> to the node's data.

=item insertData ( $offset, $str )

Inserts C<$str> at the given C<$offset>, which is understood to be the
number of Unicode characters from the beginning of the node's data.

=item insertData16

Like C<insertData>, but C<$offset> is taken to be the number of UTF-16
(16-bit) bytes.

=item deleteData ( $offset, $length )

Deletes the specified data. If C<$length> is omitted, all characters from
C<$offset> to the end of the node's data are deleted.

=item deleteData16

A UTF-16 version of the above.

=item replaceData ( $offset, $length, $str )

This replaces the substring specified by C<$offset> and C<$length> with
C<$str>.

=back

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Text>

L<HTML::DOM::Comment>
