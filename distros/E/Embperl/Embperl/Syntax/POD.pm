
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
#   $Id: POD.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Syntax::POD ;

use Embperl::Syntax (':types') ;
use Embperl::Syntax::EmbperlBlocks ;

use strict ;
use vars qw{@ISA %Tags %Format %Escape %Para %ParaItem %ParaTitle %List %Search %SearchInside %ListStart %CDATA %Skip} ;



@ISA = qw(Embperl::Syntax::EmbperlBlocks) ;


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

    #$self = Embperl::Syntax::EmbperlBlocks::new ($self, 1) ;
    $self = Embperl::Syntax::new ($self, 1) ;

    if (!$self -> {-PODTags})
        {
	$self -> {-PODTags}	  = $self -> CloneHash (\%Search) ;

	$self -> AddToRoot ($self -> {-PODTags}) ;
        $self -> AddInitCode (undef, '$escmode=0;$_ep_node=%$x%+1;print OUT "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" ?>"; $escmode=15; ', undef) ;
	#$self -> AddToRoot ({'-defnodetype' => ntypText,}) ;
    

	#$self -> {-PODCmds} = $self -> {-PODTags}{'POD Command'}{'follow'} ;
	#Init ($self) ;
        }

    return $self ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new POD command
#
# ---------------------------------------------------------------------------------


sub AddPODCmd

    {
    my ($self, $cmdname, $name) = @_ ;

    my $ttfollow = $self -> {-PODCmds} ;

    my $tag = $ttfollow -> {$cmdname} = { 
                                'text'      => $cmdname,
                                'nodetype'  => ntypStartEndTag,
                                'cdatatype' => ntypText,
                                'removespaces'  => 72,
                                'inside'  => \%Format,
                              } ;
    $tag -> {nodename} = $name if ($name) ;

    return $tag ;
    }


sub AddPODStartEnd

    {
    my ($self, $start, $end, $name) = @_ ;

    my $ttfollow = $self -> {-PODCmds} ;

    my $stag = $ttfollow -> {$start} = { 
                                'text'      => $start,
                                'nodetype'  => ntypStartTag,
                                'cdatatype' => 0,
                                'removespaces'  => 72,
                              } ;
    $stag -> {nodename} = $name if ($name) ;

    my $etag = $ttfollow -> {$end} = { 
                                'text'      => $end,
                                'nodetype'  => ntypEndTag,
                                'cdatatype' => 0,
                                'starttag'  => $start,
                                'removespaces'  => 72,
                              } ;
    return $stag ;
    }




###################################################################################
#
#   Definitions for POD
#
###################################################################################

sub Init

    {
    my ($self) = @_ ;

    #$self -> AddPODCmd ('head1') ;
    $self -> AddPODCmd ('head2') ;
    $self -> AddPODCmd ('head3') ;
    $self -> AddPODStartEnd ('over', 'back', 'list') ;
    $self -> AddPODStartEnd ('pod', 'cut') ;
    $self -> AddPODCmd ('item') ;
    $self -> AddPODCmd ('item *', 'bulletitem') ;
    } 


%Escape = (
    '-lsearch' => 1,
    'POD Escape' => {
	'text' => '<',
	'end'  => '>',
       'nodename' => ':::&gt;:&lt;',
        'nodetype'  => ntypStartEndTag,
        },
   'POD Escape &' => {
	'text' => '&',
        'nodename' => ':::&amp;',
        'nodetype'  => ntypTag,
        },
) ;

my %Escape2 = (

    'POD Escape <' => {
	'text' => '<',
        'nodename' => ':::&lt;',
        'nodetype'  => ntypTag,
        },
    'POD Escape >' => {
	'text' => '>',
        'nodename' => ':::&gt;',
        'nodetype'  => ntypTag,
        },
   'POD Escape &' => {
	'text' => '&',
        'nodename' => ':::&amp;',
        'nodetype'  => ntypTag,
        },

    ) ;


%Format = (
    '-lsearch' => 1,
    '-defnodetype' => ntypText,
    'POD Format B' => {
	'text' => 'B<',
	'end'  => '>',
        'nodename' => 'strong',
        'nodetype'  => ntypStartEndTag,
        },
    'POD Format C' => {
	'text' => 'C<',
	'end'  => '>',
        'nodename' => 'code',
        'nodetype'  => ntypStartEndTag,
        },
    'POD Format F' => {
	'text' => 'F<',
	'end'  => '>',
        'nodename' => 'code',
        'nodetype'  => ntypStartEndTag,
        },
    'POD Format I' => {
	'text' => 'I<',
	'end'  => '>',
        'nodename' => 'emphasis',
        'nodetype'  => ntypStartEndTag,
        },
    'POD Format U' => {
	'text' => 'U<',
	'end'  => '>',
        'nodename' => 'underline',
        'nodetype'  => ntypStartEndTag,
        },
    'POD Format L' => {
	'text' => 'L<',
	'end'  => '>',
        'nodename' => 'xlink',
        'nodetype'  => ntypStartEndTag,
        'inside'   =>
            {
            -lsearch => 1,
            '|' => 
                {
                'text' => '|',
                'end' => '>',
                'donteat' => 2,
                'follow' => {
                    'Quote ""' => 
                        {
                        'text'   => '"',
                        'end'    => '"',
                        'nodename' => 'uri',
                        'nodetype'   => ntypAttr,
                        'cdatatype'  => ntypAttrValue,
                        'addflags' => aflgSingleQuote,
                        },
                    'Quote \'\'' => 
                        {
                        'text'   => '\'',
                        'end'    => '\'',
                        'nodename' => 'uri',
                        'nodetype'   => ntypAttr,
                        'cdatatype'  => ntypAttrValue,
                        'addflags' => aflgSingleQuote,
                        },
                    'all' => 
                        {
                        'matchall' => 1,
                        'nodename' => 'uri',
                        'nodetype'   => ntypAttr,
                        'cdatatype'  => ntypAttrValue,
                        'donteat' => 2,
                        'addflags' => aflgSingleQuote,
                        },
                    },
                },
            'Quote ""' => 
                {
                'text'   => '"',
                'end'    => '"',
                'nodetype' => 0,
                'cdatatype' => ntypText,
                },
            'Quote \'\'' => 
                {
                'text'   => '\'',
                'end'    => '\'',
                'nodetype' => 0,
                'cdatatype' => ntypText,
                },
            '|1' => 
                {
                'text' => '|',
                'end' => '>',
                'nodename' => 'uri',
                'nodetype'   => ntypAttr,
                'cdatatype'  => ntypAttrValue,
                'donteat' => 2,
                'addflags' => aflgSingleQuote,
                },

            },
        },
    'POD Format L 2' => {
	'text' => 'L<',
	'end'  => '>',
        'nodename' => 'xlink',
        'nodetype'  => ntypStartEndTag,
        },
    'POD Format #' => {
	'text' => '#<',
	'end'  => '>',
        'nodename' => 'id',
        'nodetype'   => ntypAttr,
        'cdatatype'  => ntypAttrValue,
        'removespaces' => 72,
        },
    'http link' => {
	'text' => 'http://',
        'nodename' => 'xlink',
        'nodetype'  => ntypStartEndTag,
        'contains'   => '/.-:~?&=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789',
        'cdatatype' => ntypText,
        'donteat'   => 1,
        },
    'ftp link' => {
	'text' => 'ftp://',
        'nodename' => 'xlink',
        'nodetype'  => ntypStartEndTag,
        'contains'   => '/.-:~?&=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789',
        'cdatatype' => ntypText,
        'donteat'   => 1,
        },
    ) ;

my $paraend = "\n\n" ;

%List = 
    (
    '-lsearch' => 1,
    '-defnodetype' => ntypText,
    'liststart' => {
        'text'      => '=over',
        'end'       => '=back',
        'nodetype'  => ntypStartEndTag,
        'cdatatype' => 0,
        'removespaces'  => 2,
        'nodename'    => 'list',
        'inside'     => \%List,
        },
    'listend' => { 
        'text'      => '=back',
        'end'       => "\n",
        'nodetype'  => ntypEndTag,
        'cdatatype' => 0,
        'nodename'  => 'list',
        'removespaces'  => 72,
        'exitinside' => 1,
        },
    'item*' => {
        'text'      => '=item *',
        'end'       => '=item *',
        'donteat'   => 2,
        'nodetype'  => ntypStartEndTag,
        'nodename' => 'item',
        'removespaces' => 2,
        'inside'  => \%ParaItem,
        },
    'item' => {
        'text'      => '=item',
        'end'       => '=item',
        'donteat'   => 2,
        'nodetype'  => ntypStartEndTag,
        'nodename' => 'item',
        'removespaces' => 2,
        'inside'  => \%ParaItem,
        },
    ) ;

%ListStart = 
    (
    %List,
    'title' => 
        {
        'matchall'  => -1,  # only match first time after =over
        'text' => "\x02",      # gives sort order
        'end' => "\n",      # eat until end of line
        'cdatatype' => 0,
        'nodetype'  => 0,
        },
    ) ;

%CDATA = 
    (
    '-lsearch' => 1,
    'http link' => {
	'text' => 'http://',
        'nodename' => 'xlink',
        'nodetype'  => ntypStartEndTag,
        'contains'   => '/.-:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789',
        'cdatatype' => ntypText,
        'donteat'   => 1,
        },
    'ftp link' => {
	'text' => 'ftp://',
        'nodename' => 'xlink',
        'nodetype'  => ntypStartEndTag,
        'contains'   => '/.-:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789',
        'cdatatype' => ntypText,
        'donteat'   => 1,
        },
    'verbatim2' => 
        {
        'text' => " ",
        'end' => $paraend,
        'cdatatype' => ntypCDATA,
        'nodename' => ':::<![CDATA[:]]>',
        'removespaces' => 0,
        #'inside'  => { 'X' => { removespaces => 0, cdatatype => ntypCDATA }},
        #'inside' => \%Format,
        'nodetype'  => ntypStartEndTag,
        'donteat'  => 3,
        },


    ) ;

%Skip =
    (
    'skip1' => 
        {
#        'text' => "\n",
        'contains' => "\r\n",
        'nodetype' => ntypTag,
        'cdatatype' => 0,
        'removespaces' => 0,
        'nodename' => "!:\n",
        },
#    'skip2' => 
#        {
#        'text' => "\r",
#        'contains' => "\r\n",
#        'nodetype' => ntypTag,
#        'cdatatype' => 0,
#        'removespaces' => 0,
#        'nodename' => "!:\n",
#        },
    ) ;


%Para = 
    (
    %List,
    'skip' => 
        {
        'text' => "\n",
        'nodetype' => 0,
        'cdatatype' => 0,
        'removespaces' => 0,
        'nodename' => "\n",
        },
    'skip2' => 
        {
        'text' => "\r",
        'nodetype' => 0,
        'cdatatype' => 0,
        'removespaces' => 0,
        'nodename' => '',
        },
    'para' => 
        {
        'matchall'      => 1,
        'text' => "\0x01", # gives sort order
        'end' => $paraend,
        'cdatatype' => ntypText,
        'nodename' => 'para',
        'removespaces' => 72,
        'inside' => \%Format,
        'nodetype'  => ntypStartEndTag,
        },
    'verbatim' => 
        {
        'text' => " ",
        'end' => $paraend,
        'cdatatype' => 0,
        'nodename' => 'verbatim',
        'removespaces' => 0,
        'inside' => \%CDATA,
        'nodetype'  => ntypStartEndTag,
        'donteat'  => 1,
        },
    'pic' => {
        'text'      => '=pic',
        'end' => $paraend,
        'nodename'  => 'pic',
        'nodetype'  => ntypStartEndTag,
        'cdatatype' => ntypText,
        },
    #%Skip,
    ) ;

%ParaTitle = 
    (
    'title' => 
        {
        'matchall'  => -1,  # only match first time after =head
        'text' => "\x02",      # gives sort order
        'end' => $paraend,
        'cdatatype' => ntypText,
        'nodename' => 'title',
        'removespaces' => 40, #72,
        'inside' => \%Format,
        'nodetype'  => ntypStartEndTag,
        },
    %Para,
    ) ;

%ParaItem = 
    (
    %Para,
    'itemtext' => 
        {
        'matchall'  => -1,  # only match first time after =head
        'text' => "\x02",      # gives sort order
        'end' => $paraend,
        'cdatatype' => ntypText,
        'nodename' => 'itemtext',
        'removespaces' => 72,
        'inside' => \%Format,
        'nodetype'  => ntypStartEndTag,
        },
    'item*' => {
        'text'      => '=item *',
        'nodename'  => 'item',
        'nodetype'  => ntypEndTag,
        'donteat'   => 1,
        'exitinside'  => 1,
        },
    'item' => {
        'text'      => '=item',
        'nodename'  => 'item',
        'nodetype'  => ntypEndTag,
        'donteat'   => 1,
        'exitinside'  => 1,
        },
    'listend' => {
        'text'      => '=back',
        'nodename'  => 'item',
        'nodetype'  => ntypEndTag,
        'donteat'   => 1,
        'exitinside'  => 1,
        },
    'cut' => {
        'text'      => '=cut',
        'nodetype'  => 0,
        'cdatatype'  => 0,
        'nodename' => '',
        'inside'  => \%SearchInside,
        },
    
    
    ) ;

%SearchInside = 
    (
    '-lsearch' => 1,
    '-defnodetype' => 0,
    'start' => {
        'text'      => "\n=",
        'donteat'   => 1,
        'nodetype'  => 0,
        'cdatatype'  => 0,
        'removespaces' => 2,
        'exitinside'  => 1,
        },
    ) ;


%Tags = 
    (
    '-lsearch' => 1,
    '-defnodetype' => ntypText,
    'head1name' => {
        'text'      => '=head1 NAME',
        'end'       => '=head1',
        'donteat'   => 2,
        'nodetype'  => ntypStartEndTag,
        'nodename' => 'head',
        'removespaces' => 2,
        'inside'  => {
            '-lsearch' => 1,
            'title' => 
                {
                'matchall'  => -1,  # only match first time after =head
                'text' => "\x02",      # gives sort order
                'end' => $paraend,
                'cdatatype' => ntypText,
                'nodename' => 'title',
                'removespaces' => 72,
                'inside' => \%Format,
                'nodetype'  => ntypStartEndTag,
                },
            },
        },
    'head1' => {
        'text'      => '=head1',
        'end'       => '=head1',
        'donteat'   => 2,
        'nodetype'  => ntypStartEndTag,
        'nodename' => 'sect1',
        'removespaces' => 2,
        'inside'  => {
            '-lsearch' => 1,
            %ParaTitle,
            'head1' => {
                'text'      => '=head1',
                'nodename'  => 'sect1',
                'nodetype'  => ntypEndTag,
                'donteat'   => 1,
                'exitinside'  => 1,
                },
            'cut' => {
                'text'      => '=cut',
                'nodename'  => 'sect1',
                'nodetype'  => ntypEndTag,
                'donteat'   => 1,
                'exitinside'  => 1,
                },
            'head2' => {
                'text'      => '=head2',
                'end'       => '=head2',
                'donteat'   => 2,
                'nodetype'  => ntypStartEndTag,
                'nodename' => 'sect2',
                'removespaces' => 2,
                'inside'  => {
                    '-lsearch' => 1,
                    %ParaTitle,
                    'head1' => {
                        'text'      => '=head1',
                        'nodename' => 'sect2',
                        'nodetype'  => ntypEndTag,
                        'cdatatype' => 0,
                        'donteat'   => 1,
                        'exitinside'  => 1,
                        },
                    'head2' => {
                        'text'      => '=head2',
                        'nodetype'  => ntypEndTag,
                        'nodename' => 'sect2',
                        'donteat'   => 1,
                        'exitinside'  => 1,
                        },
                    'cut' => {
                        'text'      => '=cut',
                        'nodetype'  => 0,
                        'cdatatype'  => 0,
                        'nodename' => '',
                        'inside'  => \%SearchInside,
                        },
                    'head3' => {
                        'text'      => '=head3',
                        'end'       => '=head3',
                        'donteat'   => 2,
                        'nodetype'  => ntypStartEndTag,
                        'nodename' => 'sect3',
                        'removespaces' => 2,
                        'inside'  => {
                            '-lsearch' => 1,
                            %ParaTitle,
                            'head1' => {
                                'text'      => '=head1',
                                'nodename' => 'sect3',
                                'nodetype'  => ntypEndTag,
                                'cdatatype' => 0,
                                'donteat'   => 1,
                                'exitinside'  => 1,
                                },
                            'head2' => {
                                'text'      => '=head2',
                                'nodetype'  => ntypEndTag,
                                'cdatatype' => 0,
                                'nodename' => 'sect3',
                                'donteat'   => 1,
                                'exitinside'  => 1,
                                },
                            'head3' => {
                                'text'      => '=head3',
                                'nodetype'  => ntypEndTag,
                                'nodename' => 'sect3',
                                'donteat'   => 1,
                                'exitinside'  => 1,
                                },
                            'cut' => {
                                'text'      => '=cut',
                                'nodetype'  => 0,
                                'cdatatype'  => 0,
                                'nodename' => '',
                                'inside'  => \%SearchInside,
                                },
                            },
                        },
                    },
                },
            },
        },
    'cut' => {
        'text'      => '=cut',
        'nodetype'  => 0,
        'cdatatype'  => 0,
        'exitinside'  => 1,
        },
#    %Para,
    ) ;

%Search = 
    (
    '-lsearch' => 1,
    '-defnodetype' => 0,
    '-rootnode' => 'pod',
    'start' => {
        'text'      => "\n=",
        'donteat'   => 1,
        'nodetype'  => 0,
        'cdatatype'  => 0,
        'removespaces' => 2,
        'inside'  => \%Tags
        },
    'startpod' => {
        'text'      => '=pod',
        'end'       => "\n",
        'nodetype'  => 0,
        'cdatatype'  => 0,
        'removespaces' => 2,
        'inside'  => \%Tags
        },
    'startpod2' => {
        'text'      => "\n=pod",
        'end'       => "\n",
        'nodetype'  => 0,
        'cdatatype'  => 0,
        'removespaces' => 2,
        'inside'  => \%Tags
        },
    ) ;

1;


__END__

=pod

=head1 NAME

Embperl::Syntax::POD - convert POD to XML on-the-fly

=head1 SYNOPSIS


=head1 DESCRIPTION

Class derived from Embperl::Syntax to convert Perl Plain Old
Documentation (POD) files on the fly into XML.

Used for generating the Embperl online documentation from the Embperl
POD files. See to eg directory in the distribution for an example how
to use it.


=head1 TODO

Documenation of the resulting XML format still has to be written...


=head1 Methods

I<Embperl::Syntax::POD> defines the following methods:

=head2 Embperl::Syntax::POD -> new  /  $self -> new

Create a new syntax class. This method should only be called inside a constructor
of a derived class.


=head2 AddPODCmd ($cmdname, $procinfo)

Add a new POD command with name C<$cmdname> and use processor info from
C<$procinfo>. See I<Embperl::Syntax> for a definition of procinfo.

=head2 AddPODCmdStartEnd ($cmdname, $endname, $procinfo)

Add a new POD command with name C<$cmdname> and use processor info from
C<$procinfo>. Addtionaly specify that a matching C<$endname> POD command
must be found to end the block, that is started by this POD command.
See I<Embperl::Syntax> for a definition of procinfo.



=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

Embperl::Syntax
