
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: HTML.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Syntax::HTML ;

use Embperl::Syntax (':types') ;

use strict ;
use vars qw{@ISA %Attr %AssignAttr %AssignAttrLink %Quotes} ;


@ISA = qw(Embperl::Syntax) ;


###################################################################################
#
#   Methods
#
###################################################################################

# ---------------------------------------------------------------------------------
#
#   Create new Syntax Object
#
# ---------------------------------------------------------------------------------

sub new

    {
    my $self = shift ;

    $self = Embperl::Syntax::new ($self) ;

    if (!$self -> {-htmlAssignAttr})
        {
        $self -> {-htmlAssignAttr}     = $self -> CloneHash (\%AssignAttr) ;
        $self -> {-htmlAssignAttrLink} = $self -> CloneHash (\%AssignAttr) ;
        $self -> {-htmlQuotes}         = $self -> CloneHash (\%Quotes) ;
        }

    return $self ;
    }


# ---------------------------------------------------------------------------------
#
#   Add new element
#
# ---------------------------------------------------------------------------------


sub AddElement 

    {
    my ($self, $tagtype, $tagname, $attrs, $attrsurl, $attrsnoval, $procinfo, $taginfo, $addsess) = @_ ;


    my $ttref ;
    die "'$tagtype' unknown" if (!($ttref = $self -> {-root}{$tagtype})) ;
    my $ttfollow = ($ttref -> {'follow'} ||= {}) ;

    $ttref -> {'follow'}{-contains} = 'abcdefghijklmnopqrstuvwxyz0123456789_' ;
    
    my $tag = $ttfollow -> {$tagname} = { 
                                'text'      => $tagname,
                                'unescape'  => 1,
                                (ref($taginfo) eq 'HASH'?%$taginfo:()),
                              } ;
    $tag -> {'procinfo'} = { $self -> {-procinfotype} => $procinfo, (ref($taginfo) eq 'HASH'?%{$taginfo->{procinfo}}:()) } if ($procinfo) ;

    my %inside = (%{$self -> {-htmlQuotes}},
                   'removeslash' =>
        {
        'text' => "/",
        'nodetype' => 0,
        'cdatatype' => 0,
        'removespaces' => 0,
        'nodename' => '',
        },

                 ) ;
    my $addinside = 0 ;
    if ($attrs)
        {
        my $assignattr = $self -> {-htmlAssignAttr} ;
        foreach (@$attrs)
            {
            $inside {$_} = { 'text' => $_,  'nodename' => $_,  'follow' => $assignattr },
            $addinside++ ;
            }
        }
    if ($attrsurl)
        {
        my $assignattr = $self -> {-htmlAssignAttrLink} ;
        foreach (@$attrsurl)
            {
            $inside {$_} = { 'text' => $_,  'nodename' => $_,  'follow' => $assignattr },
            $addinside++ ;
            }
        $tag -> {'procinfo'}{$self->{-procinfotype}}{perlcode} .= 
            q[Embperl::Cmd::AddSessionIdToLink (%$n%, ] . $addsess . q[,'] . join ("','", @$attrsurl) . "') ;" 
                if ($addsess) ;
        }
    if ($attrsnoval)
        {
        foreach (@$attrsnoval)
            {
            $inside {$_} = { 'text' => $_,  , 'nodetype'   => ntypAttr, },
            $addinside++ ;
            }
        }
    $tag -> {'inside'} = \%inside if ($addinside) ;

    if (exists ($tag -> {'inside'}))
        {
        $self -> {-htmlTagInside} ||= [] ;
        push @{$self -> {-htmlTagInside}}, $tag -> {'inside'} ;
        }

    return $tag ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new simple html tag
#
# ---------------------------------------------------------------------------------


sub AddTag

    {
    my $self = shift ;


    $self -> AddToRoot ({
                        'A HTML Tag' => {
                            'text' => '<',
                            'end'  => '>',
                            }
                        }) if (!exists $self -> {-root}{'A HTML Tag'}) ;


    $self -> AddElement ('A HTML Tag', @_) ;
    }



# ---------------------------------------------------------------------------------
#
#   Add new simple html tag which is also available inside of other tags
#
# ---------------------------------------------------------------------------------


sub AddTagInside

    {
    my $self = shift ;

    my $tag = $self -> AddTag (@_) ;
    

    foreach my $inside (@{$self -> {-htmlTagInside}})
        {
        if (!exists ($inside -> {'HTML Tag'}))
            {
            $inside -> {'HTML Tag'} = 
                           {
                            'text' => '<',
                            'end'  => '>',
                            'follow' => {},
                            } ;
            }
        $inside -> {'HTML Tag'}{follow}{$_[0]} = $tag ;
        }

    my $quotes = $self -> {"-htmlQuotes"} ;
    while (my ($k2, $v2) = each %$quotes)
        {
        if (ref($v2) eq 'HASH')
	    {	  
            my $inside = $v2 -> {inside} ;
            if (!exists ($inside -> {'HTML Tag'}))
                {
                $inside -> {'HTML Tag'} = 
                               {
                                'text' => '<',
                                'end'  => '>',
                                'follow' => {},
                                } ;
                }
            $inside -> {'HTML Tag'}{follow}{$_[0]} = $tag ;

	    }
        }

    $quotes = $self -> {"-htmlAssignAttr"}{'Assign'}{follow} ;
    while (my ($k2, $v2) = each %$quotes)
        {
        if (ref($v2) eq 'HASH')
	    {	  
            my $inside = $v2 -> {inside} ;
            if (!exists ($inside -> {'HTML Tag'}))
                {
                $inside -> {'HTML Tag'} = 
                               {
                                'text' => '<',
                                'end'  => '>',
                                'follow' => {},
                                } ;
                }
            $inside -> {'HTML Tag'}{follow}{$_[0]} = $tag ;

	    }
        }
    $quotes = $self -> {"-htmlAssignAttrLink"}{'Assign'}{follow} ;
    while (my ($k2, $v2) = each %$quotes)
        {
        if (ref($v2) eq 'HASH')
	    {	  
            my $inside = $v2 -> {inside} ;
            if (!exists ($inside -> {'HTML Tag'}))
                {
                $inside -> {'HTML Tag'} = 
                               {
                                'text' => '<',
                                'end'  => '>',
                                'follow' => {},
                                } ;
                }
            $inside -> {'HTML Tag'}{follow}{$_[0]} = $tag ;

	    }
        }
    }


# ---------------------------------------------------------------------------------
#
#   Add new html comment tag
#
# ---------------------------------------------------------------------------------


sub AddComment

    {
    my $self = shift ;


    $self -> AddToRoot (
                    {
                    'HTML Comment' => {
                        'text' => '<!--',
                        'end'  => '-->',
                            }
                        }) if (!exists $self -> {-root}{'HTML Comment'}) ;
                         
    $self -> AddElement ('HTML Comment', @_) ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new block html tag
#
# ---------------------------------------------------------------------------------


sub AddTagBlock 

    {
    my ($self, $tagname, $attrs, $attrsurl, $attrsnoval, $procinfo, $taginfo) = @_ ;


    my $tag = $self -> AddTag ($tagname, $attrs, $attrsurl, $attrsnoval, $procinfo, $taginfo) ;

    $tag -> {'nodetype'} = &ntypStartTag ;

    $tag = $self -> AddTag ("/$tagname") ;

    $tag -> {'nodetype'} = &ntypEndTag ;
    $tag -> {'starttag'} = $tagname ;
    }


# ---------------------------------------------------------------------------------
#
#   Add new html tag which is an optional end tag
#
# ---------------------------------------------------------------------------------


sub AddTagWithStart

    {
    my ($self, $tagname, $starttag, $attrs, $attrsurl, $attrsnoval, $procinfo, $taginfo) = @_ ;


    my $tag = $self -> AddTag ($tagname, $attrs, $attrsurl, $attrsnoval, $procinfo, $taginfo) ;

    $tag -> {'starttag'} = $starttag ;
    }




# ---------------------------------------------------------------------------------
#
#   
#
# ---------------------------------------------------------------------------------


    
sub AddInside 

    {
    my ($self, $tagtype, $inside) = @_ ;

    my $ttref ;
    die "'$tagtype' unknown" if (!($ttref = $self -> {-tagtype}{$tagtype})) ;
    my $ttinside = ($ttref -> {'inside'} ||= {}) ;
    
    while (my ($k, $v) = each (%$inside))
        {
        $ttinside -> {$k} = $v ;
        }

    }


###################################################################################
#
#   Definitions for HTML attributs
#
###################################################################################


%Attr = (
    '-lsearch' => 1,
    'Attribut ""' => 
        {
        'text'   => '"',
        'end'    => '"',
        'nodetype'   => ntypAttr,
        'cdatatype'  => ntypAttrValue,
        },
    'Attribut \'\'' => 
        {
        'text'   => '\'',
        'end'    => '\'',
        'nodetype'   => ntypAttr,
        'cdatatype'  => ntypAttrValue,
        'addflags' => aflgSingleQuote,
        },
    'Attribut alphanum' => 
        {
        'contains'   => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789',
        'nodetype'   => ntypAttr,
        'cdatatype'  => ntypAttrValue,
        }
    ) ;


%AssignAttr = (
    'Assign' => 
        {
        'text' => '=',
        'follow' => \%Attr,
        }
    ) ;

%Quotes = (
    'Quote ""' => 
        {
        'text'   => '"',
        'end'    => '"',
        'nodetype'   => ntypCDATA,
        'cdatatype'  => ntypAttrValue,
        },
    'Quote \'\'' => 
        {
        'text'   => '\'',
        'end'    => '\'',
        'nodetype'   => ntypCDATA,
        'cdatatype'  => ntypAttrValue,
        },
    ) ;


1;


__END__

=pod

=head1 NAME

Embperl::Syntax::HTML - define the syntax for HTML

=head1 SYNOPSIS


=head1 DESCRIPTION

Class derived from Embperl::Syntax to define the syntax for HTML.
This class does not add functionalty of it own, it just provides
methods add definitions for derived classes to implement their own
tags.

=head1 Methods

I<Embperl::Syntax::HTML> defines the following methods:

=head2 Embperl::Syntax::HTML -> new  /  $self -> new

Create a new syntax class. This method should only be called inside a constructor
of a derived class.

=head2 AddTag ($tagname, $attrs, $attrsurl, $attrsnoval, $procinfo, $taginfo, $addsess)

Add a new HTML tag. 

=over 4

=item $tagname

Name of the HTML tag

=item $attrs

List of attributes that should be parsed out.

=item $attrsurl

List of attributes that should be parsed out. Any output inside the attribute value
is url escaped.

=item $attrsnoval

List of attributes that should be parsed out and doesn't contain a value.

=item $procinfo

Processor info. See I<Embperl::Syntax> for a definition of procinfo.

=item $taginfo

Addtional tag definitions. See I<Embperl::Syntax> for more infos.

=item $addsess

If set to 1 session id will be added to attributes passed via $attrsurl.
If set to 2 a hidden input tag with the session id will be added.

=back

=head2 AddTagInside ($tagname, $attrs, $attrsurl, $attrsnoval, $procinfo)

Same as AddTag, but tag could be also used inside of another tag. 
(e.g. <sometag <someothertag> > ). This is not HTML or XML compatible,
but maybe useful for implementing tagslibs etc. sometimes.

=head2 AddComment ($tagname, $attrs, $attrsurl, $attrsnoval, $procinfo)

Add a new HTML comment. Parameters are the same as for C<AddTag>.

=head2 AddTagBlock ($tagname, $attrs, $attrsurl, $attrsnoval, $procinfo)

Add a new HTML tag with start and end tag (e.g. <table> and </table>). 
Parameters are the same as for C<AddTag>.

=head2 AddTagWithStart ($tagname, $startname, $attrs, $attrsurl, $attrsnoval, $procinfo)

Add a new HTML tag which is an endtag for another tag. In opposite to C<AddTagBlock> the
end tag can, but need not exists in the source.
Parameters are the same as for C<AddTag>. Addtionaly the name of the starttag must be
specified.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

Embperl::Syntax







