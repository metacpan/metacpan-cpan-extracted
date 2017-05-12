# This is a fork of HTML::Element.  Eventually the code may be merged.

package HTML::DOM::_Element;

use strict;
use Carp           ();
use HTML::Entities ();
use HTML::Tagset   ();
use integer;    # vroom vroom!

use vars qw( $VERSION );
$VERSION = 4.2;

# This contorls encoding entities on output.
# When set entities won't be re-encoded.
# Defaulting off because parser defaults to unencoding entities
our $encoded_content = 0;

use vars qw($html_uc $Debug $ID_COUNTER %list_type_to_sub);

$Debug = 0 unless defined $Debug;

sub Version { $VERSION; }

my $nillio = [];

*HTML::DOM::_Element::emptyElement   = \%HTML::Tagset::emptyElement;      # legacy
*HTML::DOM::_Element::optionalEndTag = \%HTML::Tagset::optionalEndTag;    # legacy
*HTML::DOM::_Element::linkElements   = \%HTML::Tagset::linkElements;      # legacy
*HTML::DOM::_Element::boolean_attr   = \%HTML::Tagset::boolean_attr;      # legacy
*HTML::DOM::_Element::canTighten     = \%HTML::Tagset::canTighten;        # legacy

# Constants for signalling back to the traverser:
my $travsignal_package = __PACKAGE__ . '::_travsignal';
my ( $ABORT, $PRUNE, $PRUNE_SOFTLY, $OK, $PRUNE_UP )
    = map { my $x = $_; bless \$x, $travsignal_package; }
    qw(
    ABORT  PRUNE   PRUNE_SOFTLY   OK   PRUNE_UP
);

## Comments from Father Chrysostomos RT #58880
## The sole purpose for empty parentheses after a sub name is to make it
## parse as a 0-ary (nihilary?) function. I.e., ABORT+1 should parse as
## ABORT()+1, not ABORT(+1). The parentheses also tell perl that it can
### be inlined.
##Deparse is really useful for demonstrating this:
##$ perl -MO=Deparse,-p -e 'sub ABORT {7} print ABORT+8'
# Vs
# perl -MO=Deparse,-p -e 'sub ABORT() {7} print ABORT+8'
#
# With the parentheses, it not only makes it parse as a term.
# It even resolves the constant at compile-time, making the code run faster.

## no critic
sub ABORT ()        {$ABORT}
sub PRUNE ()        {$PRUNE}
sub PRUNE_SOFTLY () {$PRUNE_SOFTLY}
sub OK ()           {$OK}
sub PRUNE_UP ()     {$PRUNE_UP}
## use critic

$html_uc = 0;

# set to 1 if you want tag and attribute names from starttag and endtag
#  to be uc'd

# regexs for XML names
# http://www.w3.org/TR/2006/REC-xml11-20060816/NT-NameStartChar
my $START_CHAR
    = qr/(?:\:|[A-Z]|_|[a-z]|[\x{C0}-\x{D6}]|[\x{D8}-\x{F6}]|[\x{F8}-\x{2FF}]|[\x{370}-\x{37D}]|[\x{37F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])/;

# http://www.w3.org/TR/2006/REC-xml11-20060816/#NT-NameChar
my $NAME_CHAR
    = qr/(?:$START_CHAR|-|\.|[0-9]|\x{B7}|[\x{0300}-\x{036F}]|[\x{203F}-\x{2040}])/;

# Elements that does not have corresponding end tags (i.e. are empty)

#==========================================================================

#
# An HTML::DOM::_Element is represented by blessed hash reference, much like
# Tree::DAG_Node objects.  Key-names not starting with '_' are reserved
# for the SGML attributes of the element.
# The following special keys are used:
#
#    '_tag':    The tag name (i.e., the generic identifier)
#    '_parent': A reference to the HTML::DOM::_Element above (when forming a tree)
#    '_pos':    The current position (a reference to a HTML::DOM::_Element) is
#               where inserts will be placed (look at the insert_element
#               method)  If not set, the implicit value is the object itself.
#    '_content': A ref to an array of nodes under this.
#                It might not be set.
#
# Example: <img src="gisle.jpg" alt="Gisle's photo"> is represented like this:
#
#  bless {
#     _tag => 'img',
#     src  => 'gisle.jpg',
#     alt  => "Gisle's photo",
#  }, 'HTML::DOM::_Element';
#

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my $tag = shift;
    Carp::croak("No tagname") unless defined $tag and length $tag;
    Carp::croak "\"$tag\" isn't a good tag name!"
        if $tag =~ m/[<>\/\x00-\x20]/;    # minimal sanity, certainly!
    my $self = bless { _tag => scalar( $class->_fold_case($tag) ) }, $class;
    my ( $attr, $val );
    while ( ( $attr, $val ) = splice( @_, 0, 2 ) ) {
## RT #42209 why does this default to the attribute name and not remain unset or the empty string?
        $val = $attr unless defined $val;
        $self->{ $class->_fold_case($attr) } = $val;
    }
    if ( $tag eq 'html' ) {
        $self->{'_pos'} = undef;
    }
    return $self;
}

sub attr {
    my $self = shift;
    my $attr = scalar( $self->_fold_case(shift) );
    if (@_) {    # set
        if ( defined $_[0] ) {
            my $old = $self->{$attr};
            $self->{$attr} = $_[0];
            return $old;
        }
        else {    # delete, actually
            return delete $self->{$attr};
        }
    }
    else {        # get
        return $self->{$attr};
    }
}

sub tag {
    my $self = shift;
    if (@_) {    # set
        $self->{'_tag'} = $self->_fold_case( $_[0] );
    }
    else {       # get
        $self->{'_tag'};
    }
}

sub parent {
    my $self = shift;
    if (@_) {    # set
        Carp::croak "an element can't be made its own parent"
            if defined $_[0] and ref $_[0] and $self eq $_[0];    # sanity
        $self->{'_parent'} = $_[0];
    }
    else {
        $self->{'_parent'};                                       # get
    }
}

sub content_list {
    return wantarray
        ? @{ shift->{'_content'} || return () }
        : scalar @{ shift->{'_content'} || return 0 };
}

# a read-only method!  can't say $h->content( [] )!
sub content {
    return shift->{'_content'};
}

sub content_array_ref {
    return shift->{'_content'} ||= [];
}

sub content_refs_list {
    return \( @{ shift->{'_content'} || return () } );
}

sub implicit {
    return shift->attr( '_implicit', @_ );
}

sub pos {
    my $self = shift;
    my $pos  = $self->{'_pos'};
    if (@_) {    # set
        my $parm = shift;
        if ( defined $parm and $parm ne $self ) {
            $self->{'_pos'} = $parm;    # means that element
        }
        else {
            $self->{'_pos'} = undef;    # means $self
        }
    }
    return $pos if defined($pos);
    return $self;
}

sub all_attr {
    return %{ $_[0] };

    # Yes, trivial.  But no other way for the user to do the same
    #  without breaking encapsulation.
    # And if our object representation changes, this method's behavior
    #  should stay the same.
}

sub all_attr_names {
    return keys %{ $_[0] };
}

sub all_external_attr {
    my $self = $_[0];
    return map( ( length($_) && substr( $_, 0, 1 ) eq '_' )
        ? ()
        : ( $_, $self->{$_} ),
        keys %$self );
}

sub all_external_attr_names {
    return grep !( length($_) && substr( $_, 0, 1 ) eq '_' ), keys %{ $_[0] };
}

sub id {
    if ( @_ == 1 ) {
        return $_[0]{'id'};
    }
    elsif ( @_ == 2 ) {
        if ( defined $_[1] ) {
            return $_[0]{'id'} = $_[1];
        }
        else {
            return delete $_[0]{'id'};
        }
    }
    else {
        Carp::croak '$node->id can\'t take ' . scalar(@_) . ' parameters!';
    }
}

sub _gensym {
    unless ( defined $ID_COUNTER ) {

        # start it out...
        $ID_COUNTER = sprintf( '%04x', rand(0x1000) );
        $ID_COUNTER =~ tr<0-9a-f><J-NP-Z>;    # yes, skip letter "oh"
        $ID_COUNTER .= '00000';
    }
    ++$ID_COUNTER;
}

sub idf {
    my $nparms = scalar @_;

    if ( $nparms == 1 ) {
        my $x;
        if ( defined( $x = $_[0]{'id'} ) and length $x ) {
            return $x;
        }
        else {
            return $_[0]{'id'} = _gensym();
        }
    }
    if ( $nparms == 2 ) {
        if ( defined $_[1] ) {
            return $_[0]{'id'} = $_[1];
        }
        else {
            return delete $_[0]{'id'};
        }
    }
    Carp::croak '$node->idf can\'t take ' . scalar(@_) . ' parameters!';
}

sub push_content {
    my $self = shift;
    return $self unless @_;

    my $content = ( $self->{'_content'} ||= [] );
    for (@_) {
        if ( ref($_) eq 'ARRAY' ) {

            # magically call new_from_lol
            push @$content, $self->new_from_lol($_);
            $content->[-1]->{'_parent'} = $self;
        }
        elsif ( ref($_) ) {    # insert an element
            $_->detach if $_->{'_parent'};
            $_->{'_parent'} = $self;
            push( @$content, $_ );
        }
        else {                 # insert text segment
            if ( @$content && !ref $content->[-1] ) {

                # last content element is also text segment -- append
                $content->[-1] .= $_;
            }
            else {
                push( @$content, $_ );
            }
        }
    }
    return $self;
}

sub unshift_content {
    my $self = shift;
    return $self unless @_;

    my $content = ( $self->{'_content'} ||= [] );
    for ( reverse @_ ) {    # so they get added in the order specified
        if ( ref($_) eq 'ARRAY' ) {

            # magically call new_from_lol
            unshift @$content, $self->new_from_lol($_);
            $content->[0]->{'_parent'} = $self;
        }
        elsif ( ref $_ ) {    # insert an element
            $_->detach if $_->{'_parent'};
            $_->{'_parent'} = $self;
            unshift( @$content, $_ );
        }
        else {                # insert text segment
            if ( @$content && !ref $content->[0] ) {

                # last content element is also text segment -- prepend
                $content->[0] = $_ . $content->[0];
            }
            else {
                unshift( @$content, $_ );
            }
        }
    }
    return $self;
}

# Cf.  splice ARRAY,OFFSET,LENGTH,LIST

sub splice_content {
    my ( $self, $offset, $length, @to_add ) = @_;
    Carp::croak "splice_content requires at least one argument"
        if @_ < 2;    # at least $h->splice_content($offset);
    return $self unless @_;

    my $content = ( $self->{'_content'} ||= [] );

    # prep the list

    my @out;
    if ( @_ > 2 ) {    # self, offset, length, ...
        foreach my $n (@to_add) {
            if ( ref($n) eq 'ARRAY' ) {
                $n = $self->new_from_lol($n);
                $n->{'_parent'} = $self;
            }
            elsif ( ref($n) ) {
                $n->detach;
                $n->{'_parent'} = $self;
            }
        }
        @out = splice @$content, $offset, $length, @to_add;
    }
    else {    #  self, offset
        @out = splice @$content, $offset;
    }
    foreach my $n (@out) {
        $n->{'_parent'} = undef if ref $n;
    }
    return @out;
}

sub detach {
    my $self = $_[0];
    return unless ( my $parent = $self->{'_parent'} );
    $self->{'_parent'} = undef;
    my $cohort = $parent->{'_content'} || return $parent;
    @$cohort = grep { not( ref($_) and $_ eq $self ) } @$cohort;

    # filter $self out, if parent has any evident content

    return $parent;
}

sub detach_content {
    my $c = $_[0]->{'_content'} || return ();    # in case of no content
    for (@$c) {
        $_->{'_parent'} = undef if ref $_;
    }
    return splice @$c;
}

sub replace_with {
    my ( $self, @replacers ) = @_;
    Carp::croak "the target node has no parent"
        unless my ($parent) = $self->{'_parent'};

    my $parent_content = $parent->{'_content'};
    Carp::croak "the target node's parent has no content!?"
        unless $parent_content and @$parent_content;

    my $replacers_contains_self;
    for (@replacers) {
        if ( !ref $_ ) {

            # noop
        }
        elsif ( $_ eq $self ) {

            # noop, but check that it's there just once.
            Carp::croak "Replacement list contains several copies of target!"
                if $replacers_contains_self++;
        }
        elsif ( $_ eq $parent ) {
            Carp::croak "Can't replace an item with its parent!";
        }
        elsif ( ref($_) eq 'ARRAY' ) {
            $_ = $self->new_from_lol($_);
            $_->{'_parent'} = $parent;
        }
        else {
            $_->detach;
            $_->{'_parent'} = $parent;

            # each of these are necessary
        }
    }    # for @replacers
    @$parent_content = map { ( ref($_) and $_ eq $self ) ? @replacers : $_ }
        @$parent_content;

    $self->{'_parent'} = undef unless $replacers_contains_self;

    # if replacers does contain self, then the parent attribute is fine as-is

    return $self;
}

sub preinsert {
    my $self = shift;
    return $self unless @_;
    return $self->replace_with( @_, $self );
}

sub postinsert {
    my $self = shift;
    return $self unless @_;
    return $self->replace_with( $self, @_ );
}

sub replace_with_content {
    my $self = $_[0];
    Carp::croak "the target node has no parent"
        unless my ($parent) = $self->{'_parent'};

    my $parent_content = $parent->{'_content'};
    Carp::croak "the target node's parent has no content!?"
        unless $parent_content and @$parent_content;

    my $content_r = $self->{'_content'} || [];
    @$parent_content = map { ( ref($_) and $_ eq $self ) ? @$content_r : $_ }
        @$parent_content;

    $self->{'_parent'} = undef;    # detach $self from its parent

    # Update parentage link, removing from $self's content list
    for ( splice @$content_r ) { $_->{'_parent'} = $parent if ref $_ }

    return $self;                  # note: doesn't destroy it.
}

sub delete_content {
    for (
        splice @{
            delete( $_[0]->{'_content'} )

                # Deleting it here (while holding its value, for the moment)
                #  will keep calls to detach() from trying to uselessly filter
                #  the list (as they won't be able to see it once it's been
                #  deleted)
                || return ( $_[0] )    # in case of no content
        },
        0

        # the splice is so we can null the array too, just in case
        # something somewhere holds a ref to it
        )
    {
        $_->delete if ref $_;
    }
    $_[0];
}

# two handy aliases
sub destroy         { shift->delete(@_) }
sub destroy_content { shift->delete_content(@_) }

sub delete {
    my $self = $_[0];
    $self->delete_content    # recurse down
        if $self->{'_content'} && @{ $self->{'_content'} };

    $self->detach if $self->{'_parent'} and $self->{'_parent'}{'_content'};

    # not the typical case

    %$self = ();             # null out the whole object on the way out
    return;
}

sub clone {

    #print "Cloning $_[0]\n";
    my $it = shift;
    Carp::croak "clone() can be called only as an object method"
        unless ref $it;
    Carp::croak "clone() takes no arguments" if @_;

    my $new = bless {%$it}, ref($it);    # COPY!!! HOOBOY!
    delete @$new{ '_content', '_parent', '_pos', '_head', '_body' };

    # clone any contents
    if ( $it->{'_content'} and @{ $it->{'_content'} } ) {
        $new->{'_content'}
            = [ ref($it)->clone_list( @{ $it->{'_content'} } ) ];
        for ( @{ $new->{'_content'} } ) {
            $_->{'_parent'} = $new if ref $_;
        }
    }

    return $new;
}

sub clone_list {
    Carp::croak "clone_list can be called only as a class method"
        if ref shift @_;

    # all that does is get me here
    return map {
        ref($_)
            ? $_->clone    # copy by method
            : $_           # copy by evaluation
    } @_;
}

sub normalize_content {
    my $start = $_[0];
    my $c;
    return
        unless $c = $start->{'_content'} and ref $c and @$c;   # nothing to do
        # TODO: if we start having text elements, deal with catenating those too?
    my @stretches = (undef);    # start with a barrier

    # I suppose this could be rewritten to treat stretches as it goes, instead
    #  of at the end.  But feh.

    # Scan:
    for ( my $i = 0; $i < @$c; ++$i ) {
        if ( defined $c->[$i] and ref $c->[$i] ) {    # not a text segment
            if ( $stretches[0] ) {

                # put in a barrier
                if ( $stretches[0][1] == 1 ) {

                    #print "Nixing stretch at ", $i-1, "\n";
                    undef $stretches[0]; # nix the previous one-node "stretch"
                }
                else {

                    #print "End of stretch at ", $i-1, "\n";
                    unshift @stretches, undef;
                }
            }

            # else no need for a barrier
        }
        else {                           # text segment
            $c->[$i] = '' unless defined $c->[$i];
            if ( $stretches[0] ) {
                ++$stretches[0][1];      # increase length
            }
            else {

                #print "New stretch at $i\n";
                unshift @stretches, [ $i, 1 ];    # start and length
            }
        }
    }

    # Now combine.  Note that @stretches is in reverse order, so the indexes
    # still make sense as we work our way thru (i.e., backwards thru $c).
    foreach my $s (@stretches) {
        if ( $s and $s->[1] > 1 ) {

            #print "Stretch at ", $s->[0], " for ", $s->[1], "\n";
            $c->[ $s->[0] ]
                .= join( '', splice( @$c, $s->[0] + 1, $s->[1] - 1 ) )

                # append the subsequent ones onto the first one.
        }
    }
    return;
}

sub delete_ignorable_whitespace {

    # This doesn't delete all sorts of whitespace that won't actually
    #  be used in rendering, tho -- that's up to the rendering application.
    # For example:
    #   <input type='text' name='foo'>
    #     [some whitespace]
    #   <input type='text' name='bar'>
    # The WS between the two elements /will/ get used by the renderer.
    # But here:
    #   <input type='hidden' name='foo' value='1'>
    #     [some whitespace]
    #   <input type='text' name='bar' value='2'>
    # the WS between them won't be rendered in any way, presumably.

    #my $Debug = 4;
    die "delete_ignorable_whitespace can be called only as an object method"
        unless ref $_[0];

    print "About to tighten up...\n" if $Debug > 2;
    my (@to_do) = ( $_[0] );    # Start off.
    my ( $i, $sibs, $ptag, $this );    # scratch for the loop...
    while (@to_do) {
        if (   ( $ptag = ( $this = shift @to_do )->{'_tag'} ) eq 'pre'
            or $ptag eq 'textarea'
            or $HTML::Tagset::isCDATA_Parent{$ptag} )
        {

            # block the traversal under those
            print "Blocking traversal under $ptag\n" if $Debug;
            next;
        }
        next unless ( $sibs = $this->{'_content'} and @$sibs );
        for ( $i = $#$sibs; $i >= 0; --$i ) {   # work backwards thru the list
            if ( ref $sibs->[$i] ) {
                unshift @to_do, $sibs->[$i];

                # yes, this happens in pre order -- we're going backwards
                # thru this sibling list.  I doubt it actually matters, tho.
                next;
            }
            next if $sibs->[$i] =~ m<[^\n\r\f\t ]>s;   # it's /all/ whitespace

            print "Under $ptag whose canTighten ",
                "value is ", 0 + $HTML::DOM::_Element::canTighten{$ptag}, ".\n"
                if $Debug > 3;

            # It's all whitespace...

            if ( $i == 0 ) {
                if ( @$sibs == 1 ) {                   # I'm an only child
                    next unless $HTML::DOM::_Element::canTighten{$ptag};    # parent
                }
                else {    # I'm leftmost of many
                          # if either my parent or sib are eligible, I'm good.
                    next
                        unless $HTML::DOM::_Element::canTighten{$ptag}    # parent
                            or (ref $sibs->[1]
                                and $HTML::DOM::_Element::canTighten{ $sibs->[1]
                                        {'_tag'} }    # right sib
                            );
                }
            }
            elsif ( $i == $#$sibs ) {                 # I'm rightmost of many
                    # if either my parent or sib are eligible, I'm good.
                next
                    unless $HTML::DOM::_Element::canTighten{$ptag}    # parent
                        or (ref $sibs->[ $i - 1 ]
                            and $HTML::DOM::_Element::canTighten{ $sibs->[ $i - 1 ]
                                    {'_tag'} }                  # left sib
                        );
            }
            else {    # I'm the piggy in the middle
                      # My parent doesn't matter -- it all depends on my sibs
                next
                    unless ref $sibs->[ $i - 1 ]
                        or ref $sibs->[ $i + 1 ];

                # if NEITHER sib is a node, quit

                next if

                    # bailout condition: if BOTH are INeligible nodes
                    #  (as opposed to being text, or being eligible nodes)
                    ref $sibs->[ $i - 1 ]
                        and ref $sibs->[ $i + 1 ]
                        and !$HTML::DOM::_Element::canTighten{ $sibs->[ $i - 1 ]
                                {'_tag'} }    # left sib
                        and !$HTML::DOM::_Element::canTighten{ $sibs->[ $i + 1 ]
                                {'_tag'} }    # right sib
                ;
            }

       # Unknown tags aren't in canTighten and so AREN'T subject to tightening

            print "  delendum: child $i of $ptag\n" if $Debug > 3;
            splice @$sibs, $i, 1;
        }

        # end of the loop-over-children
    }

    # end of the while loop.

    return;
}

sub insert_element {
    my ( $self, $tag, $implicit ) = @_;
    return $self->pos() unless $tag;    # noop if nothing to insert

    my $e;
    if ( ref $tag ) {
        $e   = $tag;
        $tag = $e->tag;
    }
    else {    # just a tag name -- so make the element
        $e = $self->element_class->new($tag);
        ++( $self->{'_element_count'} ) if exists $self->{'_element_count'};

        # undocumented.  see TreeBuilder.
    }

    $e->{'_implicit'} = 1 if $implicit;

    my $pos = $self->{'_pos'};
    $pos = $self unless defined $pos;

    $pos->push_content($e);

    $self->{'_pos'} = $pos = $e
        unless $self->_empty_element_map->{$tag} || $e->{'_empty_element'};

    $pos;
}

#==========================================================================
# Some things to override in XML::Element

sub _empty_element_map {
    \%HTML::DOM::_Element::emptyElement;
}

sub _fold_case_LC {
    if (wantarray) {
        shift;
        map lc($_), @_;
    }
    else {
        return lc( $_[1] );
    }
}

sub _fold_case_NOT {
    if (wantarray) {
        shift;
        @_;
    }
    else {
        return $_[1];
    }
}

*_fold_case = \&_fold_case_LC;

#==========================================================================

sub dump {
    my ( $self, $fh, $depth ) = @_;
    $fh    = *STDOUT{IO} unless defined $fh;
    $depth = 0           unless defined $depth;
    print $fh "  " x $depth, $self->starttag, " \@", $self->address,
        $self->{'_implicit'} ? " (IMPLICIT)\n" : "\n";
    for ( @{ $self->{'_content'} } ) {
        if ( ref $_ ) {    # element
            $_->dump( $fh, $depth + 1 );    # recurse
        }
        else {                              # text node
            print $fh "  " x ( $depth + 1 );
            if ( length($_) > 65 or m<[\x00-\x1F]> ) {

                # it needs prettyin' up somehow or other
                my $x
                    = ( length($_) <= 65 )
                    ? $_
                    : ( substr( $_, 0, 65 ) . '...' );
                $x =~ s<([\x00-\x1F])>
                     <'\\x'.(unpack("H2",$1))>eg;
                print $fh qq{"$x"\n};
            }
            else {
                print $fh qq{"$_"\n};
            }
        }
    }
}

sub as_HTML {
    my ( $self, $entities, $indent, $omissible_map ) = @_;

    #my $indent_on = defined($indent) && length($indent);
    my @html = ();

    $omissible_map ||= \%HTML::DOM::_Element::optionalEndTag;
    my $empty_element_map = $self->_empty_element_map;

    my $last_tag_tightenable    = 0;
    my $this_tag_tightenable    = 0;
    my $nonindentable_ancestors = 0;    # count of nonindentible tags over us.

    my ( $tag, $node, $start, $depth ); # per-iteration scratch

    if ( defined($indent) && length($indent) ) {
        $self->traverse(
            sub {
                ( $node, $start, $depth ) = @_;
                if ( ref $node ) {      # it's an element

                    # detect bogus classes. RT #35948, #61673
                    $node->can('starttag')
                        or Carp::confess( "Object of class "
                            . ref($node)
                            . " cannot be processed by HTML::DOM::_Element" );

                    $tag = $node->{'_tag'};

                    if ($start) {       # on the way in
                        if ((   $this_tag_tightenable
                                = $HTML::DOM::_Element::canTighten{$tag}
                            )
                            and !$nonindentable_ancestors
                            and $last_tag_tightenable
                            )
                        {
                            push
                                @html,
                                "\n",
                                $indent x $depth,
                                $node->starttag($entities),
                                ;
                        }
                        else {
                            push( @html, $node->starttag($entities) );
                        }
                        $last_tag_tightenable = $this_tag_tightenable;

                        ++$nonindentable_ancestors
                            if $tag eq 'pre'
                                or $HTML::Tagset::isCDATA_Parent{$tag};

                    }
                    elsif (
                        not(   $empty_element_map->{$tag}
                            or $omissible_map->{$tag} )
                        )
                    {

                        # on the way out
                        if (   $tag eq 'pre'
                            or $HTML::Tagset::isCDATA_Parent{$tag} )
                        {
                            --$nonindentable_ancestors;
                            $last_tag_tightenable
                                = $HTML::DOM::_Element::canTighten{$tag};
                            push @html, $node->endtag;

                        }
                        else {    # general case
                            if ((   $this_tag_tightenable
                                    = $HTML::DOM::_Element::canTighten{$tag}
                                )
                                and !$nonindentable_ancestors
                                and $last_tag_tightenable
                                )
                            {
                                push
                                    @html,
                                    "\n",
                                    $indent x $depth,
                                    $node->endtag,
                                    ;
                            }
                            else {
                                push @html, $node->endtag;
                            }
                            $last_tag_tightenable = $this_tag_tightenable;

                           #print "$tag tightenable: $this_tag_tightenable\n";
                        }
                    }
                }
                else {    # it's a text segment

                    $last_tag_tightenable = 0;    # I guess this is right
                    HTML::Entities::encode_entities( $node, $entities )

                        # That does magic things if $entities is undef.
                        unless (
                        ( defined($entities) && !length($entities) )

                        # If there's no entity to encode, don't call it
                        || $HTML::Tagset::isCDATA_Parent{ $_[3]{'_tag'} }

                        # To keep from amp-escaping children of script et al.
                        # That doesn't deal with descendants; but then, CDATA
                        #  parents shouldn't /have/ descendants other than a
                        #  text children (or comments?)
                        || $encoded_content
                        );
                    if ($nonindentable_ancestors) {
                        push @html, $node;    # say no go
                    }
                    else {
                        if ($last_tag_tightenable) {
                            $node =~ s<[\n\r\f\t ]+>< >s;

                            #$node =~ s< $><>s;
                            $node =~ s<^ ><>s;
                            push
                                @html,
                                "\n",
                                $indent x $depth,
                                $node,

           #Text::Wrap::wrap($indent x $depth, $indent x $depth, "\n" . $node)
                                ;
                        }
                        else {
                            push
                                @html,
                                $node,

                                #Text::Wrap::wrap('', $indent x $depth, $node)
                                ;
                        }
                    }
                }
                1;    # keep traversing
            }
        );            # End of parms to traverse()
    }
    else {            # no indenting -- much simpler code
        $self->traverse(
            sub {
                ( $node, $start ) = @_;
                if ( ref $node ) {


                    $tag = $node->{'_tag'};
                    if ($start) {    # on the way in
                        push( @html, $node->starttag($entities) );
                    }
                    elsif (
                        not(   $empty_element_map->{$tag}
                            or $omissible_map->{$tag} )
                        )
                    {

                        # on the way out
                        push( @html, $node->endtag );
                    }
                }
                else {

                    # simple text content
                    HTML::Entities::encode_entities( $node, $entities )

                        # That does magic things if $entities is undef.
                        unless (
                        ( defined($entities) && !length($entities) )

                        # If there's no entity to encode, don't call it
                        || $HTML::Tagset::isCDATA_Parent{ $_[3]{'_tag'} }

                        # To keep from amp-escaping children of script et al.
                        # That doesn't deal with descendants; but then, CDATA
                        #  parents shouldn't /have/ descendants other than a
                        #  text children (or comments?)
                        || $encoded_content
                        );
                    push( @html, $node );
                }
                1;    # keep traversing
            }
        );            # End of parms to traverse()
    }

    if ( $self->{_store_declarations} && defined $self->{_decl} ) {
        unshift @html, sprintf "<!%s>\n", $self->{_decl}->{text};
    }

    return join( '', @html );
}

sub as_text {

    # Yet another iteratively implemented traverser
    my ( $this, %options ) = @_;
    my $skip_dels = $options{'skip_dels'} || 0;
    my (@pile) = ($this);
    my $tag;
    my $text = '';
    while (@pile) {
        if ( !defined( $pile[0] ) ) {    # undef!
                                         # no-op
        }
        elsif ( !ref( $pile[0] ) ) {     # text bit!  save it!
            $text .= shift @pile;
        }
        else {                           # it's a ref -- traverse under it
            unshift @pile, @{ $this->{'_content'} || $nillio }
                unless ( $tag = ( $this = shift @pile )->{'_tag'} ) eq 'style'
                or $tag eq 'script'
                or ( $skip_dels and $tag eq 'del' );
        }
    }
    return $text;
}

# extra_chars added for RT #26436
sub as_trimmed_text {
    my ( $this, %options ) = @_;
    my $text = $this->as_text(%options);
    my $extra_chars = $options{'extra_chars'} || '';

    $text =~ s/[\n\r\f\t$extra_chars ]+$//s;
    $text =~ s/^[\n\r\f\t$extra_chars ]+//s;
    $text =~ s/[\n\r\f\t$extra_chars ]+/ /g;
    return $text;
}

sub as_text_trimmed { shift->as_trimmed_text(@_) }   # alias, because I forget

# TODO: make it wrap, if not indent?

sub as_XML {

    # based an as_HTML
    my ($self) = @_;

    #my $indent_on = defined($indent) && length($indent);
    my @xml               = ();
    my $empty_element_map = $self->_empty_element_map;

    my ( $tag, $node, $start );    # per-iteration scratch
    $self->traverse(
        sub {
            ( $node, $start ) = @_;
            if ( ref $node ) {     # it's an element
                $tag = $node->{'_tag'};
                if ($start) {      # on the way in

                    foreach my $attr ( $node->all_attr_names() ) {
                        Carp::croak(
                            "$tag has an invalid attribute name '$attr'")
                            unless ( $attr eq '/' || $self->_valid_name($attr) );
                    }

                    if ( $empty_element_map->{$tag}
                        and !@{ $node->{'_content'} || $nillio } )
                    {
                        push( @xml, $node->starttag_XML( undef, 1 ) );
                    }
                    else {
                        push( @xml, $node->starttag_XML(undef) );
                    }
                }
                else {    # on the way out
                    unless ( $empty_element_map->{$tag}
                        and !@{ $node->{'_content'} || $nillio } )
                    {
                        push( @xml, $node->endtag_XML() );
                    }     # otherwise it will have been an <... /> tag.
                }
            }
            else {        # it's just text
                _xml_escape($node);
                push( @xml, $node );
            }
            1;            # keep traversing
        }
    );

    join( '', @xml, "\n" );
}

sub _xml_escape {

# DESTRUCTIVE (a.k.a. "in-place")
# Five required escapes: http://www.w3.org/TR/2006/REC-xml11-20060816/#syntax
# We allow & if it's part of a valid escape already: http://www.w3.org/TR/2006/REC-xml11-20060816/#sec-references
    foreach my $x (@_) {

        # In strings with no encoded entities all & should be encoded.
        if ($encoded_content) {
            $x
                =~ s/&(?!                 # An ampersand that isn't followed by...
                (\#\d+; |                 # A hash mark, digits and semicolon, or
                \#x[\da-f]+; |            # A hash mark, "x", hex digits and semicolon, or
                $START_CHAR$NAME_CHAR+; ) # A valid unicode entity name and semicolon
           )/&amp;/gx;    # Needs to be escaped to amp
        }
        else {
            $x =~ s/&/&amp;/g;
        }

        # simple character escapes
        $x =~ s/</&lt;/g;
        $x =~ s/>/&gt;/g;
        $x =~ s/"/&quot;/g;
        $x =~ s/'/&apos;/g;
    }
    return;
}

# NOTES:
#
# It's been suggested that attribute names be made :-keywords:
#   (:_tag "img" :border 0 :src "pie.png" :usemap "#main.map")
# However, it seems that Scheme has no such data type as :-keywords.
# So, for the moment at least, I tend toward simplicity, uniformity,
#  and universality, where everything a string or a list.

sub as_Lisp_form {
    my @out;

    my $sub;
    my $depth = 0;
    my ( @list, $val );
    $sub = sub {    # Recursor
        my $self = $_[0];
        @list = ( '_tag', $self->{'_tag'} );
        @list = () unless defined $list[-1];    # unlikely

        for ( sort keys %$self ) {              # predictable ordering
            next
                if $_ eq '_content'
                    or $_ eq '_tag'
                    or $_ eq '_parent'
                    or $_ eq '/';

            # Leave the other private attributes, I guess.
            push @list, $_, $val
                if defined( $val = $self->{$_} );    # and !ref $val;
        }

        for (@list) {

            # octal-escape it
            s<([^\x20\x21\x23\x27-\x5B\x5D-\x7E])>
         <sprintf('\\%03o',ord($1))>eg;
            $_ = qq{"$_"};
        }
        push @out, ( '  ' x $depth ) . '(' . join ' ', splice @list;
        if ( @{ $self->{'_content'} || $nillio } ) {
            $out[-1] .= " \"_content\" (\n";
            ++$depth;
            foreach my $c ( @{ $self->{'_content'} } ) {
                if ( ref($c) ) {

                    # an element -- recurse
                    $sub->($c);
                }
                else {

                    # a text segment -- stick it in and octal-escape it
                    push @out, $c;
                    $out[-1] =~ s<([^\x20\x21\x23\x27-\x5B\x5D-\x7E])>
             <sprintf('\\%03o',ord($1))>eg;

                    # And quote and indent it.
                    $out[-1] .= "\"\n";
                    $out[-1] = ( '  ' x $depth ) . '"' . $out[-1];
                }
            }
            --$depth;
            substr( $out[-1], -1 )
                = "))\n";    # end of _content and of the element
        }
        else {
            $out[-1] .= ")\n";
        }
        return;
    };

    $sub->( $_[0] );
    undef $sub;
    return join '', @out;
}

sub format {
    my ( $self, $formatter ) = @_;
    unless ( defined $formatter ) {
        require HTML::FormatText;
        $formatter = HTML::FormatText->new();
    }
    $formatter->format($self);
}

sub starttag {
    my ( $self, $entities ) = @_;

    my $name = $self->{'_tag'};

    return $self->{'text'}              if $name eq '~literal';
    return "<!" . $self->{'text'} . ">" if $name eq '~declaration';
    return "<?" . $self->{'text'} . ">" if $name eq '~pi';

    if ( $name eq '~comment' ) {
        if ( ref( $self->{'text'} || '' ) eq 'ARRAY' ) {

            # Does this ever get used?  And is this right?
            return
                "<!"
                . join( ' ', map( "--$_--", @{ $self->{'text'} } ) ) . ">";
        }
        else {
            return "<!--" . $self->{'text'} . "-->";
        }
    }

    my $tag = $html_uc ? "<\U$name" : "<\L$name";
    my $val;
    for ( sort keys %$self ) {    # predictable ordering
        next if !length $_ or m/^_/s or $_ eq '/';
        $val = $self->{$_};
        next if !defined $val;    # or ref $val;
        if ($_ eq $val &&         # if attribute is boolean, for this element
            exists( $HTML::DOM::_Element::boolean_attr{$name} )
            && (ref( $HTML::DOM::_Element::boolean_attr{$name} )
                ? $HTML::DOM::_Element::boolean_attr{$name}{$_}
                : $HTML::DOM::_Element::boolean_attr{$name} eq $_
            )
            )
        {
            $tag .= $html_uc ? " \U$_" : " \L$_";
        }
        else {                    # non-boolean attribute

            if ( ref $val eq 'HTML::DOM::_Element'
                and $val->{_tag} eq '~literal' )
            {
                $val = $val->{text};
            }
            else {
                HTML::Entities::encode_entities( $val, $entities )
                    unless (
                    defined($entities) && !length($entities)
                    || $encoded_content

                    );
            }

            $val = qq{"$val"};
            $tag .= $html_uc ? qq{ \U$_\E=$val} : qq{ \L$_\E=$val};
        }
    }    # for keys
    if ( scalar $self->content_list == 0
        && $self->_empty_element_map->{ $self->tag } )
    {
        return $tag . " />";
    }
    else {
        return $tag . ">";
    }
}

sub starttag_XML {
    my ($self) = @_;

    # and a third parameter to signal emptiness?

    my $name = $self->{'_tag'};

    return $self->{'text'}               if $name eq '~literal';
    return '<!' . $self->{'text'} . '>'  if $name eq '~declaration';
    return "<?" . $self->{'text'} . "?>" if $name eq '~pi';

    if ( $name eq '~comment' ) {
        if ( ref( $self->{'text'} || '' ) eq 'ARRAY' ) {

            # Does this ever get used?  And is this right?
            $name = join( ' ', @{ $self->{'text'} } );
        }
        else {
            $name = $self->{'text'};
        }
        $name =~ s/--/-&#45;/g;    # can't have double --'s in XML comments
        return "<!-- $name -->";
    }

    my $tag = "<$name";
    my $val;
    for ( sort keys %$self ) {     # predictable ordering
        next if !length $_ or m/^_/s or $_ eq '/';

        # Hm -- what to do if val is undef?
        # I suppose that shouldn't ever happen.
        next if !defined( $val = $self->{$_} );    # or ref $val;
        _xml_escape($val);
        $tag .= qq{ $_="$val"};
    }
    @_ == 3 ? "$tag />" : "$tag>";
}

sub endtag {
    $html_uc ? "</\U$_[0]->{'_tag'}>" : "</\L$_[0]->{'_tag'}>";
}

# TODO: document?
sub endtag_XML {
    "</$_[0]->{'_tag'}>";
}

#==========================================================================
# This, ladies and germs, is an iterative implementation of a
# recursive algorithm.  DON'T TRY THIS AT HOME.
# Basically, the algorithm says:
#
# To traverse:
#   1: pre-order visit this node
#   2: traverse any children of this node
#   3: post-order visit this node, unless it's a text segment,
#       or a prototypically empty node (like "br", etc.)
# Add to that the consideration of the callbacks' return values,
# so you can block visitation of the children, or siblings, or
# abort the whole excursion, etc.
#
# So, why all this hassle with making the code iterative?
# It makes for real speed, because it eliminates the whole
# hassle of Perl having to allocate scratch space for each
# instance of the recursive sub.  Since the algorithm
# is basically simple (and not all recursive ones are!) and
# has few necessary lexicals (basically just the current node's
# content list, and the current position in it), it was relatively
# straightforward to store that information not as the frame
# of a sub, but as a stack, i.e., a simple Perl array (well, two
# of them, actually: one for content-listrefs, one for indexes of
# current position in each of those).

my $NIL = [];

sub traverse {
    my ( $start, $callback, $ignore_text ) = @_;

    Carp::croak "traverse can be called only as an object method"
        unless ref $start;

    Carp::croak('must provide a callback for traverse()!')
        unless defined $callback and ref $callback;

    # Elementary type-checking:
    my ( $c_pre, $c_post );
    if ( UNIVERSAL::isa( $callback, 'CODE' ) ) {
        $c_pre = $c_post = $callback;
    }
    elsif ( UNIVERSAL::isa( $callback, 'ARRAY' ) ) {
        ( $c_pre, $c_post ) = @$callback;
        Carp::croak(
            "pre-order callback \"$c_pre\" is true but not a coderef!")
            if $c_pre and not UNIVERSAL::isa( $c_pre, 'CODE' );
        Carp::croak(
            "pre-order callback \"$c_post\" is true but not a coderef!")
            if $c_post and not UNIVERSAL::isa( $c_post, 'CODE' );
        return $start unless $c_pre or $c_post;

        # otherwise there'd be nothing to actually do!
    }
    else {
        Carp::croak("$callback is not a known kind of reference")
            unless ref($callback);
    }

    my $empty_element_map = $start->_empty_element_map;

    my (@C) = [$start];    # a stack containing lists of children
    my (@I) = (-1);        # initial value must be -1 for each list
         # a stack of indexes to current position in corresponding lists in @C
         # In each of these, 0 is the active point

    # scratch:
    my ($rv,           # return value of callback
        $this,         # current node
        $content_r,    # child list of $this
    );

    # THE BIG LOOP
    while (@C) {

        # Move to next item in this frame
        if ( !defined( $I[0] ) or ++$I[0] >= @{ $C[0] } ) {

            # We either went off the end of this list, or aborted the list
            # So call the post-order callback:
            if (    $c_post
                and defined $I[0]
                and @C > 1

                # to keep the next line from autovivifying
                and defined( $this = $C[1][ $I[1] ] )    # sanity, and
                     # suppress callbacks on exiting the fictional top frame
                and ref($this)    # sanity
                and not(
                    $this->{'_empty_element'}
                    || ( $empty_element_map->{ $this->{'_tag'} || '' }
                        && !@{ $this->{'_content'} } )    # RT #49932
                )    # things that don't get post-order callbacks
                )
            {
                shift @I;
                shift @C;

                #print "Post! at depth", scalar(@I), "\n";
                $rv = $c_post->(

                    #map $_, # copy to avoid any messiness
                    $this,     # 0: this
                    0,         # 1: startflag (0 for post-order call)
                    @I - 1,    # 2: depth
                );

                if ( defined($rv) and ref($rv) eq $travsignal_package ) {
                    $rv = $$rv;    #deref
                    if ( $rv eq 'ABORT' ) {
                        last;      # end of this excursion!
                    }
                    elsif ( $rv eq 'PRUNE' ) {

                        # NOOP on post!!
                    }
                    elsif ( $rv eq 'PRUNE_SOFTLY' ) {

                        # NOOP on post!!
                    }
                    elsif ( $rv eq 'OK' ) {

                        # noop
                    }
                    elsif ( $rv eq 'PRUNE_UP' ) {
                        $I[0] = undef;
                    }
                    else {
                        die "Unknown travsignal $rv\n";

                        # should never happen
                    }
                }
            }
            else {
                shift @I;
                shift @C;
            }
            next;
        }

        $this = $C[0][ $I[0] ];

        if ($c_pre) {
            if ( defined $this and ref $this ) {    # element
                $rv = $c_pre->(

                    #map $_, # copy to avoid any messiness
                    $this,     # 0: this
                    1,         # 1: startflag (1 for pre-order call)
                    @I - 1,    # 2: depth
                );
            }
            else {             # text segment
                next if $ignore_text;
                $rv = $c_pre->(

                    #map $_, # copy to avoid any messiness
                    $this,           # 0: this
                    1,               # 1: startflag (1 for pre-order call)
                    @I - 1,          # 2: depth
                    $C[1][ $I[1] ],  # 3: parent
                                     # And there will always be a $C[1], since
                             #  we can't start traversing at a text node
                    $I[0]    # 4: index of self in parent's content list
                );
            }
            if ( not $rv ) {    # returned false.  Same as PRUNE.
                next;           # prune
            }
            elsif ( ref($rv) eq $travsignal_package ) {
                $rv = $$rv;     # deref
                if ( $rv eq 'ABORT' ) {
                    last;       # end of this excursion!
                }
                elsif ( $rv eq 'PRUNE' ) {
                    next;
                }
                elsif ( $rv eq 'PRUNE_SOFTLY' ) {
                    if (ref($this)
                        and not( $this->{'_empty_element'}
                            || $empty_element_map->{ $this->{'_tag'} || '' } )
                        )
                    {

             # push a dummy empty content list just to trigger a post callback
                        unshift @I, -1;
                        unshift @C, $NIL;
                    }
                    next;
                }
                elsif ( $rv eq 'OK' ) {

                    # noop
                }
                elsif ( $rv eq 'PRUNE_UP' ) {
                    $I[0] = undef;
                    next;

                    # equivalent of last'ing out of the current child list.

            # Used to have PRUNE_UP_SOFTLY and ABORT_SOFTLY here, but the code
            # for these was seriously upsetting, served no particularly clear
            # purpose, and could not, I think, be easily implemented with a
            # recursive routine.  All bad things!
                }
                else {
                    die "Unknown travsignal $rv\n";

                    # should never happen
                }
            }

            # else fall thru to meaning same as \'OK'.
        }

        # end of pre-order calling

        # Now queue up content list for the current element...
        if (ref $this
            and not(    # ...except for those which...
                not( $content_r = $this->{'_content'} and @$content_r )

                # ...have empty content lists...
                and $this->{'_empty_element'}
                || $empty_element_map->{ $this->{'_tag'} || '' }

                # ...and that don't get post-order callbacks
            )
            )
        {
            unshift @I, -1;
            unshift @C, $content_r || $NIL;

            #print $this->{'_tag'}, " ($this) adds content_r ", $C[0], "\n";
        }
    }
    return $start;
}

sub is_inside {
    my $self = shift;
    return unless @_;    # if no items specified, I guess this is right.

    my $current = $self;

    # the loop starts by looking at the given element
    while ( defined $current and ref $current ) {
        for (@_) {
            if (ref) {    # element
                return 1 if $_ eq $current;
            }
            else {        # tag name
                return 1 if $_ eq $current->{'_tag'};
            }
        }
        $current = $current->{'_parent'};
    }
    0;
}

sub is_empty {
    my $self = shift;
    !$self->{'_content'} || !@{ $self->{'_content'} };
}

sub pindex {
    my $self = shift;

    my $parent = $self->{'_parent'}    || return;
    my $pc     = $parent->{'_content'} || return;
    for ( my $i = 0; $i < @$pc; ++$i ) {
        return $i if ref $pc->[$i] and $pc->[$i] eq $self;
    }
    return;    # we shouldn't ever get here
}

#--------------------------------------------------------------------------

sub left {
    Carp::croak "left() is supposed to be an object method"
        unless ref $_[0];
    my $pc = ( $_[0]->{'_parent'} || return )->{'_content'}
        || die "parent is childless?";

    die "parent is childless" unless @$pc;
    return if @$pc == 1;    # I'm an only child

    if (wantarray) {
        my @out;
        foreach my $j (@$pc) {
            return @out if ref $j and $j eq $_[0];
            push @out, $j;
        }
    }
    else {
        for ( my $i = 0; $i < @$pc; ++$i ) {
            return $i ? $pc->[ $i - 1 ] : undef
                if ref $pc->[$i] and $pc->[$i] eq $_[0];
        }
    }

    die "I'm not in my parent's content list?";
    return;
}

sub right {
    Carp::croak "right() is supposed to be an object method"
        unless ref $_[0];
    my $pc = ( $_[0]->{'_parent'} || return )->{'_content'}
        || die "parent is childless?";

    die "parent is childless" unless @$pc;
    return if @$pc == 1;    # I'm an only child

    if (wantarray) {
        my ( @out, $seen );
        foreach my $j (@$pc) {
            if ($seen) {
                push @out, $j;
            }
            else {
                $seen = 1 if ref $j and $j eq $_[0];
            }
        }
        die "I'm not in my parent's content list?" unless $seen;
        return @out;
    }
    else {
        for ( my $i = 0; $i < @$pc; ++$i ) {
            return +( $i == $#$pc ) ? undef : $pc->[ $i + 1 ]
                if ref $pc->[$i] and $pc->[$i] eq $_[0];
        }
        die "I'm not in my parent's content list?";
        return;
    }
}

#--------------------------------------------------------------------------

sub address {
    if ( @_ == 1 ) {    # report-address form
        return join(
            '.',
            reverse(    # so it starts at the top
                map( $_->pindex() || '0',    # so that root's undef -> '0'
                    $_[0],                   # self and...
                    $_[0]->lineage )
            )
        );
    }
    else {                                   # get-node-at-address
        my @stack = split( /\./, $_[1] );
        my $here;

        if ( @stack and !length $stack[0] ) {    # relative addressing
            $here = $_[0];
            shift @stack;
        }
        else {                                   # absolute addressing
            return unless 0 == shift @stack;   # to pop the initial 0-for-root
            $here = $_[0]->root;
        }

        while (@stack) {
            return
                unless $here->{'_content'}
                    and @{ $here->{'_content'} } > $stack[0];

            # make sure the index isn't too high
            $here = $here->{'_content'}[ shift @stack ];
            return if @stack and not ref $here;

            # we hit a text node when we expected a non-terminal element node
        }

        return $here;
    }
}

sub depth {
    my $here  = $_[0];
    my $depth = 0;
    while ( defined( $here = $here->{'_parent'} ) and ref($here) ) {
        ++$depth;
    }
    return $depth;
}

sub root {
    my $here = my $root = shift;
    while ( defined( $here = $here->{'_parent'} ) and ref($here) ) {
        $root = $here;
    }
    return $root;
}

sub lineage {
    my $here = shift;
    my @lineage;
    while ( defined( $here = $here->{'_parent'} ) and ref($here) ) {
        push @lineage, $here;
    }
    return @lineage;
}

sub lineage_tag_names {
    my $here = my $start = shift;
    my @lineage_names;
    while ( defined( $here = $here->{'_parent'} ) and ref($here) ) {
        push @lineage_names, $here->{'_tag'};
    }
    return @lineage_names;
}

sub descendents { shift->descendants(@_) }

sub descendants {
    my $start = shift;
    if (wantarray) {
        my @descendants;
        $start->traverse(
            [    # pre-order sub only
                sub {
                    push( @descendants, $_[0] );
                    return 1;
                },
                undef    # no post
            ],
            1,           # ignore text
        );
        shift @descendants;    # so $self doesn't appear in the list
        return @descendants;
    }
    else {                     # just returns a scalar
        my $descendants = -1;    # to offset $self being counted
        $start->traverse(
            [                    # pre-order sub only
                sub {
                    ++$descendants;
                    return 1;
                },
                undef            # no post
            ],
            1,                   # ignore text
        );
        return $descendants;
    }
}

sub find { shift->find_by_tag_name(@_) }

# yup, a handy alias

sub find_by_tag_name {
    my (@pile) = shift(@_);    # start out the to-do stack for the traverser
    Carp::croak "find_by_tag_name can be called only as an object method"
        unless ref $pile[0];
    return () unless @_;
    my (@tags) = $pile[0]->_fold_case(@_);
    my ( @matching, $this, $this_tag );
    while (@pile) {
        $this_tag = ( $this = shift @pile )->{'_tag'};
        foreach my $t (@tags) {
            if ( $t eq $this_tag ) {
                if (wantarray) {
                    push @matching, $this;
                    last;
                }
                else {
                    return $this;
                }
            }
        }
        unshift @pile, grep ref($_), @{ $this->{'_content'} || next };
    }
    return @matching if wantarray;
    return;
}

sub find_by_attribute {

    # We could limit this to non-internal attributes, but hey.
    my ( $self, $attribute, $value ) = @_;
    Carp::croak "Attribute must be a defined value!"
        unless defined $attribute;
    $attribute = $self->_fold_case($attribute);

    my @matching;
    my $wantarray = wantarray;
    my $quit;
    $self->traverse(
        [    # pre-order only
            sub {
                if ( exists $_[0]{$attribute}
                    and $_[0]{$attribute} eq $value )
                {
                    push @matching, $_[0];
                    return HTML::DOM::_Element::ABORT
                        unless $wantarray;    # only take the first
                }
                1;                            # keep traversing
            },
            undef                             # no post
        ],
        1,                                    # yes, ignore text nodes.
    );

    if ($wantarray) {
        return @matching;
    }
    else {
        return unless @matching;
        return $matching[0];
    }
}

#--------------------------------------------------------------------------

sub look_down {
    ref( $_[0] ) or Carp::croak "look_down works only as an object method";

    my @criteria;
    for ( my $i = 1; $i < @_; ) {
        Carp::croak "Can't use undef as an attribute name"
            unless defined $_[$i];
        if ( ref $_[$i] ) {
            Carp::croak "A " . ref( $_[$i] ) . " value is not a criterion"
                unless ref $_[$i] eq 'CODE';
            push @criteria, $_[ $i++ ];
        }
        else {
            Carp::croak "param list to look_down ends in a key!" if $i == $#_;
            push @criteria, [
                scalar( $_[0]->_fold_case( $_[$i] ) ),
                defined( $_[ $i + 1 ] )
                ? ( ( ref $_[ $i + 1 ] ? $_[ $i + 1 ] : lc( $_[ $i + 1 ] ) ),
                    ref( $_[ $i + 1 ] )
                    )

                    # yes, leave that LC!
                : undef
            ];
            $i += 2;
        }
    }
    Carp::croak "No criteria?" unless @criteria;

    my (@pile) = ( $_[0] );
    my ( @matching, $val, $this );
Node:
    while ( defined( $this = shift @pile ) ) {

        # Yet another traverser implemented with merely iterative code.
        foreach my $c (@criteria) {
            if ( ref($c) eq 'CODE' ) {
                next Node unless $c->($this);    # jump to the continue block
            }
            else {                               # it's an attr-value pair
                next Node                        # jump to the continue block
                    if                           # two values are unequal if:
                        ( defined( $val = $this->{ $c->[0] } ) )
                    ? (     !defined $c->[ 1
                                ]    # actual is def, critval is undef => fail
                                     # allow regex matching
                                     # allow regex matching
                                or (
                                  $c->[2] eq 'Regexp'
                                ? $val !~ $c->[1]
                                : ( ref $val ne $c->[2]

                                        # have unequal ref values => fail
                                        or lc($val) ne lc( $c->[1] )

                                       # have unequal lc string values => fail
                                )
                                )
                        )
                    : (     defined $c->[1]
                        )    # actual is undef, critval is def => fail
            }
        }

        # We make it this far only if all the criteria passed.
        return $this unless wantarray;
        push @matching, $this;
    }
    continue {
        unshift @pile, grep ref($_), @{ $this->{'_content'} || $nillio };
    }
    return @matching if wantarray;
    return;
}

sub look_up {
    ref( $_[0] ) or Carp::croak "look_up works only as an object method";

    my @criteria;
    for ( my $i = 1; $i < @_; ) {
        Carp::croak "Can't use undef as an attribute name"
            unless defined $_[$i];
        if ( ref $_[$i] ) {
            Carp::croak "A " . ref( $_[$i] ) . " value is not a criterion"
                unless ref $_[$i] eq 'CODE';
            push @criteria, $_[ $i++ ];
        }
        else {
            Carp::croak "param list to look_up ends in a key!" if $i == $#_;
            push @criteria, [
                scalar( $_[0]->_fold_case( $_[$i] ) ),
                defined( $_[ $i + 1 ] )
                ? ( ( ref $_[ $i + 1 ] ? $_[ $i + 1 ] : lc( $_[ $i + 1 ] ) ),
                    ref( $_[ $i + 1 ] )
                    )
                : undef    # Yes, leave that LC!
            ];
            $i += 2;
        }
    }
    Carp::croak "No criteria?" unless @criteria;

    my ( @matching, $val );
    my $this = $_[0];
Node:
    while (1) {

       # You'll notice that the code here is almost the same as for look_down.
        foreach my $c (@criteria) {
            if ( ref($c) eq 'CODE' ) {
                next Node unless $c->($this);    # jump to the continue block
            }
            else {                               # it's an attr-value pair
                next Node                        # jump to the continue block
                    if                           # two values are unequal if:
                        ( defined( $val = $this->{ $c->[0] } ) )
                    ? (     !defined $c->[ 1
                                ]    # actual is def, critval is undef => fail
                                or (
                                  $c->[2] eq 'Regexp'
                                ? $val !~ $c->[1]
                                : ( ref $val ne $c->[2]

                                        # have unequal ref values => fail
                                        or lc($val) ne $c->[1]

                                       # have unequal lc string values => fail
                                )
                                )
                        )
                    : (     defined $c->[1]
                        )    # actual is undef, critval is def => fail
            }
        }

        # We make it this far only if all the criteria passed.
        return $this unless wantarray;
        push @matching, $this;
    }
    continue {
        last unless defined( $this = $this->{'_parent'} ) and ref $this;
    }

    return @matching if wantarray;
    return;
}

#--------------------------------------------------------------------------

sub attr_get_i {
    if ( @_ > 2 ) {
        my $self = shift;
        Carp::croak "No attribute names can be undef!"
            if grep !defined($_), @_;
        my @attributes = $self->_fold_case(@_);
        if (wantarray) {
            my @out;
            foreach my $x ( $self, $self->lineage ) {
                push @out,
                    map { exists( $x->{$_} ) ? $x->{$_} : () } @attributes;
            }
            return @out;
        }
        else {
            foreach my $x ( $self, $self->lineage ) {
                foreach my $attribute (@attributes) {
                    return $x->{$attribute}
                        if exists $x->{$attribute};    # found
                }
            }
            return;                                    # never found
        }
    }
    else {

        # Single-attribute search.  Simpler, most common, so optimize
        #  for the most common case
        Carp::croak "Attribute name must be a defined value!"
            unless defined $_[1];
        my $self      = $_[0];
        my $attribute = $self->_fold_case( $_[1] );
        if (wantarray) {                               # list context
            return
                map { exists( $_->{$attribute} ) ? $_->{$attribute} : () }
                $self, $self->lineage;
        }
        else {                                         # scalar context
            foreach my $x ( $self, $self->lineage ) {
                return $x->{$attribute} if exists $x->{$attribute};    # found
            }
            return;    # never found
        }
    }
}

sub tagname_map {
    my (@pile) = $_[0];    # start out the to-do stack for the traverser
    Carp::croak "find_by_tag_name can be called only as an object method"
        unless ref $pile[0];
    my ( %map, $this_tag, $this );
    while (@pile) {
        $this_tag = ''
            unless defined( $this_tag = ( $this = shift @pile )->{'_tag'} )
        ;    # dance around the strange case of having an undef tagname.
        push @{ $map{$this_tag} ||= [] }, $this;    # add to map
        unshift @pile, grep ref($_),
            @{ $this->{'_content'} || next };       # traverse
    }
    return \%map;
}

sub extract_links {
    my $start = shift;

    my %wantType;
    @wantType{ $start->_fold_case(@_) } = (1) x @_;    # if there were any
    my $wantType = scalar(@_);

    my @links;

    # TODO: add xml:link?

    my ( $link_attrs, $tag, $self, $val );    # scratch for each iteration
    $start->traverse(
        [   sub {                             # pre-order call only
                $self = $_[0];

                $tag = $self->{'_tag'};
                return 1
                    if $wantType && !$wantType{$tag};    # if we're selective

                if (defined(
                        $link_attrs = $HTML::DOM::_Element::linkElements{$tag}
                    )
                    )
                {

                    # If this is a tag that has any link attributes,
                    #  look over possibly present link attributes,
                    #  saving the value, if found.
                    for ( ref($link_attrs) ? @$link_attrs : $link_attrs ) {
                        if ( defined( $val = $self->attr($_) ) ) {
                            push( @links, [ $val, $self, $_, $tag ] );
                        }
                    }
                }
                1;    # return true, so we keep recursing
            },
            undef
        ],
        1,            # ignore text nodes
    );
    \@links;
}

sub simplify_pres {
    my $pre = 0;

    my $sub;
    my $line;
    $sub = sub {
        ++$pre if $_[0]->{'_tag'} eq 'pre';
        foreach my $it ( @{ $_[0]->{'_content'} || return } ) {
            if ( ref $it ) {
                $sub->($it);    # recurse!
            }
            elsif ($pre) {

                #$it =~ s/(?:(?:\cm\cj*)|(?:\cj))/\n/g;

                $it = join "\n", map {
                    ;
                    $line = $_;
                    while (
                        $line
                        =~ s/^([^\t]*)(\t+)/$1.(" " x ((length($2)<<3)-(length($1)&7)))/e

              # Sort of adapted from Text::Tabs -- yes, it's hardwired-in that
              # tabs are at every EIGHTH column.
                        )
                    {
                    }
                    $line;
                    }
                    split /(?:(?:\cm\cj*)|(?:\cj))/, $it, -1;
            }
        }
        --$pre if $_[0]->{'_tag'} eq 'pre';
        return;
    };
    $sub->( $_[0] );

    undef $sub;
    return;

}

sub same_as {
    die 'same_as() takes only one argument: $h->same_as($i)' unless @_ == 2;
    my ( $h, $i ) = @_[ 0, 1 ];
    die "same_as() can be called only as an object method" unless ref $h;

    return 0 unless defined $i and ref $i;

    # An element can't be same_as anything but another element!
    # They needn't be of the same class, tho.

    return 1 if $h eq $i;

    # special (if rare) case: anything is the same as... itself!

    # assumes that no content lists in/under $h or $i contain subsequent
    #  text segments, like: ['foo', ' bar']

    # compare attributes now.
    #print "Comparing tags of $h and $i...\n";

    return 0 unless $h->{'_tag'} eq $i->{'_tag'};

    # only significant attribute whose name starts with "_"

    #print "Comparing attributes of $h and $i...\n";
    # Compare attributes, but only the real ones.
    {

        # Bear in mind that the average element has very few attributes,
        #  and that element names are rather short.
        # (Values are a different story.)

    # XXX I would think that /^[^_]/ would be faster, at least easier to read.
        my @keys_h
            = sort grep { length $_ and substr( $_, 0, 1 ) ne '_' } keys %$h;
        my @keys_i
            = sort grep { length $_ and substr( $_, 0, 1 ) ne '_' } keys %$i;

        return 0 unless @keys_h == @keys_i;

        # different number of real attributes?  they're different.
        for ( my $x = 0; $x < @keys_h; ++$x ) {
            return 0
                unless $keys_h[$x] eq $keys_i[$x] and    # same key name
                    $h->{ $keys_h[$x] } eq $i->{ $keys_h[$x] };   # same value
             # Should this test for definedness on values?
             # People shouldn't be putting undef in attribute values, I think.
        }
    }

    #print "Comparing children of $h and $i...\n";
    my $hcl = $h->{'_content'} || [];
    my $icl = $i->{'_content'} || [];

    return 0 unless @$hcl == @$icl;

    # different numbers of children?  they're different.

    if (@$hcl) {

        # compare each of the children:
        for ( my $x = 0; $x < @$hcl; ++$x ) {
            if ( ref $hcl->[$x] ) {
                return 0 unless ref( $icl->[$x] );

                # an element can't be the same as a text segment
                # Both elements:
                return 0 unless $hcl->[$x]->same_as( $icl->[$x] );  # RECURSE!
            }
            else {
                return 0 if ref( $icl->[$x] );

                # a text segment can't be the same as an element
                # Both text segments:
                return 0 unless $hcl->[$x] eq $icl->[$x];
            }
        }
    }

    return 1;    # passed all the tests!
}

sub new_from_lol {
    my $class = shift;
    $class = ref($class) || $class;

  # calling as an object method is just the same as ref($h)->new_from_lol(...)
    my $lol = $_[1];

    my @ancestor_lols;

    # So we can make sure there's no cyclicities in this lol.
    # That would be perverse, but one never knows.
    my ( $sub, $k, $v, $node );    # last three are scratch values
    $sub = sub {

        #print "Building for $_[0]\n";
        my $lol = $_[0];
        return unless @$lol;
        my ( @attributes, @children );
        Carp::croak "Cyclicity detected in source LOL tree, around $lol?!?"
            if grep( $_ eq $lol, @ancestor_lols );
        push @ancestor_lols, $lol;

        my $tag_name = 'null';

        # Recursion in in here:
        for ( my $i = 0; $i < @$lol; ++$i ) {    # Iterate over children
            if ( ref( $lol->[$i] ) eq 'ARRAY' )
            {    # subtree: most common thing in loltree
                push @children, $sub->( $lol->[$i] );
            }
            elsif ( !ref( $lol->[$i] ) ) {
                if ( $i == 0 ) {    # name
                    $tag_name = $lol->[$i];
                    Carp::croak "\"$tag_name\" isn't a good tag name!"
                        if $tag_name =~ m/[<>\/\x00-\x20]/
                    ;               # minimal sanity, certainly!
                }
                else {              # text segment child
                    push @children, $lol->[$i];
                }
            }
            elsif ( ref( $lol->[$i] ) eq 'HASH' ) {    # attribute hashref
                keys %{ $lol->[$i] };   # reset the each-counter, just in case
                while ( ( $k, $v ) = each %{ $lol->[$i] } ) {
                    push @attributes, $class->_fold_case($k), $v
                        if defined $v
                            and $k ne '_name'
                            and $k ne '_content'
                            and $k ne '_parent';

                    # enforce /some/ sanity!
                }
            }
            elsif ( UNIVERSAL::isa( $lol->[$i], __PACKAGE__ ) ) {
                if ( $lol->[$i]->{'_parent'} ) {    # if claimed
                        #print "About to clone ", $lol->[$i], "\n";
                    push @children, $lol->[$i]->clone();
                }
                else {
                    push @children, $lol->[$i];    # if unclaimed...
                         #print "Claiming ", $lol->[$i], "\n";
                    $lol->[$i]->{'_parent'} = 1;    # claim it NOW
                      # This WILL be replaced by the correct value once we actually
                      #  construct the parent, just after the end of this loop...
                }
            }
            else {
                Carp::croak "new_from_lol doesn't handle references of type "
                    . ref( $lol->[$i] );
            }
        }

        pop @ancestor_lols;
        $node = $class->new($tag_name);

        #print "Children: @children\n";

        if ( $class eq __PACKAGE__ ) {    # Special-case it, for speed:
            %$node = ( %$node, @attributes ) if @attributes;

            #print join(' ', $node, ' ' , map("<$_>", %$node), "\n");
            if (@children) {
                $node->{'_content'} = \@children;
                foreach my $c (@children) {
                    $c->{'_parent'} = $node
                        if ref $c;
                }
            }
        }
        else {                            # Do it the clean way...
                                          #print "Done neatly\n";
            while (@attributes) { $node->attr( splice @attributes, 0, 2 ) }
            $node->push_content( map { $_->{'_parent'} = $node if ref $_; $_ }
                    @children )
                if @children;
        }

        return $node;
    };

    # End of sub definition.

    if (wantarray) {
        my (@nodes) = map { ; ( ref($_) eq 'ARRAY' ) ? $sub->($_) : $_ } @_;

        # Let text bits pass thru, I guess.  This makes this act more like
        #  unshift_content et al.  Undocumented.
        undef $sub;

        # so it won't be in its own frame, so its refcount can hit 0
        return @nodes;
    }
    else {
        Carp::croak "new_from_lol in scalar context needs exactly one lol"
            unless @_ == 1;
        return $_[0] unless ref( $_[0] ) eq 'ARRAY';

        # used to be a fatal error.  still undocumented tho.
        $node = $sub->( $_[0] );
        undef $sub;

        # so it won't be in its own frame, so its refcount can hit 0
        return $node;
    }
}

sub objectify_text {
    my (@stack) = ( $_[0] );

    my ($this);
    while (@stack) {
        foreach my $c ( @{ ( $this = shift @stack )->{'_content'} } ) {
            if ( ref($c) ) {
                unshift @stack, $c;    # visit it later.
            }
            else {
                $c = $this->element_class->new(
                    '~text',
                    'text'    => $c,
                    '_parent' => $this
                );
            }
        }
    }
    return;
}

sub deobjectify_text {
    my (@stack) = ( $_[0] );
    my ($old_node);

    if ( $_[0]{'_tag'} eq '~text' ) {    # special case
            # Puts the $old_node variable to a different purpose
        if ( $_[0]{'_parent'} ) {
            $_[0]->replace_with( $old_node = delete $_[0]{'text'} )->delete;
        }
        else {    # well, that's that, then!
            $old_node = delete $_[0]{'text'};
        }

        if ( ref( $_[0] ) eq __PACKAGE__ ) {    # common case
            %{ $_[0] } = ();                    # poof!
        }
        else {

            # play nice:
            delete $_[0]{'_parent'};
            $_[0]->delete;
        }
        return '' unless defined $old_node;     # sanity!
        return $old_node;
    }

    while (@stack) {
        foreach my $c ( @{ ( shift @stack )->{'_content'} } ) {
            if ( ref($c) ) {
                if ( $c->{'_tag'} eq '~text' ) {
                    $c = ( $old_node = $c )->{'text'};
                    if ( ref($old_node) eq __PACKAGE__ ) {    # common case
                        %$old_node = ();                      # poof!
                    }
                    else {

                        # play nice:
                        delete $old_node->{'_parent'};
                        $old_node->delete;
                    }
                }
                else {
                    unshift @stack, $c;    # visit it later.
                }
            }
        }
    }

    return;
}

{

    # The next three subs are basically copied from Number::Latin,
    # based on a one-liner by Abigail.  Yes, I could simply require that
    # module, and a Roman numeral module too, but really, HTML-Tree already
    # has enough dependecies as it is; and anyhow, I don't need the functions
    # that do latin2int or roman2int.
    no integer;

    sub _int2latin {
        return unless defined $_[0];
        return '0' if $_[0] < 1 and $_[0] > -1;
        return '-' . _i2l( abs int $_[0] )
            if $_[0] <= -1;    # tolerate negatives
        return _i2l( int $_[0] );
    }

    sub _int2LATIN {

        # just the above plus uc
        return unless defined $_[0];
        return '0' if $_[0] < 1 and $_[0] > -1;
        return '-' . uc( _i2l( abs int $_[0] ) )
            if $_[0] <= -1;    # tolerate negs
        return uc( _i2l( int $_[0] ) );
    }

    my @alpha = ( 'a' .. 'z' );

    sub _i2l {                 # the real work
        my $int = $_[0] || return "";
        _i2l( int( ( $int - 1 ) / 26 ) )
            . $alpha[ $int % 26 - 1 ];    # yes, recursive
            # Yes, 26 => is (26 % 26 - 1), which is -1 => Z!
    }
}

{

    # And now, some much less impressive Roman numerals code:

    my (@i) = ( '', qw(I II III IV V VI VII VIII IX) );
    my (@x) = ( '', qw(X XX XXX XL L LX LXX LXXX XC) );
    my (@c) = ( '', qw(C CC CCC CD D DC DCC DCCC CM) );
    my (@m) = ( '', qw(M MM MMM) );

    sub _int2ROMAN {
        my ( $i, $pref );
        return '0'
            if 0 == ( $i = int( $_[0] || 0 ) );    # zero is a special case
        return $i + 0 if $i <= -4000 or $i >= 4000;

       # Because over 3999 would require non-ASCII chars, like D-with-)-inside
        if ( $i < 0 ) {    # grumble grumble tolerate negatives grumble
            $pref = '-';
            $i    = abs($i);
        }
        else {
            $pref = '';    # normal case
        }

        my ( $x, $c, $m ) = ( 0, 0, 0 );
        if ( $i >= 10 ) {
            $x = $i / 10;
            $i %= 10;
            if ( $x >= 10 ) {
                $c = $x / 10;
                $x %= 10;
                if ( $c >= 10 ) { $m = $c / 10; $c %= 10; }
            }
        }

        #print "m$m c$c x$x i$i\n";

        return join( '', $pref, $m[$m], $c[$c], $x[$x], $i[$i] );
    }

    sub _int2roman { lc( _int2ROMAN( $_[0] ) ) }
}

sub _int2int { $_[0] }    # dummy

%list_type_to_sub = (
    'I' => \&_int2ROMAN,
    'i' => \&_int2roman,
    'A' => \&_int2LATIN,
    'a' => \&_int2latin,
    '1' => \&_int2int,
);

sub number_lists {
    my (@stack) = ( $_[0] );
    my ( $this, $tag, $counter, $numberer );    # scratch
    while (@stack) {    # yup, pre-order-traverser idiom
        if ( ( $tag = ( $this = shift @stack )->{'_tag'} ) eq 'ol' ) {

            # Prep some things:
            $counter
                = ( ( $this->{'start'} || '' ) =~ m<^\s*(\d{1,7})\s*$>s )
                ? $1
                : 1;
            $numberer = $list_type_to_sub{ $this->{'type'} || '' }
                || $list_type_to_sub{'1'};

            # Immeditately iterate over all children
            foreach my $c ( @{ $this->{'_content'} || next } ) {
                next unless ref $c;
                unshift @stack, $c;
                if ( $c->{'_tag'} eq 'li' ) {
                    $counter = $1
                        if (
                        ( $c->{'value'} || '' ) =~ m<^\s*(\d{1,7})\s*$>s );
                    $c->{'_bullet'} = $numberer->($counter) . '.';
                    ++$counter;
                }
            }

        }
        elsif ( $tag eq 'ul' or $tag eq 'dir' or $tag eq 'menu' ) {

            # Immeditately iterate over all children
            foreach my $c ( @{ $this->{'_content'} || next } ) {
                next unless ref $c;
                unshift @stack, $c;
                $c->{'_bullet'} = '*' if $c->{'_tag'} eq 'li';
            }

        }
        else {
            foreach my $c ( @{ $this->{'_content'} || next } ) {
                unshift @stack, $c if ref $c;
            }
        }
    }
    return;
}

sub has_insane_linkage {
    my @pile = ( $_[0] );
    my ( $c, $i, $p, $this );    # scratch

    # Another iterative traverser; this time much simpler because
    #  only in pre-order:
    my %parent_of = ( $_[0], 'TOP-OF-SCAN' );
    while (@pile) {
        $this = shift @pile;
        $c = $this->{'_content'} || next;
        return ( $this, "_content attribute is true but nonref." )
            unless ref($c) eq 'ARRAY';
        next unless @$c;
        for ( $i = 0; $i < @$c; ++$i ) {
            return ( $this, "Child $i is undef" )
                unless defined $c->[$i];
            if ( ref( $c->[$i] ) ) {
                return ( $c->[$i], "appears in its own content list" )
                    if $c->[$i] eq $this;
                return ( $c->[$i],
                    "appears twice in the tree: once under $this, once under $parent_of{$c->[$i]}"
                ) if exists $parent_of{ $c->[$i] };
                $parent_of{ $c->[$i] } = '' . $this;

                # might as well just use the stringification of it.

                return ( $c->[$i],
                    "_parent attribute is wrong (not defined)" )
                    unless defined( $p = $c->[$i]{'_parent'} );
                return ( $c->[$i], "_parent attribute is wrong (nonref)" )
                    unless ref($p);
                return ( $c->[$i],
                    "_parent attribute is wrong (is $p; should be $this)" )
                    unless $p eq $this;
            }
        }
        unshift @pile, grep ref($_), @$c;

        # queue up more things on the pile stack
    }
    return;    #okay
}

sub _asserts_fail {    # to be run on trusted documents only
    my (@pile) = ( $_[0] );
    my ( @errors, $this, $id, $assert, $parent, $rv );
    while (@pile) {
        $this = shift @pile;
        if ( defined( $assert = $this->{'assert'} ) ) {
            $id = ( $this->{'id'} ||= $this->address )
                ;      # don't use '0' as an ID, okay?
            unless ( ref($assert) ) {

                package main;
## no critic
                $assert = $this->{'assert'} = (
                    $assert =~ m/\bsub\b/
                    ? eval($assert)
                    : eval("sub {  $assert\n}")
                );
## use critic
                if ($@) {
                    push @errors,
                        [ $this, "assertion at $id broke in eval: $@" ];
                    $assert = $this->{'assert'} = sub { };
                }
            }
            $parent = $this->{'_parent'};
            $rv     = undef;
            eval {
                $rv = $assert->(
                    $this, $this->{'_tag'}, $this->{'_id'},    # 0,1,2
                    $parent
                    ? ( $parent, $parent->{'_tag'}, $parent->{'id'} )
                    : ()                                       # 3,4,5
                );
            };
            if ($@) {
                push @errors, [ $this, "assertion at $id died: $@" ];
            }
            elsif ( !$rv ) {
                push @errors, [ $this, "assertion at $id failed" ];
            }

            # else OK
        }
        push @pile, grep ref($_), @{ $this->{'_content'} || next };
    }
    return @errors;
}

## _valid_name
#  validate XML style attribute names
#  http://www.w3.org/TR/2006/REC-xml11-20060816/#NT-Name

sub _valid_name {
    my $self = shift;
    my $attr = shift
        or Carp::croak("sub valid_name requires an attribute name");

    return (0) unless ( $attr =~ /^$START_CHAR$NAME_CHAR+$/ );

    return (1);
}

sub element_class {
    $_[0]->{_element_class} || __PACKAGE__;
}

1;

1;
