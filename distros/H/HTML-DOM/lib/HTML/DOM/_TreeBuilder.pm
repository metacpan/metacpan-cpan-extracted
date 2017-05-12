# This is a fork of HTML::Element.  Eventually the code may be merged.

package HTML::DOM::_TreeBuilder;

use warnings;
use strict;
use integer;    # vroom vroom!
use Carp ();
use vars qw(@ISA $VERSION $DEBUG);

#---------------------------------------------------------------------------
# Make a 'DEBUG' constant...

BEGIN {

    # We used to have things like
    #  print $indent, "lalala" if $Debug;
    # But there were an awful lot of having to evaluate $Debug's value.
    # If we make that depend on a constant, like so:
    #   sub DEBUG () { 1 } # or whatever value.
    #   ...
    #   print $indent, "lalala" if DEBUG;
    # Which at compile-time (thru the miracle of constant folding) turns into:
    #   print $indent, "lalala";
    # or, if DEBUG is a constant with a true value, then that print statement
    # is simply optimized away, and doesn't appear in the target code at all.
    # If you don't believe me, run:
    #    perl -MO=Deparse,-uHTML::DOM::_TreeBuilder -e 'BEGIN { \
    #      $HTML::DOM::_TreeBuilder::DEBUG = 4}  use HTML::DOM::_TreeBuilder'
    # and see for yourself (substituting whatever value you want for $DEBUG
    # there).
## no critic
    if ( defined &DEBUG ) {

        # Already been defined!  Do nothing.
    }
    elsif ( $] < 5.00404 ) {

        # Grudgingly accomodate ancient (pre-constant) versions.
        eval 'sub DEBUG { $Debug } ';
    }
    elsif ( !$DEBUG ) {
        eval 'sub DEBUG () {0}';    # Make it a constant.
    }
    elsif ( $DEBUG =~ m<^\d+$>s ) {
        eval 'sub DEBUG () { ' . $DEBUG . ' }';    # Make THAT a constant.
    }
    else {                                         # WTF?
        warn "Non-numeric value \"$DEBUG\" in \$HTML::DOM::_Element::DEBUG";
        eval 'sub DEBUG () { $DEBUG }';            # I guess.
    }
## use critic
}

#---------------------------------------------------------------------------

use HTML::Entities ();
use HTML::Tagset 3.02 ();

use HTML::DOM::_Element ();
use HTML::Parser  ();
@ISA = qw(HTML::DOM::_Element HTML::Parser);
$VERSION = 4.2001;

# This looks schizoid, I know.
# It's not that we ARE an element AND a parser.
# We ARE an element, but one that knows how to handle signals
#  (method calls) from Parser in order to elaborate its subtree.

# Legacy aliases:
*HTML::DOM::_TreeBuilder::isKnown             = \%HTML::Tagset::isKnown;
*HTML::DOM::_TreeBuilder::canTighten          = \%HTML::Tagset::canTighten;
*HTML::DOM::_TreeBuilder::isHeadElement       = \%HTML::Tagset::isHeadElement;
*HTML::DOM::_TreeBuilder::isBodyElement       = \%HTML::Tagset::isBodyElement;
*HTML::DOM::_TreeBuilder::isPhraseMarkup      = \%HTML::Tagset::isPhraseMarkup;
*HTML::DOM::_TreeBuilder::isHeadOrBodyElement = \%HTML::Tagset::isHeadOrBodyElement;
*HTML::DOM::_TreeBuilder::isList              = \%HTML::Tagset::isList;
*HTML::DOM::_TreeBuilder::isTableElement      = \%HTML::Tagset::isTableElement;
*HTML::DOM::_TreeBuilder::isFormElement       = \%HTML::Tagset::isFormElement;
*HTML::DOM::_TreeBuilder::p_closure_barriers  = \@HTML::Tagset::p_closure_barriers;

#==========================================================================
# Two little shortcut constructors:

sub new_from_file {    # or from a FH
    my $class = shift;
    Carp::croak("new_from_file takes only one argument")
        unless @_ == 1;
    Carp::croak("new_from_file is a class method only")
        if ref $class;
    my $new = $class->new();
    $new->parse_file( $_[0] );
    return $new;
}

sub new_from_content {    # from any number of scalars
    my $class = shift;
    Carp::croak("new_from_content is a class method only")
        if ref $class;
    my $new = $class->new();
    foreach my $whunk (@_) {
        if ( ref($whunk) eq 'SCALAR' ) {
            $new->parse($$whunk);
        }
        else {
            $new->parse($whunk);
        }
        last if $new->{'_stunted'};    # might as well check that.
    }
    $new->eof();
    return $new;
}

# TODO: document more fully?
sub parse_content {                    # from any number of scalars
    my $tree = shift;
    my $retval;
    foreach my $whunk (@_) {
        if ( ref($whunk) eq 'SCALAR' ) {
            $retval = $tree->parse($$whunk);
        }
        else {
            $retval = $tree->parse($whunk);
        }
        last if $tree->{'_stunted'};    # might as well check that.
    }
    $tree->eof();
    return $retval;
}

#---------------------------------------------------------------------------

sub new {                               # constructor!
    my $class = shift;
    $class = ref($class) || $class;

    # Initialize HTML::DOM::_Element part
    my $self = $class->element_class->new('html');

    {

        # A hack for certain strange versions of Parser:
        my $other_self = HTML::Parser->new();
        %$self = ( %$self, %$other_self );    # copy fields
           # Yes, multiple inheritance is messy.  Kids, don't try this at home.
        bless $other_self, "HTML::DOM::_TreeBuilder::_hideyhole";

        # whack it out of the HTML::Parser class, to avoid the destructor
    }

    # The root of the tree is special, as it has these funny attributes,
    # and gets reblessed into this class.

    # Initialize parser settings
    $self->{'_implicit_tags'}       = 1;
    $self->{'_implicit_body_p_tag'} = 0;

    # If true, trying to insert text, or any of %isPhraseMarkup right
    #  under 'body' will implicate a 'p'.  If false, will just go there.

    $self->{'_tighten'} = 1;

    # whether ignorable WS in this tree should be deleted

    $self->{'_implicit'} = 1; # to delete, once we find a real open-"html" tag

    $self->{'_ignore_unknown'}      = 1;
    $self->{'_ignore_text'}         = 0;
    $self->{'_warn'}                = 0;
    $self->{'_no_space_compacting'} = 0;
    $self->{'_store_comments'}      = 0;
    $self->{'_store_declarations'}  = 1;
    $self->{'_store_pis'}           = 0;
    $self->{'_p_strict'}            = 0;
    $self->{'_no_expand_entities'}  = 0;

    # Parse attributes passed in as arguments
    if (@_) {
        my %attr = @_;
        for ( keys %attr ) {
            $self->{"_$_"} = $attr{$_};
        }
    }

    $HTML::DOM::_Element::encoded_content = $self->{'_no_expand_entities'};

    # rebless to our class
    bless $self, $class;

    $self->{'_element_count'} = 1;

    # undocumented, informal, and maybe not exactly correct

    $self->{'_head'} = $self->insert_element( 'head', 1 );
    $self->{'_pos'}  = undef;                                # pull it back up
    $self->{'_body'} = $self->insert_element( 'body', 1 );
    $self->{'_pos'} = undef;    # pull it back up again

    return $self;
}

#==========================================================================

sub _elem                       # universal accessor...
{
    my ( $self, $elem, $val ) = @_;
    my $old = $self->{$elem};
    $self->{$elem} = $val if defined $val;
    return $old;
}

# accessors....
sub implicit_tags       { shift->_elem( '_implicit_tags',       @_ ); }
sub implicit_body_p_tag { shift->_elem( '_implicit_body_p_tag', @_ ); }
sub p_strict            { shift->_elem( '_p_strict',            @_ ); }
sub no_space_compacting { shift->_elem( '_no_space_compacting', @_ ); }
sub ignore_unknown      { shift->_elem( '_ignore_unknown',      @_ ); }
sub ignore_text         { shift->_elem( '_ignore_text',         @_ ); }
sub ignore_ignorable_whitespace { shift->_elem( '_tighten',            @_ ); }
sub store_comments              { shift->_elem( '_store_comments',     @_ ); }
sub store_declarations          { shift->_elem( '_store_declarations', @_ ); }
sub store_pis                   { shift->_elem( '_store_pis',          @_ ); }
sub warn                        { shift->_elem( '_warn',               @_ ); }

sub no_expand_entities {
    shift->_elem( '_no_expand_entities', @_ );
    $HTML::DOM::_Element::encoded_content = @_;
}

#==========================================================================

sub warning {
    my $self = shift;
    CORE::warn("HTML::Parse: $_[0]\n") if $self->{'_warn'};

    # should maybe say HTML::DOM::_TreeBuilder instead
}

#==========================================================================

{

    # To avoid having to rebuild these lists constantly...
    my $_Closed_by_structurals = [qw(p h1 h2 h3 h4 h5 h6 pre textarea)];
    my $indent;

    sub start {
        return if $_[0]{'_stunted'};

        # Accept a signal from HTML::Parser for start-tags.
        my ( $self, $tag, $attr ) = @_;

        # Parser passes more, actually:
        #   $self->start($tag, $attr, $attrseq, $origtext)
        # But we can merrily ignore $attrseq and $origtext.

        if ( $tag eq 'x-html' ) {
            print "Ignoring open-x-html tag.\n" if DEBUG;

            # inserted by some lame code-generators.
            return;    # bypass tweaking.
        }

        $tag =~ s{/$}{}s;    # So <b/> turns into <b>.  Silently forgive.

        unless ( $tag =~ m/^[-_a-zA-Z0-9:%]+$/s ) {
            DEBUG and print "Start-tag name $tag is no good.  Skipping.\n";
            return;

            # This avoids having Element's new() throw an exception.
        }

        my $ptag = ( my $pos = $self->{'_pos'} || $self )->{'_tag'};
        my $already_inserted;

        #my($indent);
        if (DEBUG) {

       # optimization -- don't figure out indenting unless we're in debug mode
            my @lineage = $pos->lineage;
            $indent = '  ' x ( 1 + @lineage );
            print $indent, "Proposing a new \U$tag\E under ",
                join( '/', map $_->{'_tag'}, reverse( $pos, @lineage ) )
                || 'Root',
                ".\n";

            #} else {
            #  $indent = ' ';
        }

        #print $indent, "POS: $pos ($ptag)\n" if DEBUG > 2;
        # $attr = {%$attr};

        foreach my $k ( keys %$attr ) {

            # Make sure some stooge doesn't have "<span _content='pie'>".
            # That happens every few million Web pages.
            $attr->{ ' ' . $k } = delete $attr->{$k}
                if length $k and substr( $k, 0, 1 ) eq '_';

            # Looks bad, but is fine for round-tripping.
        }

        my $e = $self->element_class->new( $tag, %$attr );

        # Make a new element object.
        # (Only rarely do we end up just throwing it away later in this call.)

      # Some prep -- custom messiness for those damned tables, and strict P's.
        if ( $self->{'_implicit_tags'} ) {    # wallawallawalla!

            unless ( $HTML::DOM::_TreeBuilder::isTableElement{$tag} ) {
                if ( $ptag eq 'table' ) {
                    print $indent,
                        " * Phrasal \U$tag\E right under TABLE makes implicit TR and TD\n"
                        if DEBUG > 1;
                    $self->insert_element( 'tr', 1 );
                    $pos = $self->insert_element( 'td', 1 )
                        ;                     # yes, needs updating
                }
                elsif ( $ptag eq 'tr' ) {
                    print $indent,
                        " * Phrasal \U$tag\E right under TR makes an implicit TD\n"
                        if DEBUG > 1;
                    $pos = $self->insert_element( 'td', 1 )
                        ;                     # yes, needs updating
                }
                $ptag = $pos->{'_tag'};       # yes, needs updating
            }

            # end of table-implication block.

            # Now maybe do a little dance to enforce P-strictness.
            # This seems like it should be integrated with the big
            # "ALL HOPE..." block, further below, but that doesn't
            # seem feasable.
            if (    $self->{'_p_strict'}
                and $HTML::DOM::_TreeBuilder::isKnown{$tag}
                and not $HTML::Tagset::is_Possible_Strict_P_Content{$tag} )
            {
                my $here     = $pos;
                my $here_tag = $ptag;
                while (1) {
                    if ( $here_tag eq 'p' ) {
                        print $indent, " * Inserting $tag closes strict P.\n"
                            if DEBUG > 1;
                        $self->end( \q{p} );

                    # NB: same as \'q', but less confusing to emacs cperl-mode
                        last;
                    }

                    #print("Lasting from $here_tag\n"),
                    last
                        if $HTML::DOM::_TreeBuilder::isKnown{$here_tag}
                            and
                            not $HTML::Tagset::is_Possible_Strict_P_Content{
                                $here_tag};

               # Don't keep looking up the tree if we see something that can't
               #  be strict-P content.

                    $here_tag
                        = ( $here = $here->{'_parent'} || last )->{'_tag'};
                }    # end while
                $ptag = ( $pos = $self->{'_pos'} || $self )
                    ->{'_tag'};    # better update!
            }

            # end of strict-p block.
        }

       # And now, get busy...
       #----------------------------------------------------------------------
        if ( !$self->{'_implicit_tags'} ) {    # bimskalabim
                                               # do nothing
            print $indent, " * _implicit_tags is off.  doing nothing\n"
                if DEBUG > 1;

       #----------------------------------------------------------------------
        }
        elsif ( $HTML::DOM::_TreeBuilder::isHeadOrBodyElement{$tag} ) {
            if ( $pos->is_inside('body') ) {    # all is well
                print $indent,
                    " * ambilocal element \U$tag\E is fine under BODY.\n"
                    if DEBUG > 1;
            }
            elsif ( $pos->is_inside('head') ) {
                print $indent,
                    " * ambilocal element \U$tag\E is fine under HEAD.\n"
                    if DEBUG > 1;
            }
            else {

                # In neither head nor body!  mmmmm... put under head?

                if ( $ptag eq 'html' ) {    # expected case
                     # TODO?? : would there ever be a case where _head would be
                     #  absent from a tree that would ever be accessed at this
                     #  point?
                    die "Where'd my head go?" unless ref $self->{'_head'};
                    if ( $self->{'_head'}{'_implicit'} ) {
                        print $indent,
                            " * ambilocal element \U$tag\E makes an implicit HEAD.\n"
                            if DEBUG > 1;

                        # or rather, points us at it.
                        $self->{'_pos'}
                            = $self->{'_head'};    # to insert under...
                    }
                    else {
                        $self->warning(
                            "Ambilocal element <$tag> not under HEAD or BODY!?"
                        );

                        # Put it under HEAD by default, I guess
                        $self->{'_pos'}
                            = $self->{'_head'};    # to insert under...
                    }

                }
                else {

             # Neither under head nor body, nor right under html... pass thru?
                    $self->warning(
                        "Ambilocal element <$tag> neither under head nor body, nor right under html!?"
                    );
                }
            }

       #----------------------------------------------------------------------
        }
        elsif ( $HTML::DOM::_TreeBuilder::isBodyElement{$tag} ) {

            # Ensure that we are within <body>
            if ( $ptag eq 'body' ) {

                # We're good.
            }
            elsif (
                $HTML::DOM::_TreeBuilder::isBodyElement{$ptag}    # glarg
                and not $HTML::DOM::_TreeBuilder::isHeadOrBodyElement{$ptag}
                )
            {

              # Special case: Save ourselves a call to is_inside further down.
              # If our $ptag is an isBodyElement element (but not an
              # isHeadOrBodyElement element), then we must be under body!
                print $indent, " * Inferring that $ptag is under BODY.\n",
                    if DEBUG > 3;

                # I think this and the test for 'body' trap everything
                # bodyworthy, except the case where the parent element is
                # under an unknown element that's a descendant of body.
            }
            elsif ( $pos->is_inside('head') ) {
                print $indent,
                    " * body-element \U$tag\E minimizes HEAD, makes implicit BODY.\n"
                    if DEBUG > 1;
                $ptag = (
                    $pos = $self->{'_pos'}
                        = $self->{'_body'}    # yes, needs updating
                        || die "Where'd my body go?"
                )->{'_tag'};                  # yes, needs updating
            }
            elsif ( !$pos->is_inside('body') ) {
                print $indent,
                    " * body-element \U$tag\E makes implicit BODY.\n"
                    if DEBUG > 1;
                $ptag = (
                    $pos = $self->{'_pos'}
                        = $self->{'_body'}    # yes, needs updating
                        || die "Where'd my body go?"
                )->{'_tag'};                  # yes, needs updating
            }

            # else we ARE under body, so okay.

            # Handle implicit endings and insert based on <tag> and position
            # ... ALL HOPE ABANDON ALL YE WHO ENTER HERE ...
            if (   $tag eq 'p'
                or $tag eq 'h1'
                or $tag eq 'h2'
                or $tag eq 'h3'
                or $tag eq 'h4'
                or $tag eq 'h5'
                or $tag eq 'h6'
                or $tag eq 'form'

                # Hm, should <form> really be here?!
                )
            {

                # Can't have <p>, <h#> or <form> inside these
                $self->end(
                    $_Closed_by_structurals,
                    @HTML::DOM::_TreeBuilder::p_closure_barriers

                        # used to be just li!
                );

            }
            elsif ( $tag eq 'ol' or $tag eq 'ul' or $tag eq 'dl' ) {

                # Can't have lists inside <h#> -- in the unlikely
                #  event anyone tries to put them there!
                if (   $ptag eq 'h1'
                    or $ptag eq 'h2'
                    or $ptag eq 'h3'
                    or $ptag eq 'h4'
                    or $ptag eq 'h5'
                    or $ptag eq 'h6' )
                {
                    $self->end( \$ptag );
                }

                # TODO: Maybe keep closing up the tree until
                #  the ptag isn't any of the above?
                # But anyone that says <h1><h2><ul>...
                #  deserves what they get anyway.

            }
            elsif ( $tag eq 'li' ) {    # list item
                    # Get under a list tag, one way or another
                unless (
                    exists $HTML::DOM::_TreeBuilder::isList{$ptag}
                    or $self->end( \q{*}, keys %HTML::DOM::_TreeBuilder::isList ) #'
                    )
                {
                    print $indent,
                        " * inserting implicit UL for lack of containing ",
                        join( '|', keys %HTML::DOM::_TreeBuilder::isList ), ".\n"
                        if DEBUG > 1;
                    $self->insert_element( 'ul', 1 );
                }

            }
            elsif ( $tag eq 'dt' or $tag eq 'dd' ) {

                # Get under a DL, one way or another
                unless ( $ptag eq 'dl' or $self->end( \q{*}, 'dl' ) ) {    #'
                    print $indent,
                        " * inserting implicit DL for lack of containing DL.\n"
                        if DEBUG > 1;
                    $self->insert_element( 'dl', 1 );
                }

            }
            elsif ( $HTML::DOM::_TreeBuilder::isFormElement{$tag} ) {
                if ($self->{
                        '_ignore_formies_outside_form'}  # TODO: document this
                    and not $pos->is_inside('form')
                    )
                {
                    print $indent,
                        " * ignoring \U$tag\E because not in a FORM.\n"
                        if DEBUG > 1;
                    return;                              # bypass tweaking.
                }
                if ( $tag eq 'option' ) {

                    # return unless $ptag eq 'select';
                    $self->end( \q{option} );
                    $ptag = ( $self->{'_pos'} || $self )->{'_tag'};
                    unless ( $ptag eq 'select' or $ptag eq 'optgroup' ) {
                        print $indent,
                            " * \U$tag\E makes an implicit SELECT.\n"
                            if DEBUG > 1;
                        $pos = $self->insert_element( 'select', 1 );

                    # but not a very useful select -- has no 'name' attribute!
                    # is $pos's value used after this?
                    }
                }
            }
            elsif ( $HTML::DOM::_TreeBuilder::isTableElement{$tag} ) {
                if ( !$pos->is_inside('table') ) {
                    print $indent, " * \U$tag\E makes an implicit TABLE\n"
                        if DEBUG > 1;
                    $self->insert_element( 'table', 1 );
                }

                if ( $tag eq 'td' or $tag eq 'th' ) {

                    # Get under a tr one way or another
                    unless (
                        $ptag eq 'tr'    # either under a tr
                        or $self->end( \q{*}, 'tr',
                            'table' )    #or we can get under one
                        )
                    {
                        print $indent,
                            " * \U$tag\E under \U$ptag\E makes an implicit TR\n"
                            if DEBUG > 1;
                        $self->insert_element( 'tr', 1 );

                        # presumably pos's value isn't used after this.
                    }
                }
                else {
                    $self->end( \$tag, 'table' );    #'
                }

                # Hmm, I guess this is right.  To work it out:
                #   tr closes any open tr (limited at a table)
                #   thead closes any open thead (limited at a table)
                #   tbody closes any open tbody (limited at a table)
                #   tfoot closes any open tfoot (limited at a table)
                #   colgroup closes any open colgroup (limited at a table)
                #   col can try, but will always fail, at the enclosing table,
                #     as col is empty, and therefore never open!
                # But!
                #   td closes any open td OR th (limited at a table)
                #   th closes any open th OR td (limited at a table)
                #   ...implementable as "close to a tr, or make a tr"

            }
            elsif ( $HTML::DOM::_TreeBuilder::isPhraseMarkup{$tag} ) {
                if ( $ptag eq 'body' and $self->{'_implicit_body_p_tag'} ) {
                    print
                        " * Phrasal \U$tag\E right under BODY makes an implicit P\n"
                        if DEBUG > 1;
                    $pos = $self->insert_element( 'p', 1 );

                    # is $pos's value used after this?
                }
            }

            # End of implicit endings logic

       # End of "elsif ($HTML::DOM::_TreeBuilder::isBodyElement{$tag}"
       #----------------------------------------------------------------------

        }
        elsif ( $HTML::DOM::_TreeBuilder::isHeadElement{$tag} ) {
            if ( $pos->is_inside('body') ) {
                print $indent, " * head element \U$tag\E found inside BODY!\n"
                    if DEBUG;
                $self->warning("Header element <$tag> in body");    # [sic]
            }
            elsif ( !$pos->is_inside('head') ) {
                print $indent,
                    " * head element \U$tag\E makes an implicit HEAD.\n"
                    if DEBUG > 1;
            }
            else {
                print $indent,
                    " * head element \U$tag\E goes inside existing HEAD.\n"
                    if DEBUG > 1;
            }
            $self->{'_pos'} = $self->{'_head'} || die "Where'd my head go?";

       #----------------------------------------------------------------------
        }
        elsif ( $tag eq 'html' ) {
            if ( delete $self->{'_implicit'} ) {    # first time here
                print $indent, " * good! found the real HTML element!\n"
                    if DEBUG > 1;
            }
            else {
                print $indent, " * Found a second HTML element\n"
                    if DEBUG;
                $self->warning("Found a nested <html> element");
            }

            # in either case, migrate attributes to the real element
            for ( keys %$attr ) {
                $self->attr( $_, $attr->{$_} );
            }
            $self->{'_pos'} = undef;
            return $self;    # bypass tweaking.

       #----------------------------------------------------------------------
        }
        elsif ( $tag eq 'head' ) {
            my $head = $self->{'_head'} || die "Where'd my head go?";
            if ( delete $head->{'_implicit'} ) {    # first time here
                print $indent, " * good! found the real HEAD element!\n"
                    if DEBUG > 1;
            }
            else {                                  # been here before
                print $indent, " * Found a second HEAD element\n"
                    if DEBUG;
                $self->warning("Found a second <head> element");
            }

            # in either case, migrate attributes to the real element
            for ( keys %$attr ) {
                $head->attr( $_, $attr->{$_} );
            }
            return $self->{'_pos'} = $head;         # bypass tweaking.

       #----------------------------------------------------------------------
        }
        elsif ( $tag eq 'body' ) {
            my $body = $self->{'_body'} || die "Where'd my body go?";
            if ( delete $body->{'_implicit'} ) {    # first time here
                print $indent, " * good! found the real BODY element!\n"
                    if DEBUG > 1;
            }
            else {                                  # been here before
                print $indent, " * Found a second BODY element\n"
                    if DEBUG;
                $self->warning("Found a second <body> element");
            }

            # in either case, migrate attributes to the real element
            for ( keys %$attr ) {
                $body->attr( $_, $attr->{$_} );
            }
            $self->{'_pos'} = $body unless $pos->is_inside('body');
            return $body;                           # bypass tweaking.

       #----------------------------------------------------------------------
        }
        elsif ( $tag eq 'frameset' ) {
            if (!( $self->{'_frameset_seen'}++ )    # first frameset seen
                and !$self->{'_noframes_seen'}

                # otherwise it'll be under the noframes already
                and !$self->is_inside('body')
                )
            {

           # The following is a bit of a hack.  We don't use the normal
           #  insert_element because 1) we don't want it as _pos, but instead
           #  right under $self, and 2), more importantly, that we don't want
           #  this inserted at the /end/ of $self's content_list, but instead
           #  in the middle of it, specifiaclly right before the body element.
           #
                my $c    = $self->{'_content'} || die "Contentless root?";
                my $body = $self->{'_body'}    || die "Where'd my BODY go?";
                for ( my $i = 0; $i < @$c; ++$i ) {
                    if ( $c->[$i] eq $body ) {
                        splice( @$c, $i, 0, $self->{'_pos'} = $pos = $e );
                        $e->{'_parent'} = $self;
                        $already_inserted = 1;
                        print $indent,
                            " * inserting 'frameset' right before BODY.\n"
                            if DEBUG > 1;
                        last;
                    }
                }
                die "BODY not found in children of root?"
                    unless $already_inserted;
            }

        }
        elsif ( $tag eq 'frame' ) {

            # Okay, fine, pass thru.
            # Should probably enforce that these should be under a frameset.
            # But hey.  Ditto for enforcing that 'noframes' should be under
            # a 'frameset', as the DTDs say.

        }
        elsif ( $tag eq 'noframes' ) {

           # This basically assumes there'll be exactly one 'noframes' element
           #  per document.  At least, only the first one gets to have the
           #  body under it.  And if there are no noframes elements, then
           #  the body pretty much stays where it is.  Is that ever a problem?
            if ( $self->{'_noframes_seen'}++ ) {
                print $indent, " * ANOTHER noframes element?\n" if DEBUG;
            }
            else {
                if ( $pos->is_inside('body') ) {
                    print $indent, " * 'noframes' inside 'body'.  Odd!\n"
                        if DEBUG;

               # In that odd case, we /can't/ make body a child of 'noframes',
               # because it's an ancestor of the 'noframes'!
                }
                else {
                    $e->push_content( $self->{'_body'}
                            || die "Where'd my body go?" );
                    print $indent, " * Moving body to be under noframes.\n"
                        if DEBUG;
                }
            }

       #----------------------------------------------------------------------
        }
        else {

            # unknown tag
            if ( $self->{'_ignore_unknown'} ) {
                print $indent, " * Ignoring unknown tag \U$tag\E\n" if DEBUG;
                $self->warning("Skipping unknown tag $tag");
                return;
            }
            else {
                print $indent, " * Accepting unknown tag \U$tag\E\n"
                    if DEBUG;
            }
        }

       #----------------------------------------------------------------------
       # End of mumbo-jumbo

        print $indent, "(Attaching ", $e->{'_tag'}, " under ",
            ( $self->{'_pos'} || $self )->{'_tag'}, ")\n"

            # because if _pos isn't defined, it goes under self
            if DEBUG;

        # The following if-clause is to delete /some/ ignorable whitespace
        #  nodes, as we're making the tree.
        # This'd be a node we'd catch later anyway, but we might as well
        #  nip it in the bud now.
        # This doesn't catch /all/ deletable WS-nodes, so we do have to call
        #  the tightener later to catch the rest.

        if ( $self->{'_tighten'} and !$self->{'_ignore_text'} )
        {    # if tightenable
            my ( $sibs, $par );
            if (( $sibs = ( $par = $self->{'_pos'} || $self )->{'_content'} )
                and @$sibs            # parent already has content
                and !
                ref( $sibs->[-1] )    # and the last one there is a text node
                and $sibs->[-1] !~ m<[^\n\r\f\t ]>s  # and it's all whitespace

                and (    # one of these has to be eligible...
                    $HTML::DOM::_TreeBuilder::canTighten{$tag}
                    or (( @$sibs == 1 )
                        ?    # WS is leftmost -- so parent matters
                        $HTML::DOM::_TreeBuilder::canTighten{ $par->{'_tag'} }
                        :    # WS is after another node -- it matters
                        (   ref $sibs->[-2]
                                and
                                $HTML::DOM::_TreeBuilder::canTighten{ $sibs->[-2]
                                    {'_tag'} }
                        )
                    )
                )

                and !$par->is_inside( 'pre', 'xmp', 'textarea', 'plaintext' )

                # we're clear
                )
            {
                pop @$sibs;
                print $indent, "Popping a preceding all-WS node\n" if DEBUG;
            }
        }

        $self->insert_element($e) unless $already_inserted;

        if (DEBUG) {
            if ( $self->{'_pos'} ) {
                print $indent, "(Current lineage of pos:  \U$tag\E under ",
                    join(
                    '/',
                    reverse(

                        # $self->{'_pos'}{'_tag'},  # don't list myself!
                        $self->{'_pos'}->lineage_tag_names
                    )
                    ),
                    ".)\n";
            }
            else {
                print $indent, "(Pos points nowhere!?)\n";
            }
        }

        unless ( ( $self->{'_pos'} || '' ) eq $e ) {

            # if it's an empty element -- i.e., if it didn't change the _pos
            &{         $self->{"_tweak_$tag"}
                    || $self->{'_tweak_*'}
                    || return $e }( map $_, $e, $tag, $self )
                ;    # make a list so the user can't clobber
        }

        return $e;
    }
}

#==========================================================================

{
    my $indent;

    sub end {
        return if $_[0]{'_stunted'};

       # Either: Acccept an end-tag signal from HTML::Parser
       # Or: Method for closing currently open elements in some fairly complex
       #  way, as used by other methods in this class.
        my ( $self, $tag, @stop ) = @_;
        if ( $tag eq 'x-html' ) {
            print "Ignoring close-x-html tag.\n" if DEBUG;

            # inserted by some lame code-generators.
            return;
        }

        unless ( ref($tag) or $tag =~ m/^[-_a-zA-Z0-9:%]+$/s ) {
            DEBUG and print "End-tag name $tag is no good.  Skipping.\n";
            return;

            # This avoids having Element's new() throw an exception.
        }

       # This method accepts two calling formats:
       #  1) from Parser:  $self->end('tag_name', 'origtext')
       #        in which case we shouldn't mistake origtext as a blocker tag
       #  2) from myself:  $self->end(\q{tagname1}, 'blk1', ... )
       #     from myself:  $self->end(['tagname1', 'tagname2'], 'blk1',  ... )

        # End the specified tag, but don't move above any of the blocker tags.
        # The tag can also be a reference to an array.  Terminate the first
        # tag found.

        my $ptag = ( my $p = $self->{'_pos'} || $self )->{'_tag'};

        # $p and $ptag are sort-of stratch

        if ( ref($tag) ) {

            # First param is a ref of one sort or another --
            #  THE CALL IS COMING FROM INSIDE THE HOUSE!
            $tag = $$tag if ref($tag) eq 'SCALAR';

            # otherwise it's an arrayref.
        }
        else {

            # the call came from Parser -- just ignore origtext
            # except in a table ignore unmatched table tags RT #59980
            @stop = $tag =~ /^t[hdr]\z/ ? 'table' : ();
        }

        #my($indent);
        if (DEBUG) {

           # optimization -- don't figure out depth unless we're in debug mode
            my @lineage_tags = $p->lineage_tag_names;
            $indent = '  ' x ( 1 + @lineage_tags );

            # now announce ourselves
            print $indent, "Ending ",
                ref($tag) ? ( '[', join( ' ', @$tag ), ']' ) : "\U$tag\E",
                scalar(@stop)
                ? ( " no higher than [", join( ' ', @stop ), "]" )
                : (), ".\n";

            print $indent, " (Current lineage: ", join( '/', @lineage_tags ),
                ".)\n"
                if DEBUG > 1;

            if ( DEBUG > 3 ) {

                #my(
                # $package, $filename, $line, $subroutine,
                # $hasargs, $wantarray, $evaltext, $is_require) = caller;
                print $indent,
                    " (Called from ", ( caller(1) )[3], ' line ',
                    ( caller(1) )[2],
                    ")\n";
            }

            #} else {
            #  $indent = ' ';
        }

        # End of if DEBUG

        # Now actually do it
        my @to_close;
        if ( $tag eq '*' ) {

        # Special -- close everything up to (but not including) the first
        #  limiting tag, or return if none found.  Somewhat of a special case.
        PARENT:
            while ( defined $p ) {
                $ptag = $p->{'_tag'};
                print $indent, " (Looking at $ptag.)\n" if DEBUG > 2;
                for (@stop) {
                    if ( $ptag eq $_ ) {
                        print $indent,
                            " (Hit a $_; closing everything up to here.)\n"
                            if DEBUG > 2;
                        last PARENT;
                    }
                }
                push @to_close, $p;
                $p = $p->{'_parent'};    # no match so far? keep moving up
                print $indent,
                    " (Moving on up to ", $p ? $p->{'_tag'} : 'nil', ")\n"
                    if DEBUG > 1;
            }
            unless ( defined $p ) { # We never found what we were looking for.
                print $indent, " (We never found a limit.)\n" if DEBUG > 1;
                return;
            }

            #print
            #   $indent,
            #   " (To close: ", join('/', map $_->tag, @to_close), ".)\n"
            #  if DEBUG > 4;

            # Otherwise update pos and fall thru.
            $self->{'_pos'} = $p;
        }
        elsif ( ref $tag ) {

           # Close the first of any of the matching tags, giving up if you hit
           #  any of the stop-tags.
        PARENT:
            while ( defined $p ) {
                $ptag = $p->{'_tag'};
                print $indent, " (Looking at $ptag.)\n" if DEBUG > 2;
                for (@$tag) {
                    if ( $ptag eq $_ ) {
                        print $indent, " (Closing $_.)\n" if DEBUG > 2;
                        last PARENT;
                    }
                }
                for (@stop) {
                    if ( $ptag eq $_ ) {
                        print $indent,
                            " (Hit a limiting $_ -- bailing out.)\n"
                            if DEBUG > 1;
                        return;    # so it was all for naught
                    }
                }
                push @to_close, $p;
                $p = $p->{'_parent'};
            }
            return unless defined $p;    # We went off the top of the tree.
               # Otherwise specified element was found; set pos to its parent.
            push @to_close, $p;
            $self->{'_pos'} = $p->{'_parent'};
        }
        else {

            # Close the first of the specified tag, giving up if you hit
            #  any of the stop-tags.
            while ( defined $p ) {
                $ptag = $p->{'_tag'};
                print $indent, " (Looking at $ptag.)\n" if DEBUG > 2;
                if ( $ptag eq $tag ) {
                    print $indent, " (Closing $tag.)\n" if DEBUG > 2;
                    last;
                }
                for (@stop) {
                    if ( $ptag eq $_ ) {
                        print $indent,
                            " (Hit a limiting $_ -- bailing out.)\n"
                            if DEBUG > 1;
                        return;    # so it was all for naught
                    }
                }
                push @to_close, $p;
                $p = $p->{'_parent'};
            }
            return unless defined $p;    # We went off the top of the tree.
               # Otherwise specified element was found; set pos to its parent.
            push @to_close, $p;
            $self->{'_pos'} = $p->{'_parent'};
        }

        $self->{'_pos'} = undef if $self eq ( $self->{'_pos'} || '' );
        print $indent, "(Pos now points to ",
            $self->{'_pos'} ? $self->{'_pos'}{'_tag'} : '???', ".)\n"
            if DEBUG > 1;

        ### EXPENSIVE, because has to check that it's not under a pre
        ### or a CDATA-parent.  That's one more method call per end()!
        ### Might as well just do this at the end of the tree-parse, I guess,
        ### at which point we'd be parsing top-down, and just not traversing
        ### under pre's or CDATA-parents.
        ##
        ## Take this opportunity to nix any terminal whitespace nodes.
        ## TODO: consider whether this (plus the logic in start(), above)
        ## would ever leave any WS nodes in the tree.
        ## If not, then there's no reason to have eof() call
        ## delete_ignorable_whitespace on the tree, is there?
        ##
    #if(@to_close and $self->{'_tighten'} and !$self->{'_ignore_text'} and
    #  ! $to_close[-1]->is_inside('pre', keys %HTML::Tagset::isCDATA_Parent)
    #) {  # if tightenable
    #  my($children, $e_tag);
    #  foreach my $e (reverse @to_close) { # going top-down
    #    last if 'pre' eq ($e_tag = $e->{'_tag'}) or
    #     $HTML::Tagset::isCDATA_Parent{$e_tag};
    #
    #    if(
    #      $children = $e->{'_content'}
    #      and @$children      # has children
    #      and !ref($children->[-1])
    #      and $children->[-1] =~ m<^\s+$>s # last node is all-WS
    #      and
    #        (
    #         # has a tightable parent:
    #         $HTML::DOM::_TreeBuilder::canTighten{ $e_tag }
    #         or
    #          ( # has a tightenable left sibling:
    #            @$children > 1 and
    #            ref($children->[-2])
    #            and $HTML::DOM::_TreeBuilder::canTighten{ $children->[-2]{'_tag'} }
    #          )
    #        )
    #    ) {
    #      pop @$children;
    #      #print $indent, "Popping a terminal WS node from ", $e->{'_tag'},
    #      #  " (", $e->address, ") while exiting.\n" if DEBUG;
    #    }
    #  }
    #}

        foreach my $e (@to_close) {

            # Call the applicable callback, if any
            $ptag = $e->{'_tag'};
            &{         $self->{"_tweak_$ptag"}
                    || $self->{'_tweak_*'}
                    || next }( map $_, $e, $ptag, $self );
            print $indent, "Back from tweaking.\n" if DEBUG;
            last
                if $self->{ '_stunted'
                    };    # in case one of the handlers called stunt
        }
        return @to_close;
    }
}

#==========================================================================
{
    my ( $indent, $nugget );

    sub text {
        return if $_[0]{'_stunted'};

        # Accept a "here's a text token" signal from HTML::Parser.
        my ( $self, $text, $is_cdata ) = @_;

        # the >3.0 versions of Parser may pass a cdata node.
        # Thanks to Gisle Aas for pointing this out.

        return unless length $text;    # I guess that's always right

        my $ignore_text         = $self->{'_ignore_text'};
        my $no_space_compacting = $self->{'_no_space_compacting'};
        my $no_expand_entities  = $self->{'_no_expand_entities'};
        my $pos                 = $self->{'_pos'} || $self;

        HTML::Entities::decode($text)
            unless $ignore_text
                || $is_cdata
                || $HTML::Tagset::isCDATA_Parent{ $pos->{'_tag'} }
                || $no_expand_entities;

        #my($indent, $nugget);
        if (DEBUG) {

           # optimization -- don't figure out depth unless we're in debug mode
            my @lineage_tags = $pos->lineage_tag_names;
            $indent = '  ' x ( 1 + @lineage_tags );

            $nugget
                = ( length($text) <= 25 )
                ? $text
                : ( substr( $text, 0, 25 ) . '...' );
            $nugget =~ s<([\x00-\x1F])>
                 <'\\x'.(unpack("H2",$1))>eg;
            print $indent, "Proposing a new text node ($nugget) under ",
                join( '/', reverse( $pos->{'_tag'}, @lineage_tags ) )
                || 'Root',
                ".\n";

            #} else {
            #  $indent = ' ';
        }

        my $ptag;
        if ($HTML::Tagset::isCDATA_Parent{ $ptag = $pos->{'_tag'} }

            #or $pos->is_inside('pre')
            or $pos->is_inside( 'pre', 'textarea' )
            )
        {
            return if $ignore_text;
            $pos->push_content($text);
        }
        else {

            # return unless $text =~ /\S/;  # This is sometimes wrong

            if ( !$self->{'_implicit_tags'} || $text !~ /[^\n\r\f\t ]/ ) {

                # don't change anything
            }
            elsif ( $ptag eq 'head' or $ptag eq 'noframes' ) {
                if ( $self->{'_implicit_body_p_tag'} ) {
                    print $indent,
                        " * Text node under \U$ptag\E closes \U$ptag\E, implicates BODY and P.\n"
                        if DEBUG > 1;
                    $self->end( \$ptag );
                    $pos = $self->{'_body'}
                        ? ( $self->{'_pos'}
                            = $self->{'_body'} )    # expected case
                        : $self->insert_element( 'body', 1 );
                    $pos = $self->insert_element( 'p', 1 );
                }
                else {
                    print $indent,
                        " * Text node under \U$ptag\E closes, implicates BODY.\n"
                        if DEBUG > 1;
                    $self->end( \$ptag );
                    $pos = $self->{'_body'}
                        ? ( $self->{'_pos'}
                            = $self->{'_body'} )    # expected case
                        : $self->insert_element( 'body', 1 );
                }
            }
            elsif ( $ptag eq 'html' ) {
                if ( $self->{'_implicit_body_p_tag'} ) {
                    print $indent,
                        " * Text node under HTML implicates BODY and P.\n"
                        if DEBUG > 1;
                    $pos = $self->{'_body'}
                        ? ( $self->{'_pos'}
                            = $self->{'_body'} )    # expected case
                        : $self->insert_element( 'body', 1 );
                    $pos = $self->insert_element( 'p', 1 );
                }
                else {
                    print $indent,
                        " * Text node under HTML implicates BODY.\n"
                        if DEBUG > 1;
                    $pos = $self->{'_body'}
                        ? ( $self->{'_pos'}
                            = $self->{'_body'} )    # expected case
                        : $self->insert_element( 'body', 1 );

                    #print "POS is $pos, ", $pos->{'_tag'}, "\n";
                }
            }
            elsif ( $ptag eq 'body' ) {
                if ( $self->{'_implicit_body_p_tag'} ) {
                    print $indent, " * Text node under BODY implicates P.\n"
                        if DEBUG > 1;
                    $pos = $self->insert_element( 'p', 1 );
                }
            }
            elsif ( $ptag eq 'table' ) {
                print $indent,
                    " * Text node under TABLE implicates TR and TD.\n"
                    if DEBUG > 1;
                $self->insert_element( 'tr', 1 );
                $pos = $self->insert_element( 'td', 1 );

                # double whammy!
            }
            elsif ( $ptag eq 'tr' ) {
                print $indent, " * Text node under TR implicates TD.\n"
                    if DEBUG > 1;
                $pos = $self->insert_element( 'td', 1 );
            }

            # elsif (
            #       # $ptag eq 'li'   ||
            #       # $ptag eq 'dd'   ||
            #         $ptag eq 'form') {
            #    $pos = $self->insert_element('p', 1);
            #}

            # Whatever we've done above should have had the side
            # effect of updating $self->{'_pos'}

            #print "POS is now $pos, ", $pos->{'_tag'}, "\n";

            return if $ignore_text;
            $text =~ s/[\n\r\f\t ]+/ /g    # canonical space
                unless $no_space_compacting;

            print $indent, " (Attaching text node ($nugget) under ",

           # was: $self->{'_pos'} ? $self->{'_pos'}{'_tag'} : $self->{'_tag'},
                $pos->{'_tag'}, ").\n"
                if DEBUG > 1;

            $pos->push_content($text);
        }

        &{ $self->{'_tweak_~text'} || return }( $text, $pos,
            $pos->{'_tag'} . '' );

        # Note that this is very exceptional -- it doesn't fall back to
        #  _tweak_*, and it gives its tweak different arguments.
        return;
    }
}

#==========================================================================

# TODO: test whether comment(), declaration(), and process(), do the right
#  thing as far as tightening and whatnot.
# Also, currently, doctypes and comments that appear before head or body
#  show up in the tree in the wrong place.  Something should be done about
#  this.  Tricky.  Maybe this whole business of pre-making the body and
#  whatnot is wrong.

sub comment {
    return if $_[0]{'_stunted'};

    # Accept a "here's a comment" signal from HTML::Parser.

    my ( $self, $text ) = @_;
    my $pos = $self->{'_pos'} || $self;
    return
        unless $self->{'_store_comments'}
            || $HTML::Tagset::isCDATA_Parent{ $pos->{'_tag'} };

    if (DEBUG) {
        my @lineage_tags = $pos->lineage_tag_names;
        my $indent = '  ' x ( 1 + @lineage_tags );

        my $nugget
            = ( length($text) <= 25 )
            ? $text
            : ( substr( $text, 0, 25 ) . '...' );
        $nugget =~ s<([\x00-\x1F])>
                 <'\\x'.(unpack("H2",$1))>eg;
        print $indent, "Proposing a Comment ($nugget) under ",
            join( '/', reverse( $pos->{'_tag'}, @lineage_tags ) ) || 'Root',
            ".\n";
    }

    ( my $e = $self->element_class->new('~comment') )->{'text'} = $text;
    $pos->push_content($e);
    ++( $self->{'_element_count'} );

    &{         $self->{'_tweak_~comment'}
            || $self->{'_tweak_*'}
            || return $e }( map $_, $e, '~comment', $self );

    return $e;
}

sub declaration {
    return if $_[0]{'_stunted'};

    # Accept a "here's a markup declaration" signal from HTML::Parser.

    my ( $self, $text ) = @_;
    my $pos = $self->{'_pos'} || $self;

    if (DEBUG) {
        my @lineage_tags = $pos->lineage_tag_names;
        my $indent = '  ' x ( 1 + @lineage_tags );

        my $nugget
            = ( length($text) <= 25 )
            ? $text
            : ( substr( $text, 0, 25 ) . '...' );
        $nugget =~ s<([\x00-\x1F])>
                 <'\\x'.(unpack("H2",$1))>eg;
        print $indent, "Proposing a Declaration ($nugget) under ",
            join( '/', reverse( $pos->{'_tag'}, @lineage_tags ) ) || 'Root',
            ".\n";
    }
    ( my $e = $self->element_class->new('~declaration') )->{'text'} = $text;

    $self->{_decl} = $e;
    return $e;
}

#==========================================================================

sub process {
    return if $_[0]{'_stunted'};

    # Accept a "here's a PI" signal from HTML::Parser.

    return unless $_[0]->{'_store_pis'};
    my ( $self, $text ) = @_;
    my $pos = $self->{'_pos'} || $self;

    if (DEBUG) {
        my @lineage_tags = $pos->lineage_tag_names;
        my $indent = '  ' x ( 1 + @lineage_tags );

        my $nugget
            = ( length($text) <= 25 )
            ? $text
            : ( substr( $text, 0, 25 ) . '...' );
        $nugget =~ s<([\x00-\x1F])>
                 <'\\x'.(unpack("H2",$1))>eg;
        print $indent, "Proposing a PI ($nugget) under ",
            join( '/', reverse( $pos->{'_tag'}, @lineage_tags ) ) || 'Root',
            ".\n";
    }
    ( my $e = $self->element_class->new('~pi') )->{'text'} = $text;
    $pos->push_content($e);
    ++( $self->{'_element_count'} );

    &{ $self->{'_tweak_~pi'} || $self->{'_tweak_*'} || return $e }( map $_,
        $e, '~pi', $self );

    return $e;
}

#==========================================================================

#When you call $tree->parse_file($filename), and the
#tree's ignore_ignorable_whitespace attribute is on (as it is
#by default), HTML::DOM::_TreeBuilder's logic will manage to avoid
#creating some, but not all, nodes that represent ignorable
#whitespace.  However, at the end of its parse, it traverses the
#tree and deletes any that it missed.  (It does this with an
#around-method around HTML::Parser's eof method.)
#
#However, with $tree->parse($content), the cleanup-traversal step
#doesn't happen automatically -- so when you're done parsing all
#content for a document (regardless of whether $content is the only
#bit, or whether it's just another chunk of content you're parsing into
#the tree), call $tree->eof() to signal that you're at the end of the
#text you're inputting to the tree.  Besides properly cleaning any bits
#of ignorable whitespace from the tree, this will also ensure that
#HTML::Parser's internal buffer is flushed.

sub eof {

    # Accept an "end-of-file" signal from HTML::Parser, or thrown by the user.

    return if $_[0]->{'_done'};    # we've already been here

    return $_[0]->SUPER::eof() if $_[0]->{'_stunted'};

    my $x = $_[0];
    print "EOF received.\n" if DEBUG;
    my (@rv);
    if (wantarray) {

        # I don't think this makes any difference for this particular
        #  method, but let's be scrupulous, for once.
        @rv = $x->SUPER::eof();
    }
    else {
        $rv[0] = $x->SUPER::eof();
    }

    $x->end('html') unless $x eq ( $x->{'_pos'} || $x );

    # That SHOULD close everything, and will run the appropriate tweaks.
    # We /could/ be running under some insane mode such that there's more
    #  than one HTML element, but really, that's just insane to do anyhow.

    unless ( $x->{'_implicit_tags'} ) {

        # delete those silly implicit head and body in case we put
        # them there in implicit tags mode
        foreach my $node ( $x->{'_head'}, $x->{'_body'} ) {
            $node->replace_with_content
                if defined $node
                    and ref $node
                    and $node->{'_implicit'}
                    and $node->{'_parent'};

            # I think they should be empty anyhow, since the only
            # logic that'd insert under them can apply only, I think,
            # in the case where _implicit_tags is on
        }

        # this may still leave an implicit 'html' at the top, but there's
        # nothing we can do about that, is there?
    }

    $x->delete_ignorable_whitespace()

        # this's why we trap this -- an after-method
        if $x->{'_tighten'} and !$x->{'_ignore_text'};
    $x->{'_done'} = 1;

    return @rv if wantarray;
    return $rv[0];
}

#==========================================================================

# TODO: document

sub stunt {
    my $self = $_[0];
    print "Stunting the tree.\n" if DEBUG;
    $self->{'_done'} = 1;

    if ( $HTML::Parser::VERSION < 3 ) {

        #This is a MEAN MEAN HACK.  And it works most of the time!
        $self->{'_buf'} = '';
        my $fh = *HTML::Parser::F{IO};

        # the local'd FH used by parse_file loop
        if ( defined $fh ) {
            print "Closing Parser's filehandle $fh\n" if DEBUG;
            close($fh);
        }

      # But if they called $tree->parse_file($filehandle)
      #  or $tree->parse_file(*IO), then there will be no *HTML::Parser::F{IO}
      #  to close.  Ahwell.  Not a problem for most users these days.

    }
    else {
        $self->SUPER::eof();

        # Under 3+ versions, calling eof from inside a parse will abort the
        #  parse / parse_file
    }

    # In the off chance that the above didn't work, we'll throw
    #  this flag to make any future events be no-ops.
    $self->stunted(1);
    return;
}

# TODO: document
sub stunted { shift->_elem( '_stunted', @_ ); }
sub done    { shift->_elem( '_done',    @_ ); }

#==========================================================================

sub delete {

    # Override Element's delete method.
    # This does most, if not all, of what Element's delete does anyway.
    # Deletes content, including content in some special attributes.
    # But doesn't empty out the hash.

    $_[0]->{'_element_count'} = 1;    # never hurts to be scrupulously correct

    delete @{ $_[0] }{ '_body', '_head', '_pos' };
    for (
        @{ delete( $_[0]->{'_content'} ) || [] },    # all/any content

     #       delete @{$_[0]}{'_body', '_head', '_pos'}
     # ...and these, in case these elements don't appear in the
     #   content, which is possible.  If they did appear (as they
     #   usually do), then calling $_->delete on them again is harmless.
     #  I don't think that's such a hot idea now.  Thru creative reattachment,
     #  those could actually now point to elements in OTHER trees (which we do
     #  NOT want to delete!).
## Reasoned out:
  #  If these point to elements not in the content list of any element in this
  #   tree, but not in the content list of any element in any OTHER tree, then
  #   just deleting these will make their refcounts hit zero.
  #  If these point to elements in the content lists of elements in THIS tree,
  #   then we'll get to deleting them when we delete from the top.
  #  If these point to elements in the content lists of elements in SOME OTHER
  #   tree, then they're not to be deleted.
        )
    {
        $_->delete
            if defined $_ and ref $_    #  Make sure it's an object.
                and $_ ne $_[0];    #  And avoid hitting myself, just in case!
    }

    $_[0]->detach if $_[0]->{'_parent'} and $_[0]->{'_parent'}{'_content'};

    # An 'html' element having a parent is quite unlikely.

    return;
}

sub tighten_up {                    # legacy
    shift->delete_ignorable_whitespace(@_);
}

sub elementify {

    # Rebless this object down into the normal element class.
    my $self     = $_[0];
    my $to_class = $self->element_class;
    delete @{$self}{
        grep {
            ;
            length $_ and substr( $_, 0, 1 ) eq '_'

                # The private attributes that we'll retain:
                and $_ ne '_tag'
                and $_ ne '_parent'
                and $_ ne '_content'
                and $_ ne '_implicit'
                and $_ ne '_pos'
                and $_ ne '_element_class'
            } keys %$self
        };
    bless $self, $to_class;    # Returns the same object we were fed
}

sub element_class {
    return 'HTML::DOM::_Element' if not ref $_[0];
    return $_[0]->{_element_class} || 'HTML::DOM::_Element';
}

#--------------------------------------------------------------------------

sub guts {
    my @out;
    my @stack       = ( $_[0] );
    my $destructive = $_[1];
    my $this;
    while (@stack) {
        $this = shift @stack;
        if ( !ref $this ) {
            push @out, $this;    # yes, it can include text nodes
        }
        elsif ( !$this->{'_implicit'} ) {
            push @out, $this;
            delete $this->{'_parent'} if $destructive;
        }
        else {

            # it's an implicit node.  Delete it and recurse
            delete $this->{'_parent'} if $destructive;
            unshift @stack,
                @{
                (   $destructive
                    ? delete( $this->{'_content'} )
                    : $this->{'_content'}
                    )
                    || []
                };
        }
    }

    # Doesn't call a real $root->delete on the (when implicit) root,
    #  but I don't think it needs to.

    return @out if wantarray;    # one simple normal case.
    return unless @out;
    return $out[0] if @out == 1 and ref( $out[0] );
    my $x = HTML::DOM::_Element->new( 'div', '_implicit' => 1 );
    $x->push_content(@out);
    return $x;
}

sub disembowel { $_[0]->guts(1) }

#--------------------------------------------------------------------------
1;

__END__

