
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
#   $Id: ASP.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 
package Embperl::Syntax::ASP ;

use Embperl::Syntax qw{:types} ;
use Embperl::Syntax::HTML ;

use strict ;
use vars qw{@ISA %Cmds %CmdsOutput %CmdsOutputLink} ;

@ISA = qw(Embperl::Syntax::HTML) ;


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
    my $class = shift ;

    my $self = Embperl::Syntax::HTML::new ($class) ;

    if (!$self -> {-aspInit})
        {
        $self -> {-aspInit} = 1 ;    
        Init ($self) ;
        }

    return $self ;
    }



###################################################################################
#
#   Definitions for ASP HTML tags
#
###################################################################################

sub Init

    {
    my ($self) = @_ ;


    $self -> {-aspCmds}     = $self -> CloneHash ({ %Cmds, %CmdsOutput }) ;
    $self -> {-aspCmdsLink} = $self -> CloneHash ({ %Cmds, %CmdsOutputLink }, { 'unescape' => 2 }) ;

    $self -> AddToRoot ($self -> {-aspCmds}) ;

    $self -> AddToRoot ({
        'ASP Syntax' => {
            'text' => '<%?syntax',
            'end'  => '?%>',
            'procinfo' => {
                embperl => { 
                        compiletimeperlcode => '$_[0] -> Syntax (Embperl::Syntax::GetSyntax(%#\'0%, $_[0] -> SyntaxName));', 
                        parsetimeperlcode   => '$_[0] -> Syntax (Embperl::Syntax::GetSyntax(\'%%\', $_[0] -> SyntaxName)) ;',
                        removenode => 3,
                        }
                    }
                }
        }) ;



    }

# ---------------------------------------------------------------------------------
#
#   Add new simple html tag (override to add asp commands inside html tags)
#
# ---------------------------------------------------------------------------------


sub AddTag

    {
    my $self = shift ;

    my $tag = $self -> Embperl::Syntax::HTML::AddTag (@_) ;

    #### add the ASP cmd inside the new HTML Tag ####

    $tag -> {inside} ||= {} ;
    my $inside = $tag -> {inside} ;    

    while (my ($k, $v) = each (%{$self -> {-aspCmds}}))
        {
        $inside -> {$k} = $v ;
        }

    if (!$self -> {-aspHTMLInit})
        {
        #### if not already done add the ASP cmds inside the HTML Attributes ####

        $self -> {-aspHTMLInit} = 1 ;

        my $unescape = 0 ;
        foreach ('', 'Link')
            {
            my $attr   = $self -> {"-htmlAssignAttr$_"} ;
            my $blocks = $self -> {"-aspCmds$_"} ;
            while (my ($k1, $v1) = each %$attr)
                {
                if (!($k1 =~ /^-/) && ref ($v1) eq 'HASH')
                    {
                    my $follow = $v1 -> {follow} ;
                    if (ref($follow) eq 'HASH')
                        {
                        while (my ($k2, $v2) = each %$follow)
                            {
                            if (ref($v2) eq 'HASH')
				{	  
				$v2 -> {inside} ||= {} ;
                            	my $inside = $v2 -> {inside} ;

	                        while (my ($k, $v) = each (%$blocks))
                                    {
                                    $inside -> {$k} = $v ;
                                    }
				}
                            }
                        }
                    }
                }
            }

        my $quotes = $self -> {"-htmlQuotes"} ;
        my $blocks = $self -> {"-aspCmds"} ;
        while (my ($k2, $v2) = each %$quotes)
            {
            if (ref($v2) eq 'HASH')
		{	  
		$v2 -> {inside} ||= {} ;
                my $inside = $v2 -> {inside} ;

	        while (my ($k, $v) = each (%$blocks))
                    {
                    $inside -> {$k} = $v ;
                    }
		}
            }
        }
    return $tag ;
    }

###################################################################################
#
#   ASP Implementation
#
###################################################################################




%Cmds = (
    '-lsearch' => 1,
    'ASP Code' => {
        'text' => '<%',
        'end'  => '%>',
        'procinfo' => 
            {
            embperl => 
                { 
                perlcode    => '%$c%%#0%',
                removenode  => 3,
                mayjump     => 1,
                compilechilds => 0,
                },
            },
        }
    ) ;

%CmdsOutput = (
    'ASP Output' => {
        'text' => '<%=',
        'end'  => '%>',
        'procinfo' => {
            embperl => { 
                    perlcode => 
                        [
                        'if (!defined (_ep_rp(%$x%,scalar(%#~0:$col%)))) %#~-0:$row% { if ($col == 0) { _ep_dcp (%$t%,%^*htmltable%) ; last l%^*htmltable% ; } else { _ep_dcp (%$t%,%^*htmlrow%) ; last l%^*htmlrow% ; }}',
                        'if (!defined (_ep_rp(%$x%,scalar(%#~0:$col%)))) { _ep_dcp (%$t%,%^*htmlrow%) ; last l%^*htmlrow% ; }',
                        'if (!defined (_ep_rp(%$x%,scalar(%#~0:$row%)))) { _ep_dcp (%$t%,%^*htmltable%) ; last l%^*htmltable% ; }',
                        '_ep_rp(%$x%,scalar(%#0%));', 
			],
                    removenode  => 4,
                    mayjump => '%#~0:$col|$row|$cnt% %?*htmlrow% %?*htmltable%',
                    compilechilds => 0,
                    }
                }
        }
    ) ;

%CmdsOutputLink = (
    'ASP Output Link' => {
        'text' => '<%=',
        'end'  => '%>',
        'nodename' => '<%=url',
        'unescape' => 2,
       'procinfo' => {
            embperl => { 
                    perlcode => 
                        [
                        'if (!defined (_ep_rpurl(%$x%,scalar(%#~0:$col%)))) %#~-0:$row% { if ($col == 0) { _ep_dcp (%$t%,%^*htmltable%) ; last l%^*htmltable% ; } else { _ep_dcp (%$t%,%^*htmlrow%) ; last l%^*htmlrow% ; }}',
                        'if (!defined (_ep_rpurl(%$x%,scalar(%#~0:$col%)))) { _ep_dcp (%$t%,%^*htmlrow%) ; last l%^*htmlrow% ; }',
                        'if (!defined (_ep_rpurl(%$x%,scalar(%#~0:$row%)))) { _ep_dcp (%$t%,%^*htmltable%) ; last l%^*htmltable% ; }',
                        '_ep_rpurl(%$x%,scalar(%#0%));', 
			],
                    removenode  => 4,
                    mayjump => '%#~0:$col|$row|$cnt% %?*htmlrow% %?*htmltable%',
                    compilechilds => 0,
                    }
                }
        }
    ) ;


1; 

__END__

=pod

=head1 NAME

Embperl::Syntax::ASP - ASP syntax module for Embperl 

=head1 SYNOPSIS

    [$syntax ASP $]

    <% $a = 1 ; %>
    <table>
        <% foreach (1..5) { %>
            <tr>
                <td><%= $_ %></td>
                <td><%= $a += 2 %></td>
            </tr>
        <% } %>
    </table>




=head1 DESCRIPTION

The module add the ASP syntax to Embperl. That mean when you select ASP as
syntax, Embperl understand the two following tags:

=over 4

=item <%   %>

Between <% and %> you can put any Perl code that should be executed.


=item <%=   %>

Between <%= and %> you can place a valid Perl expression and the result of
the expression is inserted instead of the <%= %> block.


=back

=head1 Author

Gerald Richter <richter at embperl dot org>

=head1 See Also

Embperl::Syntax

