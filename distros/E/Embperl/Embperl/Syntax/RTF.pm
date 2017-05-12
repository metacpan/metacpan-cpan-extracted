
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
#   $Id: RTF.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Syntax::RTF ;

use Embperl::Syntax (':types') ;
use Embperl::Syntax::EmbperlBlocks ;

use strict ;
use vars qw{@ISA %RTF %Para %ParaBlockInside %Block %BlockInside %FieldStart %CmdStart %Var %Spaces %Inside} ;

require Text::ParseWords ;

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

    $self = Embperl::Syntax::EmbperlBlocks::new ($self, { 'unescape' => 17 }) ;

    if (!$self -> {-rtfBlocks})
        {
        my $eb = $self -> {-epbBlocks} ;
        my $k ;
        my $v ;
        my $ebesc = $self -> CloneHash ($eb, { 'unescape' => 17 }) ;

        $self -> {-root} = $self -> CloneHash ($self -> {-root}, { 'unescape' => 17 }) ;
       
        while (($k, $v) = each %$ebesc)
            {
            $Block{$k} = $v ;
            }

	$self -> {-rtfBlocks}	  = $self -> CloneHash (\%RTF) ;

	$self -> AddToRoot ($self -> {-rtfBlocks}) ;

#	$self -> {-rtfCmds} = $self -> {-rtfBlocks}{'RTF mainblock'}{'inside'}{'RTF first paragraph'}{'inside'}{'RTF field'}{'inside'}{'RTF fieldstart'}{'inside'}{'RTF block cmd'}{'inside'}  ;
#	$self -> {-rtfCmds2} = $self -> {-rtfBlocks}{'RTF mainblock'}{'inside'}{'RTF first paragraph'}{'inside'}{'RTF field'}{'inside'}{'RTF fieldstart'}{'inside'}  ;
	$self -> {-rtfCmds} = $self -> {-rtfBlocks}{'RTF mainblock'}{'inside'}{'RTF field'}{'inside'}{'RTF fieldstart'}{'inside'}{'RTF block cmd'}{'inside'}  ;
	$self -> {-rtfCmds2} = $self -> {-rtfBlocks}{'RTF mainblock'}{'inside'}{'RTF field'}{'inside'}{'RTF fieldstart'}{'inside'}  ;
	Init ($self) ;
        }

    return $self ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new rtf command
#
# ---------------------------------------------------------------------------------


sub AddRTFCmd

    {
    my ($self, $cmdname, $procinfo, $taginfo, $procinfoinside) = @_ ;

    my $ttfollow = $self -> {-rtfCmds} ;

    my $tag = $ttfollow -> {$cmdname} = { 
                                'text'      => $cmdname,
                                'nodetype'  => ntypStartEndTag,
                                #'nodetype'  => ntypTag,
                                #'cdatatype' => ntypAttrValue,
                                'forcetype' => 1,
                                'unescape'  => 1,
                                'removespaces'  => 16,
                                (ref($taginfo) eq 'HASH'?%$taginfo:()),
                              } ;
    if ($procinfo) 
        {
        #$procinfo -> {compiletimeperlcode} = q[my $tmp = %#'0% ; $tmp =~ s/_ep_rp\(.*?\,/push \@_ep_rtf_tmp,(/,  $Embperl::req -> component -> code ($tmp) ; ] ;
        $tag -> {'procinfo'} = { $self -> {-procinfotype} => $procinfo } ;
        }
    $self -> {-rtfCmds2} -> {$cmdname} = $tag ;
    
    
    return $tag ;
    }


# ---------------------------------------------------------------------------------
#
#   Add new rtf command that has an corresponding end rtf command
#
# ---------------------------------------------------------------------------------


sub AddRTFCmdWithEnd

    {
    my ($self, $cmdname, $endname, $procinfo) = @_ ;

    my $tag = $self -> AddRTFCmd ($cmdname, $procinfo) ;

    $tag -> {'endtag'} = $endname ;

    return $tag ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new rtf command with start and end
#
# ---------------------------------------------------------------------------------


sub AddRTFCmdBlock

    {
    my ($self, $cmdname, $endname, $procinfostart, $procinfoend) = @_ ;

    my $tag ;
    my $pinfo ;

    $tag = $self -> AddRTFCmd ($cmdname, $procinfostart) ;
    $tag -> {'endtag'} = $endname ;
    $pinfo = $tag -> {'procinfo'} -> {$self -> {-procinfotype}} ;
    $pinfo -> {'stackname'} = 'metacmd' ;
    $pinfo -> {'push'} = $cmdname ;

    $tag = $self -> AddRTFCmd ($endname, $procinfoend) ;
    $pinfo = $tag -> {'procinfo'} -> {$self -> {-procinfotype}} ;
    $pinfo -> {'stackname'} = 'metacmd' ;
    $pinfo -> {'stackmatch'} = $cmdname ;
    

    return $tag ;
    }




###################################################################################
#
#   Definitions for RTF
#
###################################################################################

sub Init

    {
    my ($self) = @_ ;

    $self -> AddInitCode (undef, '$_ep_rtf_ndx=0;$escmode=0;sub esc { my $x = shift ; $x =~ s/([{}])/\\\\$1/g ; $x =~ s/\n/\\\\line /g ; $x} ; ', undef) ;

    $self -> AddRTFCmd ('DOCVARIABLE',
                            { 
                            perlcode => '_ep_rp(%$x%,scalar(esc(join(\'\',', 
                            perlcodeend => '))));', 
                            compiletimeperlcode => q[if ($_ep_rtf_inside) { my $tmp = $Embperl::req -> component -> code () ; $tmp =~ s/_ep_rp\(.*?\,/push \@_ep_rtf_tmp,(/ ; $Embperl::req -> component -> code ($tmp) } ; $_ep_rtf_cmd = 1 ;],
			    },
                            { 
                            'inside'    => \%Var,
                            'cdatatype' => 0,
                            },
                            ) ;
    $self -> AddRTFCmd ('MERGEFIELD',
                            { 
                            perlcode => '_ep_rp(%$x%,scalar(esc(join(\'\', ',
                            perlcodeend => '))));', 
                            compiletimeperlcode => q[if ($_ep_rtf_inside) { my $tmp = $Embperl::req -> component -> code () ; $tmp =~ s/_ep_rp\(.*?\,/push \@_ep_rtf_tmp,(/ ; $tmp .= '\'' . (%>'-1%) . '\'' . ',' ; $Embperl::req -> component -> code ($tmp) } ; $_ep_rtf_cmd = 1 ;],
			    },
                            { 
                            'inside'    => \%Var,
                            'cdatatype' => 0,
			    },
                            ) ;


    $self -> AddRTFCmd ('NEXT',
                            { 
                            perlcode => '$_ep_rtf_ndx++;', 
                            'removenode'  => 1,
			    },
                            { 
                            'nodename' => '::::NEXT',
                            'cdatatype' => 0,
			    }) ;

    $self -> AddRTFCmd ('MERGEREC',
                            { 
                            perlcode => '_ep_rp(%$x%,$_ep_rtf_ndx+1);', 
			    },
                            { 
                            'nodename' => '::::MERGEREC',
                            'cdatatype' => 0,
			    },
                            { 
                            perlcode => 'push @_ep_rtf_tmp,$_ep_rtf_ndx+1', 
			    },
                            ) ;

    $self -> AddRTFCmd ('MERGESEQ',
                            { 
                            perlcode => '_ep_rp(%$x%,$_ep_rtf_ndx+1);', 
			    },
                            { 
                            'nodename' => '::::MERGESEQ',
                            'cdatatype' => 0,
			    },
                            { 
                            perlcode => 'push @_ep_rtf_tmp,$_ep_rtf_ndx+1', 
			    },
                            ) ;

    $self -> AddRTFCmd ('IF',
                            { 
                            perlcode => '@_ep_rtf_tmp=();%>\'-1% =~ /^\s*(.*?)\s*$/ ; $_ep_rtf_preif=$1;', 
                            compiletimeperlcode => q[$_ep_rtf_inside = 1 ; $_ep_rtf_code = '{ my $itmp = $true?$_ep_rtf_tmp[3]:$_ep_rtf_tmp[4]; _ep_rp($x, \'{\'.$_ep_rtf_preif.(($itmp =~ /^\\\\\\\\/) || !$_ep_rtf_preif?$itmp:" $itmp").\'}\');}'  ;  $_ep_rtf_cmd = 1 ; ],
                            'removenode'  => 1,
			    },
                            { 
                            'nodename' => '::::IF',
                            'cdatatype' => 0,
			    },
                            ) ;

    $self -> AddRTFCmd ('NEXTIF',
                            { 
                            perlcode => '@_ep_rtf_tmp=();', 
                            compiletimeperlcode => q[$_ep_rtf_inside = 1 ; $_ep_rtf_code = '$_ep_rtf_ndx++ if ($true); ' ;  $_ep_rtf_cmd = 1 ;],
                            'removenode'  => 1,
			    },
                            { 
                            'nodename' => '::::NEXTIF',
                            'cdatatype' => 0,
			    },
                            ) ;

    $self -> AddRTFCmd ('SKIPIF',
                            { 
                            perlcode => '@_ep_rtf_tmp=();', 
                            compiletimeperlcode => q[$_ep_rtf_inside = 1 ; $_ep_rtf_code = '$_ep_rtf_ndx+=2 if ($true); ' ;  $_ep_rtf_cmd = 1 ; ],
                            'removenode'  => 1,
			    },
                            { 
                            'nodename' => '::::NEXTIF',
                            'cdatatype' => 0,
			    },
                            ) ;
    }



sub Var2Code

    {
    my $var = shift ;
    $var =~ s/(\r|\n)//g ;  # variablename can contain \r and/or \n !!!
    my @parts = split (/\./, $var) ;
    return '' if (!@parts) ;
    my $code = '$param[$_ep_rtf_ndx]' ;

    foreach (@parts)
        {
        if (/^\d+/)
            { $code .= "[$_]" }
        else
            { $code .= "{'$_'}" }
        }
    return $code ;
    }

# Variablename inside of a command

%Var = (
    '-lsearch' => 1,
    'Varname' => 
        {
        'contains'   => "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789.\r\n",
        #'inside'     => \%Varseparator,
        #'inside'     => \%Varinside,
        'cdatatype' => ntypTag,
        'nodename'   => ':{:}:full_var',
        'procinfo'   => {
            'embperl' => {
                compiletimeperlcode => q[$Embperl::req -> component -> code (Embperl::Syntax::RTF::Var2Code (%#'0%)) ;],
                },
            },

        },
    'VarnameComment' => 
        {
        text => '\\\\*',
        'cdatatype' => 0,
        'contains'   => "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789.\r\n",
        },
    ) ;


%Inside = () ;


%ParaBlockInside = (
    '-lsearch' => 1,
    'RTF block' => {
	'text' => '{',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
        'cdatatype' => ntypCDATA,
        'removespaces' => 0,
	'inside' => \%ParaBlockInside,
        'procinfo'   => {
            'embperl' => {
                },
            },
        },
    'RTF field' => {
	'text' => '{\field',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
	#'cdatatype' => ntypAttrValue,
	'insidemustexist' => 1,
	'inside' => \%FieldStart,
        'procinfo'   => {
            'embperl' => {
                },
            },
        },
    ) ;


# Start of commands

%CmdStart = (
    '-lsearch' => 1,
    'RTF block cmd'    => {
	'text'	   => '{',
	'end'	   => '}',
	'unescape' => 1,
        'nodetype'  => ntypStartEndTag,
        'removespaces' => 2,
        #'cdatatype' => ntypCDATA,
	#'cdatatype' => ntypAttrValue,
        'nodename' => '!:',
	'inside'  => {%ParaBlockInside,}, 
        'procinfo'   => {
            'embperl' => {
                compiletimeperlcodeend => q[ $Embperl::req -> component -> code ('') if (!$_ep_rtf_inside || $_ep_rtf_cmd) ; $_ep_rtf_cmd = 0 ;],
                perlcodeend => q[ { my $tmp = %#'0% ; if ($tmp =~ /\"\s*$/) { $tmp =~ s/\\\\/\\\\\\\\/g ; push @_ep_rtf_tmp, Text::ParseWords::quotewords('\s+', 0, $tmp) } else { push @_ep_rtf_tmp,$tmp } }], 
                },
            },
#        'procinfo'   => {'embperl' => {}},
        },
    'RTF field' => {
	'text' => '{\field',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
	'insidemustexist' => 1,
	'inside' => \%FieldStart,
        'procinfo'   => {
            'embperl' => {
                compiletimeperlcode => q[$_ep_rtf_inside++ if ($_ep_rtf_inside) ; ],
                compiletimeperlcodeend => q[ if ($_ep_rtf_inside) { $_ep_rtf_inside-- ; if ($_ep_rtf_inside == 0) { $Embperl::req -> component -> code ($_ep_rtf_code) ; } } ],
                },
            },
        },
    
    ) ;

# Field start and end

%FieldStart = (
    '-lsearch' => 1,
    'RTF block inside'    => {
	'text' => '{',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
        'cdatatype' => ntypCDATA,
        'removespaces' => 0,
	'inside' => \%Block,
        },
    'RTF fieldstart' => {
	'text'	   => '{\*\fldinst',
	'end'	   => '}',
        'nodename' => '!:',
        'nodetype'  => ntypStartEndTag,
        #'cdatatype' => ntypCDATA,
	#'cdatatype' => ntypAttrValue,
	'inside'  => \%CmdStart,
        'procinfo'   => {'embperl' => {}},
        },
    'RTF fieldend' => {
	'text'	   => '{\fldrslt',
	'end'	   => '}',
        'nodename' => '!',
	'cdatatype' => ntypAttrValue,
	'inside'  => \%BlockInside,
        },
    ) ;


=pod

=begin comment

    'RTF first paragraph' => {
	'text' => '\pard',
	'end'  => '}',
        'nodename' => '!:::\pard:',
	'nodetype' => ntypStartTag,
	'inside' => \%Block,
        'procinfo'   => {
            'embperl' => {
                perlcode => q[ do { ],
                perlcodeend => q[ $_ep_rtf_ndx++;} while ($param[$_ep_rtf_ndx]) ; ],
                mayjump => 1,
                },
            },
        },

=end comment

=cut

# Finds the first paragraph

%Para = (
    '-lsearch' => 1,
    'RTF field' => {
	'text' => '{\field',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
	#'cdatatype' => ntypAttrValue,
	'insidemustexist' => 1,
	'inside' => \%FieldStart,
        'procinfo'   => {
            'embperl' => {
                },
            },
        },
    %ParaBlockInside,
    ) ;

%RTF = (
    '-lsearch' => 1,
    'RTF mainblock' => {
	'text' => '{\rtf1',
	'end'  => '}',
        'nodename' => '!:{\rtf1:::}',
        'nodetype'  => ntypStartEndTag,
        'cdatatype' => ntypCDATA,
        'removespaces' => 0,
	'inside' => \%Block,
        'procinfo'   => {
            'embperl' => {
                perlcode => q[ my @_ep_rtf_stack ; do { ],
                perlcodeend => q[ $_ep_rtf_ndx++;} while ($param[$_ep_rtf_ndx]) ; ],
                mayjump => 1,
                },
            },
        },
    'RTF field' => {
	'text' => '{\field',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
	'insidemustexist' => 1,
	'inside' => \%FieldStart,
        'procinfo'   => {
            'embperl' => {
                },
            },
        },
    ) ;

# Basic definition of Block in a RTF file

#print "---------\n" ;
#foreach (@_ep_rtf_tmp) { print "<$_>\n" ; } ;                                                 


%Block = (
    '-lsearch' => 1,
#    'RTF block' => {
#	'text' => '{',
#	'end'  => '}',
#        'nodename' => '!:{:}:',
#	'cdatatype' => ntypAttrValue,
#	#'forcetype' => ntypAttrValue,
#        'removespaces' => 0,
#	'inside' => \%Block,
#        },
    'RTF block' => {
	'text' => '{',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
        'cdatatype' => ntypCDATA,
        'removespaces' => 0,
	'inside' => \%Block,
        'procinfo'   => {
            'embperl' => {},
                },
        },
    'RTF field' => {
	'text' => '{\field',
	'end'  => '}',
        'nodename' => '!:{:::}',
        'nodetype'  => ntypStartEndTag,
	'insidemustexist' => 1,
	'inside' => \%FieldStart,
        'procinfo'   => {
            'embperl' => {
                compiletimeperlcode => q[$_ep_rtf_inside++ if ($_ep_rtf_inside) ; ],
                perlcodeend => '%$x%', 
                compiletimeperlcodeend => q[#!- 
                    if ($_ep_rtf_inside) 
                        { 
                        $_ep_rtf_inside-- ; 
                        if ($_ep_rtf_inside == 0) 
                            {  
                            my $x = $Embperl::req -> component -> code ;
                            $_ep_rtf_code =~ s/\$x/$x/g ;

                            $Embperl::req -> component -> code (q[
                                             {

                                             $_ep_rtf_tmp[0] =~ s/\\\\\\\\[0-9a-zA-Z]+\s*//g ;
                                             $_ep_rtf_tmp[1] =~ s/\\\\\\\\[0-9a-zA-Z]+\s*//g ;
                                             if ($_ep_rtf_tmp[0] =~ /^\s*(.+?)\s*(=|<|>)$/)
                                                {
                                                unshift @_ep_rtf_tmp, $1 ;
                                                $_ep_rtf_tmp[1] = $2 ;
                                                }
                                             if ($_ep_rtf_tmp[1] =~ /^(=|<|>)\s*\"?\s*(.+?)\s*$/)
                                                {
                                                unshift @_ep_rtf_tmp, $_ep_rtf_tmp[0] ;
                                                $_ep_rtf_tmp[1] = $1 ;
                                                $_ep_rtf_tmp[2] = $2 ;
                                                }
                                              if (!$_ep_rtf_tmp[1])
                                                {
                                                my $tmp = shift @_ep_rtf_tmp ;
                                                $_ep_rtf_tmp[0] = $tmp ;
                                                }
                                              if ($_ep_rtf_tmp[4] =~ /^(\\\\\\\\[0-9a-zA-Z]+\s*)+$/)
                                                {
                                                $_ep_rtf_tmp[4] = $_ep_rtf_tmp[5] ;
                                                }

                                             my $op = $_ep_rtf_tmp[1] ;
                                             if ($op eq '=')
                                                { $true = $_ep_rtf_tmp[0] eq $_ep_rtf_tmp[2] }
                                             elsif ($op eq '<')
                                                { $true = $_ep_rtf_tmp[0] lt $_ep_rtf_tmp[2] }
                                             elsif ($op eq '>')
                                                { $true = $_ep_rtf_tmp[0] gt $_ep_rtf_tmp[2] }
                                             elsif ($op eq '<=')
                                                { $true = $_ep_rtf_tmp[0] le $_ep_rtf_tmp[2] }
                                             elsif ($op eq '>=')
                                                { $true = $_ep_rtf_tmp[0] gt $_ep_rtf_tmp[2] }
                                             elsif ($op eq '!=')
                                                { $true = $_ep_rtf_tmp[0] ne $_ep_rtf_tmp[2] }
                                             elsif ($op eq '<>')
                                                { $true = $_ep_rtf_tmp[0] ne $_ep_rtf_tmp[2] }

                                             ] . $_ep_rtf_code . '}') ;
                            }
                        } 
                    else
                        {
                        $Embperl::req -> component -> code ('') ;
                        }
                    ],
                },
            },
        },

    'RTF escape open' => {
	'text' => '\\{',
	'nodename' => '\\{',
        'nodetype' => ntypCDATA,
        },
    'RTF escape close' => {
	'text' => '\\}',
	'nodename' => '\\}',
        'nodetype' => ntypCDATA,
        },

    ) ;

# Block inside of a command that should be deleted in the output

%BlockInside = (
    '-lsearch' => 1,
    'RTF block' => {
	'text' => '{',
	'end'  => '}',
        'nodename' => '!',
	'cdatatype' => ntypAttrValue,
	'inside' => \%BlockInside,
        },
    ) ;


1;
=pod

=begin comment

                            #$Embperl::req -> component -> code ($_ep_rtf_code) ;

                            my $x = $Embperl::req -> component -> code ;
                            my ($op, $cmp, $a, $b) = XML::Embperl::DOM::Node::iChildsText (%$q%,%$x%,1) =~ /\:([=<>])+\s*\"(.*?)\"(?:\s*\"(.*?)\"\s*\"(.*?)\")?/ ;
                            
                            if ($op eq '=') { $op = 'eq' }
                            elsif ($op eq '<') { $op = 'lt' }
                            elsif ($op eq '>') { $op = 'gt' }
                            elsif ($op eq '>=') { $op = 'ge' }
                            elsif ($op eq '<=') { $op = 'le' }

                            print "\n#" . __LINE__ . " op = $op cmp = $cmp a = $a b = $b code=$_ep_rtf_code tmp=$_ep_rtf_tmp 0=$param[0]{'adressen_anrede'} ndx=$_ep_rtf_ndx eval=qq[$_ep_rtf_code]\n" ;
                            $_ep_rtf_code =~ s/\$a/q\[$a\]/g ;
                            $_ep_rtf_code =~ s/\$b/q\[$b\]/g ;
                            $_ep_rtf_code =~ s/\$cmp/q\[$cmp\]/g ;
                            $_ep_rtf_code =~ s/\$op/$op/g ;
                            $_ep_rtf_code =~ s/\$x/$x/g ;
                            print "result=$_ep_rtf_code\n" ;
                            
                            warn "RTF IF syntax error. Missing operator" if (!$op) ;

=end comment

=cut



__END__

=pod

=head1 NAME

Embperl::Syntax::RTF - define syntax for RTF files

=head1 SYNOPSIS


=head1 DESCRIPTION

Class derived from Embperl::Syntax to define the syntax for 
RTF files. RTF files can be read and written by various word processing
programs. This allows you to create dynamic wordprocessing documents or
let process serial letters thru Embperl.

Currently Embperl regocnices the fields C<DOCVARIABLE>, C<MERGEFIELD> and
C<NEXT>. Variablenames are resolved as hash keys to $param[0] e.g. C<foo.bar>
referes to C<$param[0]{foo}{bar}>, the C<@param> Array can by set via the
C<param> parameter of the C<Execute> function. C<NEXT> moves to the next element
of the @param array. If the end of the document is reached, Embperl repeats
the document until all element of @param are processed. This can for example
be use to tie a database table to @param and generate a serial letter.

NOTE: Extenting this syntax to support full Embperl support (like embedding Perl
into RTF file is planned, but not implemented yet)

=head1 Example for generating a serial letter from a database


  use DBIx::Recordset ;
  use Embperl ;

  *set = DBIx::Recordset -> Search({'!DataSource' => $db, '!Table' => 'address', '!WriteMode' => 0}) ;

  die DBIx::Recordset -> LastError if (DBIx::Recordset -> LastError) ;

  Embperl::Execute ({'inputfile' => 'address.rtf', param => \@set, syntax => 'RTF'}) ;


  # if your database table contains fields 'name' and 'street' you can now simply insert a
  # fields call 'name' and 'street' in your RTF file and Embperl will repeat the document
  # until all records are outputed


=head1 Methods

I<Embperl::Syntax::RTF> defines the following methods:

=head2 Embperl::Syntax::RTF -> new  /  $self -> new

Create a new syntax class. This method should only be called inside a constructor
of a derived class.


=head2 AddRTFCmd ($cmdname, $procinfo)

Add a new RTF command with name C<$cmdname> and use processor info from
C<$procinfo>. See I<Embperl::Syntax> for a definition of procinfo.

=head2 AddRTFCmdWithEnd ($cmdname, $endname, $procinfo)

Add a new RTF command with name C<$cmdname> and use processor info from
C<$procinfo>. Addtionaly specify that a matching C<$endname> RTF command
must be found to end the block, that is started by this RTF command.
See I<Embperl::Syntax> for a definition of procinfo.

=head2 AddRTFCmdBlock ($cmdname, $endname, $procinfostart, $procinfoend)

Add a new RTF command with name C<$cmdname> and and a second RTF command
C<$endname> which ends the block that is started by C<$cmdname>.
Use processor info from C<$procinfo>.
See I<Embperl::Syntax> for a definition of procinfo.



=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

Embperl::Syntax
