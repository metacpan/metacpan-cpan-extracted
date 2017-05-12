package Jabber::NodeFactory;

# $Id: NodeFactory.pm,v 1.3 2002/02/22 20:02:58 dj Exp $

use XML::Parser;

=head1 NAME

Jabber::NodeFactory - Simple XML Node Factory for Jabber

=head1 SYNOPSIS

  my $nf = new Jabber::NodeFactory(fromstr => 1);
  print $nf->newNode('presence')->toStr;

  -> <presence/>

  my $tag1 = $nf->newNode('iq');
  $tag1->attr('type', 'get');
  my $query = $tag1->insertTag('query', 'jabber:iq:auth');
  $query->insertTag('username')->data('qmacro');
  print $tag1->toStr;

  -> <iq type='get'><query xmlns='jabber:iq:auth'>
          <username>qmacro</username></query></iq>

  my $tag2 = $nf->newNodeFromStr("<message><body>hi</body></message>");
  $tag2->attr('to','qmacro@jabber.org');
  my $msg = $tag2->getTag('body')->data;
  print $tag2->toStr, "\n";
  print $msg;

  -> <message to='qmacro@jabber.org'><body>hi</body></message>
  -> hi

=head1 DESCRIPTION

Jabber::NodeFactory is a library for creating and
manipulating XML nodes. It was created to offer similar functions
to the xmlnode library in the Jabber server implementation.

It provides enough functions to create and manipulate XML fragments
(nodes) in the Jabber XML stream world. The functions are low level,
RISC-style :-)

=head1 ORGANISATION

There are two packages - Jabber::NodeFactory and Jabber::NodeFactory::Node.
The former is a wrapper which offers two node construction methods;
the latter is the package that represents the actual node objects
that are created and manipulated.

Use Jabber::NodeFactory to contruct new nodes (which will be 
Jabber::NodeFactory::Node objects) and
Jabber::NodeFactory::Node to manipulate those nodes. 

The Connection package will present stream fragments received in
the form of Jabber::NodeFactory::Node objects; use
Jabber::NodeFactory::Node to parse and manipulate these fragments.

=head1 METHODS in Jabber::NodeFactory

=over 4

=item new()

The Jabber::NodeFactory constructor. Call this to create a
new Jabber::NodeFactory, with which you can build nodes.

You can create nodes in one of two ways - building them up starting
from the tagname (C<newNode()>), or creating them from a string
(C<newNodeFromStr()>). If you want to be
able to do the latter, you need to specify the flag 

  fromstr => 1

like this

  my $nf = new Jabber::NodeFactory(fromstr => 1)

Creating nodes from strings requires the strings to be parsed; an
XML parser is only created as part of the Jabber::NodeFactory object being
constructed if you set this flag. If you don't set the flag and 
subsequently try to call C<newNodeFromStr()>, you'll get an error.

=cut

sub new {

  # debug => 1
  # fromstr => 1 

  my ($class, %args) = @_;
  my $self = {};
  if ($args{fromstr}) {
    $self->{parser} = new XML::Parser
      (
        Handlers => {
                       Start => sub { $self->_startTag(@_) },
                       End   => sub { $self->_endTag(@_) },
                       Char  => sub { $self->_charData(@_) },
                    }
      );
    $self->{nodedepth} = 0;
  }

  $self->{debug} = 1 if $args{debug};

  return bless $self, $class;

}


sub _debug {

  my $self = shift;
  my $string = shift;
  print STDERR $string,"\n" if $self->{debug};

}


=item newNode()

Call this to create a new node. This will return a new
Jabber::NodeFactory::Node object. There is one mandatory argument to
this call - the name of the tag for the node being created.

  my $node = $nf->newNode('tag');

will create a node that looks like this:

  <tag/>

If you want to create a node like this, by specifying a tag name,
you can also use the C<new> method in Jabber::NodeFactory::Node to achieve
the same thing; the C<newNode> method has been made available here just to
have some consistency with C<newNodeFromStr>.

=cut

sub newNode {

  my $self = shift;
  my $name = shift;
  my $xmlns = shift;

  return Jabber::NodeFactory::Node->new($name, $xmlns);
  
}


=item newNodeFromStr()

Like C<newNode>, this also returns a new Jabber::NodeFactory::Node object.
The single argument to be passed is a string. The NodeFactory will
use an XML parser to parse this string and create a node or hierarchy 
of nodes.

  my $node =
    $nf->newNodeFromStr(qq[<test><child attr1='a'/></test>]);

will create a node object that represents the <test> node having a
child node as shown.

=cut

sub newNodeFromStr {

  my $self = shift;
  my $string = shift;

  unless ($self->{parser}) {
    die "Cannot create node from string - create nodefactory with fromstr => 1\n";
  }

  $self->{node} = undef;
  $self->{parser}->parse($string);
  return $self->{node};

}


sub _startTag {

  my ($self, $expat, $tag, %attr) = @_;
  $self->_debug("START: $tag");
  $self->{depth} += 1;
	if ($self->{depth} == 1) {
    $self->{node} = Jabber::NodeFactory::Node->new($tag);
    $self->{node}->attr($_, $attr{$_}) foreach keys %attr;
    $self->{currnode} = $self->{node};
  }
  else {
    my $kid = $self->{currnode}->insertTag($tag);
    $kid->attr($_, $attr{$_}) foreach keys %attr;
    $self->{currnode} = $kid;
  }

}

sub _endTag {

  my ($self, $expat, $tag) = @_;
  $self->_debug("END  : $tag");
  $self->{depth} -= 1;
# $self->{currnode} = $self->{node}->parent();
  $self->{currnode} = $self->{currnode}->parent();

}

sub _charData {

  my ($self, $expat, $data) = @_;
  $self->_debug("DATA : $data");
  $self->{currnode}->data($self->{currnode}->data().$data);

}

=back

=cut

############################################################################

package Jabber::NodeFactory::Node;

=head1 METHODS in Jabber::NodeFactory::Node

=over 4

=item new()

Construct a new node. Returns a Jabber::NodeFactory::Node object. You must
specify a tag name for the node.

Example:

  my $tag1 = new Jabber::NodeFactory::Node('tag1');

$tag1 represents a node that looks like this:

  <tag1/>

=cut

use Scalar::Util qw(weaken);

sub new {

  my ($class, $name, $xmlns, $parent) = @_;

  my $node = {
               name   => $name,
               attrs  => {},
               data   => '',
               kids   => [],
               parent => $parent,
             };

  weaken($node->{parent}); # XXX
  bless $node => $class;
  $node->attr('xmlns' => $xmlns) if $xmlns;
  return $node;

}


=item name()

Returns the name (the tag name) of the node, in the form of a string.

=cut

sub name {
  my $self = shift;
  return $self->{name};
}


=item parent()

Returns the node's parent. This will be a node object or undef (if
it doesn't have a parent).

=cut

sub parent { 
  my $self = shift;
  return $self->{parent};
}


# sets parent; called from insertTag()
sub _setParent {
  my $self = shift;
  my $parent = shift;
  $self->{parent} = $parent;
  return $self->{parent};
}


=item attr()

Sets or gets a node attribute. Pass one argument - an attribute 
name - to get the value, or two arguments - the name and a value - 
to set the value. In both cases the value is returned.

Example:

  $tag1->attr('colour' => 'red');
  print $tag1->attr('colour');

prints

  red

=cut

sub attr {

  my ($self, $attr, $val) = @_;

  if (defined $val) {
    if ($val eq '') {
      delete $self->{attrs}->{$attr};
    }
    else {
      $self->{attrs}->{$attr} = $val;
    }
  }

  return $self->{attrs}->{$attr};
 
}

            
=item data()

Sets or gets a node's data. Pass no arguments to get the data, 
or one argument - the data - to set the data.
In both cases the data is returned.

Example:

  $tag1->data('hello world');

results in $tag1 representing

  <tag1 colour='red'>hello world</tag1>

The common character entities will be encoded/decoded on the fly.
These are & (&amp;), " (&quot;), ' (&apos;), < (&lt;) and > (&gt;).
This means that if you call data() with the string "this & that",
what actually will get stored is "this &amp; that". If you receive
a string containing "--&gt; this way", calling data() to retrieve
it will give you "--> this way".

See the rawdata() function for a contrast.

=cut

sub data {

  my $self = shift;
  if (my $data = shift) {
    $self->{data} = _encode($data);
  }

  return _decode($self->{data});
 
}


sub _encode {

  my $data = shift;

  $data =~ s/&/&amp;/g;
  $data =~ s/</&lt;/g;
  $data =~ s/>/&gt;/g;
  $data =~ s/'/&apos;/g;
  $data =~ s/"/&quot;/g;

  return $data;

}

            
sub _decode {

  my $data = shift;

  $data =~ s/&amp;/&/g;
  $data =~ s/&lt;/</g;
  $data =~ s/&gt;/>/g;
  $data =~ s/&apos;/'/g;
  $data =~ s/&quot;/"/g;

  return $data;

}

            
=item rawdata()

Similar to data(), this function allows you to get and set the data
for a node. Unlike data(), there is no encoding or decoding of character
entities. It's up to you to make sure you don't break the XML stream by
sending a stray "<" or something.

=cut

sub rawdata {

  my $self = shift;
  if (my $data = shift) {
    $self->{data} = $data;
  }

  return $self->{data};
 
}


=item insertTag()

This will insert a tag - with the name given in
the first (mandatory) argument - into the node object on which
the method call is made. 

A namespace can be specified in an optional second argument. 

Example:

  my $tag2 = new Jabber::NodeFactory::Node('tag2');
  $tag2->insertTag('a');
  $tag2->insertTag('b', 'fish:face');
  $tag2->insertTag('c')->data('hello');

results in $tag2 looking like this:

  <tag2><a/><b xmlns='fish:face'/><c>hello</c></tag2>

=cut

sub insertTag {

  my ($self, $tagname, $ns) = @_;

  # Can pass a Node to insert too
  my $tag = ref($tagname) eq ref($self)
            ? $tagname->_setParent($self) && $tagname
            : new Jabber::NodeFactory::Node($tagname, $ns, $self);

  push @{$self->{kids}}, $tag;

  return $tag;

}


=item toStr()

Returns a string representation of the node (and all its children).

Example:

  my $x = new Jabber::NodeFactory::Node('tag');
  my $y = $x->insertTag('anothertag');
  $y->attr('number',3);

  print $x->toStr, "\n";
  print $y->toStr, "\n";

results in:

  <tag><anothertag number='3'/></tag>
  <anothertag number='3'/>

=cut

sub toStr {

  my $self = shift;
  my $str = '<'.$self->name();
  foreach my $attr (keys %{$self->{attrs}}) {
    $str .= ' '.$attr."='".$self->{attrs}->{$attr}."'";
  }
  if ($self->{data} or @{$self->{kids}}) {
    $str .= '>'.$self->{data};
    foreach my $kid (@{$self->{kids}}) {
      $str .= $kid->toStr();
    }   
    $str .= '</'.$self->name().'>';
  }
  else {
    $str .= '/>';
  }
  return $str;
 
}


=item getTag()

Retrieves a child tag and returns it as a node. Specify the name of the
tag to retrieve, and an optional namespace attribute (that must be 
explicitly specified as an xmlns attribute in the child tag you want) 
to distinguish it from other tags of the same name.

If you don't know the tagname but know what namespace you want (common
in Jabber), then specify an empty string for the tagname.

Example:

  $node->getTag('x','jabber:x:event');

Will return the <x> tag(s) that have xmlns='jabber:x:event'. 
If you only want the first one, make the call in scalar context:

  my $event = $node->getTag('x','jabber:x:event');

otherwise make it in array context:

  my @xtags = $node->getTag('x');

to get multiple tags (node objects).
  

Another example:

  my $query = $node->getTag('', 'jabber:iq:version');

This gets a 'query' node that's qualified by the iq:version namespace.

=cut

sub getTag {

  my ($self, $tagname, $ns) = @_;

  my @tags;

  foreach my $kid (@{$self->{kids}}) {
    if (length($tagname)) {
      next unless $kid->name eq $tagname;
    }
    if (defined($ns) and length($ns)) {
      next unless defined($kid->attr('xmlns')) and $kid->attr('xmlns') eq $ns;
    }
    push @tags, $kid;
  }

  # Potentially only return the first one
  return wantarray ? @tags : $tags[0];

}


=item hide()

Use this method to remove a child tag. Use getTag to identify the tag
to remove.

Example:

  my $tag = $nf->newNodeFromStr(qq[<a><b fruit='banana'>yellow</b></a>]);
  $tag->getTag('b')->hide;
  print $tag->toStr;

outputs this:

  <a/>

=cut

sub hide {

  my ($self) = @_;
  my @newkids;
  foreach my $kid (@{$self->{parent}->{kids}}) {
    push(@newkids, $kid) unless $kid eq $self;
  }
  $self->{parent}->{kids} = \@newkids;

}


=item getChildren()

This returns a list (array) of the direct child tags of the tag
on which the method is called.

Example:

  my $node = $nf->newNodeFromStr(qq[<a><a1/><a2/><a3><a31/></a3></a>]);
  print $_->name, "\n" foreach $

=cut

sub getChildren {

  my ($self) = @_;
  return @{$self->{kids}};

}


=back

=head1 SEE ALSO

Jabber::Connection, Jabber::NS

=head1 AUTHOR

DJ Adams

=head1 VERSION

early

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



1;



