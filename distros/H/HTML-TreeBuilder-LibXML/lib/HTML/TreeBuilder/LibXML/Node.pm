package HTML::TreeBuilder::LibXML::Node;
use strict;
use warnings;
use Carp();

sub new {
    my $class = shift;
    Carp::croak 'missing arguments' unless @_>=1;
    if (@_==1 && ref($_[0])) {
        bless {node => $_[0]}, $class;
    } else {
        my ($tag, @attrs) = @_;
        my $doc = XML::LibXML->createDocument;
        my $node = $doc->createElement($tag);
        while (my ($k, $v) = splice @attrs, 0, 2) {
            $node->setAttribute($k, $v);
        }
        bless {node => $node}, $class;
    }
}

sub attr {
    my ($self, $key, $value) = @_;
    if (@_ == 3) {
        if (defined $value) {
            $self->{node}->setAttribute (lc $key, $value);
        } else {
            $self->{node}->removeAttribute(lc $key);
        }
    } elsif (@_ == 2 and lc $key eq 'text') {
        return $self->{node}->textContent;
    }
    $self->{node}->getAttribute(lc $key);
}

sub isTextNode {
    my $self = shift;
    $self->{node}->isa('XML::LibXML::Text');
}

# The analog of HTML::TreeBuilder::XPath::getValue for comment nodes
*getValue = \&as_text;

sub string_value {
    $_[0]->{node}->textContent;
}

sub as_text {
    $_[0]->{node}->textContent;
}

sub as_trimmed_text {
    my $text = shift->as_text(@_);
    $text =~ s/[\n\r\f\t ]+$//s;
    $text =~ s/^[\n\r\f\t ]+//s;
    $text =~ s/[\n\r\f\t ]+/ /g;
    return $text;
}
sub as_text_trimmed { shift->as_trimmed_text(@_) } # alias

sub objectify_text { }
sub deobjectify_text { }

sub as_XML {
    $_[0]->{node}->toString;
}

sub as_HTML {
    return $_[0]->{node}->toStringHTML if $_[0]->{node}->can('toStringHTML'); # best method, but only document nodes can toStringHTML()
    
    # second best is to call toStringC14N(1), which generates valid HTML (eg. no auto closed <div/>), 
    # but dies on some cases with "Failed to convert doc to string in doc->toStringC14N" error.
    # so we fallback to toString()
    {
        local $@; # protect existing $@
        my $output = eval { $_[0]->{node}->toStringC14N(1) };
        return $_[0]->{node}->toString if ($@ or $output eq '');
        return $output;
    }
}

sub tag {
    $_[0]->{node}->localname
}

sub id {
    if (@_==2) {
        # setter
        if (defined $_[1]) {
            $_[0]->{node}->setAttribute('id', $_[1]);
        } else {
            $_[0]->{node}->removeAttribute('id');
        }
    } else {
        $_[0]->{node}->getAttribute('id');
    }
}

# hack for Web::Scraper
sub isa {
    my ($self, $klass) = @_;
    $klass eq 'HTML::Element' ? 1 : UNIVERSAL::isa($self, $klass);
}

sub exists {
    my( $self , $xpath ) = @_;

    $self->_eof_or_die unless $self->{node};
    my @nodes = $self->{node}->findnodes( $xpath );
    return scalar( @nodes ) ? 1 : 0;
}

sub find {
    my( $self , $elem ) = @_;

    $self->_eof_or_die unless $self->{node};

    my @nodes = $self->{node}->getElementsByTagName( $elem );
    @nodes = map { HTML::TreeBuilder::LibXML::Node->new( $_ ) } @nodes;

    wantarray ? @nodes : \@nodes;
}

sub findnodes {
    my ($self, $xpath) = @_;

    $self->_eof_or_die unless $self->{node};
    my @nodes = $self->{node}->findnodes( $xpath );
    @nodes = map { HTML::TreeBuilder::LibXML::Node->new($_) } @nodes;
    wantarray ? @nodes : \@nodes;
}

*findnodes_as_string  = \&findvalue;
*findnodes_as_strings = \&findvalues;

sub findnodes_filter {
    my( $self , $xpath , $callback ) = @_;

    Carp::croak "Second argument must be coderef"
          unless $callback and ref $callback eq 'CODE';

    my @nodes = $self->findnodes( $xpath );
    @nodes = grep { $callback->($_) } @nodes;

    wantarray ? @nodes : \@nodes;
}

sub findvalue {
    my ($self, $xpath) = @_;

    $self->_eof_or_die unless $self->{node};
    $self->{node}->findvalue( $xpath );
}

sub findvalues {
    my( $self , $xpath ) = @_;

    $self->_eof_or_die unless $self->{node};
    my $nodes = $self->{node}->find( $xpath );
    my @nodes = map { $_->textContent } $nodes->get_nodelist;
    wantarray ? @nodes : \@nodes;
}

sub clone {
    my ($self, ) = @_;

    my $orignode = $self->{node};
    my $origdoc = $orignode->ownerDocument;

    my $node = $orignode->cloneNode(1);

    # arguments can be undefined
    my $doc = do {
        no warnings;
        XML::LibXML::Document->new($origdoc->version, $origdoc->encoding);
    };
    
    if ($node->isa('XML::LibXML::Dtd')) {
        $doc->createInternalSubset( $node->getName, $node->publicId, $node->systemId );
        $node = $doc->internalSubset;        
    } elsif ($node->isa('XML::LibXML::Element')) {
        $doc->setDocumentElement($node);    
    } else {
        $doc->adoptNode($node);
    }
    
    my $cloned = __PACKAGE__->new($node);
    return $cloned;
}

sub clone_list {
    my $class = shift;
    my @clones = map { $_->clone } @_;
    @clones;    
}

sub detach {
    my $self = shift;
    my $parent = $self->parent;
    #$self->{node}->unbindNode();   
    my $doc = XML::LibXML->createDocument;
    $doc->adoptNode($self->{node});
    $doc->setDocumentElement($self->{node});  
    $parent;
}

sub delete {
    my $self = shift;
    $self->{node}->unbindNode();
}

sub delete_content {
    my ($self) = @_;
    $self->{node}->removeChildNodes;
}

sub getFirstChild {
    my $self = shift;
    __PACKAGE__->new($self->{node}->getFirstChild);
}

sub childNodes {
    my $self = shift;

    $self->_eof_or_die unless $self->{node};
    my @nodes = $self->{node}->childNodes;
    @nodes = map { __PACKAGE__->new($_) } @nodes;
    wantarray ? @nodes : \@nodes;
}

sub content_list {
    my ($self) = @_;
    my @nodes = $self->childNodes;
    @nodes;
}

sub replace_with {
    my $self = shift;
    
    # TODO handle @_ == 0
    
    my $node   = $self->{node}; 
    my $doc    = $node->ownerDocument;
    my $parent = $node->parentNode;
    die "can't replace_with(), node has no parent!" unless $parent;
            
    my @nodes  = map { ref $_ ? $_->{node} : $doc->createTextNode($_) } @_;
    
    if ($parent->isa('XML::LibXML::Document')) {
        # can't call insertBefore() in a document node,
        # so this is the best hack so far :[
        # works only if $node is the last child
        die "[not supported] calling replace_with() in a node that is child of a document node, and its not the last child."
            unless $node->isSameNode($parent->lastChild);
        
        foreach (@nodes) {
                       
            if ($_->isa('XML::LibXML::Dtd')) {
                $parent->createInternalSubset($_->getName, $_->publicId, $_->systemId);
                next;
            }
            $parent->adoptNode($_);
            $node->addSibling($_);
        }    
         
    }
    else {
        $parent->insertBefore($_, $node)
            for @nodes;        
    }
    
    $self->detach;   
    $self;  
}

sub push_content {
    my $self = shift;
 
    my $node = $self->{node};
    my $doc = $node->isa('XML::LibXML::Document') ? $node : $node->ownerDocument;
    my @nodes = map { ref $_ ? $_->{node} : $doc->createTextNode($_) } @_;
    
    # thats because appendChild() is not supported on a Document node (as of XML::LibXML 2.0017)
    if ($node->isa('XML::LibXML::Document')) { 
        
        foreach (@nodes) {      
            #$node->adoptNode($_);
            $node->hasChildNodes ? $node->lastChild->addSibling($_)
                                 : $node->setDocumentElement($_);
        }        
    }
    else {
        $node->appendChild($_) for @nodes;
    }
    
    $self;
}

sub unshift_content {
    my $self = shift;
    
    return $self->push_content(@_) 
        unless $self->{node}->hasChildNodes;

    my $node = $self->{node};
    my $doc = $node->isa('XML::LibXML::Document') ? $node : $node->ownerDocument;
    my @nodes = map { ref $_ ? $_->{node} : $doc->createTextNode($_) } @_;
    
    # thats because insertBefore() is not supported on a Document node (as of XML::LibXML 2.0017)
    if ($node->isa('XML::LibXML::Document')) {
        
        foreach (@nodes) {
            $node->hasChildNodes ? $node->lastChild->addSibling($_)
                                 : $node->setDocumentElement($_);
        }
        
        # rotate
        while (not $node->firstChild->isSameNode($nodes[0])) {
            my $first_node = $node->firstChild;
            $first_node->unbindNode;
            $node->lastChild->addSibling($first_node);
            
        }        
    }
    else {
        my $first_child = $node->firstChild;
        $node->insertBefore($_, $first_child) for @nodes;
    }
    
    $self;    
}

sub left {
    my $self = shift;

    $self->_eof_or_die unless $self->{node};
    my $prev = $self->{node}->previousNonBlankSibling;
    return $prev ? __PACKAGE__->new( $prev ) : undef;
}

sub right {
    my $self = shift;

    $self->_eof_or_die unless $self->{node};
    my $next = $self->{node}->nextNonBlankSibling;
    return $next ? __PACKAGE__->new( $next ) : undef;
}

sub look_down {
    my $self = shift;
    my @args = @_;

    $self->_eof_or_die unless $self->{node};

    my @filter;
    my $xpath = "//*"; # default
    while (@args) {
        if (ref $args[0] eq 'CODE') {
            my $code = shift @args;
            push @filter, $code;
        } elsif (@args >= 2 && $args[0] eq '_tag') {
            my($tag, $want_tag) = splice(@args, 0, 2);
            $xpath = "//$want_tag";
        } elsif (@args >= 2) {
            my($attr, $stuff) = splice(@args, 0, 2);
            if (ref $stuff eq 'Regexp') {
                push @filter, sub { no warnings 'uninitialized'; $_[0]->attr($attr) =~ $stuff };
            } else {
                push @filter, sub { no warnings 'uninitialized'; $_[0]->attr($attr) eq $stuff };
            }
        } else {
            Carp::carp("Don't know what to do with @args");
            shift @args;
        }
    }

    $xpath =~ s/~text\b/text()/g;

    my @nodes = $self->findnodes($xpath);
    my @wants = grep {
        my $node = $_;
        my $ok = 1;
        for my $filter (@filter) {
            $filter->($_) or $ok = 0;
        }
        $ok ? $node : ();
    } @nodes;

    wantarray ? @wants : $wants[0];
}

sub all_attr {
    my $self = shift;
    return map { $_->name => $_->value } $self->{node}->attributes;
}

sub all_attr_names {
    my $self = shift;
    return map $_->name, $self->{node}->attributes;
}

sub all_external_attr       { shift->all_attr(@_) }
sub all_external_attr_names { shift->all_attr_names(@_) }

sub _eof_or_die {
    my $self = shift;
    if (defined($self->{_content})) {
        $self->eof;
    } else {
        Carp::croak "\$self is not loaded: $self"
    }
}


sub matches {
    my ($self, $xpath) = @_;    
    
    foreach ($self->{node}->ownerDocument->findnodes($xpath)) {
        return 1 if $_->isEqual($self->{node});
    }    
    
    return;
}

sub parent {
    my $self = shift;
    
    if (@_) {    
        
        # unset
        unless (defined $_[0]) {
            $self->{node}->unbindNode;   
            return;            
        }
        
        # set        
        Carp::croak "an element can't be made its own parent"
            if ref $_[0]->{node}->isSameNode($self->{node});    # sanity
            
        my $parent = $_[0]->{node};
        
        if ($_[0]->{node}->isa('XML::LibXML::Document')) {

            if ($parent->hasChildNodes) {
                $parent->lastChild->addSibling($self->{node});
            }
            else {
                $parent->adoptNode($self->{node});
                $parent->setDocumentElement($self->{node});                    
            }                
            
        }
        else {
            $parent->appendChild($self->{node});                
        }
                
    }
    else {
        # get
        my $parent = $self->{node}->parentNode;
        return defined $parent && !$parent->isa('XML::LibXML::DocumentFragment')? ref($self)->new($parent) : undef;
    }

}

sub postinsert {
    my $self   = shift;    
    my @nodes  = map { $_->{node} } @_;
    my $parent = $self->{node}->parentNode;
    
    $parent->insertAfter($_, $self->{node})
        foreach reverse @nodes;
    
    $self;    
}

sub preinsert {
    my $self   = shift;    
    my @nodes  = map { $_->{node} } @_;
    my $parent = $self->{node}->parentNode;
    
    $parent->insertBefore($_, $self->{node})
        foreach @nodes;
    
    $self;    
}



1;

__END__

=head1 NAME

HTML::TreeBuilder::LibXML::Node - HTML::Element compatible API for HTML::TreeBuilder::LibXML

=head1 SYNOPSIS

  my $value = $node->attr('name');
  my $string = $node->string_value;
  my $text   = $node->as_text;
  my $t_text = $node->as_trimmed_text;
  my $xml    = $node->as_XML;
  my $html   = $node->as_HTML;
  my $tag    = $node->tag;
  my $id     = $node->id;
  my $clone  = $node->clone;
  $node->delete;
  my $prev_sib = $node->left;
  my $next_sib = $node->right;
  $node->look_down(@args);
  my %attr     = $node->all_attr;
  my %attr     = $node->all_external_attr;
  my @names    = $node->all_attr_names;
  my @names    = $node->all_external_attr_names;
  my @elements = $node->find($elem_name);
  my @child_nodes = $node->content_list;
  my $parent = $node->parent;
  my $old_parent = $node->detach;
  $node->postinsert($element_or_text, ...);
  $node->preinsert($element_or_text, ...);
  $node->push_content($element_or_text, ...);
  $node->unshift_content($element_or_text, ...);
  $node->replace_with($element_or_text, ...);
  
  my @clones = HTML::TreeBuilder::LibXML::Node->clone_list(@nodes);

  # HTML::TreeBuilder::XPath
  my @nodes  = $node->find($xpath)
  my @nodes  = $node->findnodes($xpath);
  my $value  = $node->findvalue($xpath);
  my @values = $node->findvalues($xpath);
  $node->isTextNode;
  my $child = $node->getFirstChild;
  my $bool  = $node->exists($xpath);
  my $bool  = $node->matches($xpath);

  my $value  = $node->findnodes_as_string($xpath);
  my @values = $node->findnodes_as_strings($xpath);
