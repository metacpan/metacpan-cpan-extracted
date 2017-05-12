=head1 NAME

MKDoc::XML::Token - XML Token Object

=cut
package MKDoc::XML::Token;
use strict;
use warnings;


=head1 SYNOPSIS

  my $tokens = MKDoc::XML::Tokenizer->process_data ($some_xml);
  foreach my $token (@{$tokens})
  {
      print "'" . $token->as_string() . "' is text\n" if (defined $token->text());
      print "'" . $token->as_string() . "' is a self closing tag\n" if (defined $token->tag_self_close());
      print "'" . $token->as_string() . "' is an opening tag\n" if (defined $token->tag_open());
      print "'" . $token->as_string() . "' is a closing tag\n" if (defined $token->tag_close());
      print "'" . $token->as_string() . "' is a processing instruction\n" if (defined $token->pi());
      print "'" . $token->as_string() . "' is a declaration\n" if (defined $token->declaration());
      print "'" . $token->as_string() . "' is a comment\n" if (defined $token->comment());
      print "'" . $token->as_string() . "' is a tag\n" if (defined $token->tag());
      print "'" . $token->as_string() . "' is a pseudo-tag (NOT text and NOT tag)\n" if (defined $token->pseudotag());
      print "'" . $token->as_string() . "' is a leaf token (NOT opening tag)\n" if (defined $token->leaf());
  }


=head1 SUMMARY

L<MKDoc::XML::Token> is an object representing an XML token produced by L<MKDoc::XML::Tokenizer>.

It has a set of methods to identify the type of token it is, as well as to help building a parsed
tree as in L<MKDoc::XML::TreeBuilder>.

=head1 API

=head2 my $token = new MKDoc::XML::Token ($string_token);

Constructs a new MKDoc::XML::Token object.

=cut
sub new
{
    my $class = shift;
    my $token = shift;
    return bless \$token, $class;
}


=head2 my $string_token = $token->as_string();

Returns the string representation of this token so that:

  MKDoc::XML::Token->new ($token)->as_string eq $token

is a tautology.

=cut
sub as_string
{
    my $self = shift;
    return $$self;
}


=head2 my $node = $token->leaf();

If this token is not an opening tag, this method will return its corresponding
node structure as returned by $token->text(), $token->tag_self_close(),
etc.

Returns undef otherwise.

=cut
sub leaf
{
    my $self = shift;
    my $res  = undef;
    
    $res = $self->comment();
    defined $res and return $res;
    
    $res = $self->declaration();
    defined $res and return $res;
    
    $res = $self->pi();
    defined $res and return $res;
    
    $res = $self->tag_self_close();
    defined $res and return $res;
    
    $res = $self->text();
    defined $res and return $res;

    return;
}


=head2 my $node = $token->pseudotag();

If this token is a comment, declaration or processing instruction,
this method will return $token->tag_comment(), $token_declaration()
or $token->pi() resp.

Returns undef otherwise.

=cut
sub pseudotag
{
    my $self = shift;
    my $res  = undef;
    
    $res = $self->comment();
    defined $res and return $res;
    
    $res = $self->declaration();
    defined $res and return $res;
    
    $res = $self->pi();
    defined $res and return $res;
    
    return;
}


=head2 my $node = $token->tag();

If this token is an opening, closing, or self closing tag, this
method will return $token->tag_open(), $token->tag_close()
or $token->tag_self_close() resp.

Returns undef otherwise.

=cut
sub tag
{
    my $self = shift;
    my $res  = undef;

    $res = $self->tag_open();
    defined $res and return $res;
    
    $res = $self->tag_close();
    defined $res and return $res;
    
    $res = $self->tag_self_close();
    defined $res and return $res;
    
    return $res;
}


=head2 my $node = $token->comment();

If this token object represents a declaration, the following structure
is returned:

  # this is <!-- I like Pie. Pie is good -->
  {
      _tag   => '~comment',
      text   => ' I like Pie. Pie is good ',
  }
  
Returns undef otherwise.

=cut
sub comment
{
    my $self = shift;
    my $node = undef;
    $$self =~ /^<\!--/ and do {
	$node = {
	    _tag => '~comment',
	    text => $$self,
	};
	$node->{text} =~ s/^<\!--//;
	$node->{text} =~ s/-->$//;
    };
    $node;
}


=head2 my $node = $token->declaration();

If this token object represents a declaration, the following structure
is returned:

  # this is <!DOCTYPE foo>
  {
      _tag   => '~declaration',
      text   => 'DOCTYPE foo',
  }

Returns undef otherwise.

=cut
sub declaration
{
    my $self = shift;
    my $node = undef;
    $$self !~ /^<\!--/ and $$self =~ /^<!/ and do {
	$node = {
	    _tag => '~declaration',
	    text => $$self,
	};
	$node->{text} =~ s/^<!//;
	$node->{text} =~ s/>$//;
    };
    $node;
}


=head2 my $node = $token->pi();

If this token object represents a processing instruction, the following structure
is returned:

  # this is <?xml version="1.0" charset="UTF-8"?>
  {
      _tag   => '~pi',
      text   => 'xml version="1.0" charset="UTF-8"',
  }

Returns undef otherwise.

=cut
sub pi
{
    my $self = shift;
    my $node = undef;
    $$self =~ /^<\?/ and do {
	$node = {
	    _tag => '~pi',
	    text => $$self,
	};
	$node->{text} =~ s/^<\?//;
	$node->{text} =~ s/\>$//;
	$node->{text} =~ s/\?$//;
    };
    $node;
}


=head2 my $node = $token->tag_open();

If this token object represents an opening tag, the following structure
is returned:

  # this is <aTag foo="bar" baz="buz">
  {
      _tag   => 'aTag',
      _open  => 1,
      _close => 0,
      foo    => 'bar',
      baz    => 'buz',
  }

Returns undef otherwise.

=cut
sub tag_open
{
    my $self = shift;
    my $node  = undef;
    $$self !~ /^<\!/ and
    $$self !~ /^<\// and
    $$self !~ /\/>$/ and
    $$self !~ /^<\?/ and    
    $$self =~ /^</   and do {
	my %node      = _extract_attributes ($$self);
	($node{_tag}) = $$self =~ /.*?([A-Za-z0-9][A-Za-z0-9_:-]*)/;
	$node{_open}  = 1;
	$node{_close} = 0;
	$node = \%node;
    };
    
    $node;
}


=head2 my $node = $token->tag_close();

If this token object represents a closing tag, the following structure
is returned:

  # this is </aTag>
  {
      _tag   => 'aTag',
      _open  => 0,
      _close => 1,
  }

Returns undef otherwise.

=cut
sub tag_close
{
    my $self = shift;
    my $node = undef;
    $$self !~ /^<\!/ and
    $$self =~ /^<\// and
    $$self !~ /\/>$/ and do {
        my %node      = ();
	($node{_tag}) = $$self =~ /.*?([A-Za-z0-9][A-Za-z0-9_:-]*)/;
	$node{_open}  = 0;
	$node{_close} = 1;
	$node = \%node;
    };
    
    $node;
}


=head2 my $node = $token->tag_self_close();

If this token object represents a self-closing tag, the following structure
is returned:

  # this is <aTag foo="bar" baz="buz" />
  {
      _tag   => 'aTag',
      _open  => 1,
      _close => 1,
      foo    => 'bar',
      baz    => 'buz',
  }

Returns undef otherwise.

=cut
sub tag_self_close
{
    my $self = shift;
    my $node  = undef;
    $$self !~ /^<\!/ and
    $$self !~ /^<\// and
    $$self =~ /\/>$/ and
    # ((?:\w|:|-)+)\s*=\s*\"(.*?)\"/gs;
    $$self =~ /^</   and do {
	my %node      = _extract_attributes ($$self);
        ($node{_tag}) = $$self =~ /.*?([A-Za-z0-9][A-Za-z0-9_:-]*)/;
	$node{_open}  = 1;
	$node{_close} = 1;
	$node = \%node;
    };
    
    $node;
}


=head2 my $node = $token->text();

If this token object represents a piece of text, then this text is returned.
Returns undef otherwise. TRAP! $token->text() returns a false value if this
text happens to be '0' or ''. So really you should use:

  if (defined $token->text()) {
    ... do stuff...
  }

=cut
sub text
{
    my $self = shift;
    return ($$self !~ /^</) ? $$self : undef;
}

our $S = "[ \\n\\t\\r]+";
our $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
our $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
our $Name = "(?:$NameStrt)(?:$NameChar)*";
our $EndTagCE = "$Name(?:$S)?>?";
our $AttValSE = "\"[^<\"]*\"|'[^<']*'";
our $ElemTagCE = "$Name((?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*)(?:$S)?/?>?";
our $ElemTagCE_Mod = "$S($Name)(?:$S)?=(?:$S)?($AttValSE)";

our $RE_1 = qr /$ElemTagCE/;
our $RE_2 = qr /$ElemTagCE_Mod/;


sub _extract_attributes
{
    my $tag = shift;
    my ($tags) = $tag =~ /$RE_1/g;
    my %attr = $tag =~ /$RE_2/g;
    foreach my $key (keys %attr)
    {
        my $val = $attr{$key};
        $val    =~ s/^(\"|\')//;
        $val    =~ s/(\"|\')$//;
        $attr{$key} = $val;
    }
    
    %attr;
}


1;


__END__


=head1 NOTES

L<MKDoc::XML::Token> works with L<MKDoc::XML::Tokenizer>, which can be used
when building a full tree is not necessary. If you need to build a tree, look
at L<MKDoc::XML::TreeBuilder>.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::Tokenizer>
L<MKDoc::XML::TreeBuilder>


=cut
