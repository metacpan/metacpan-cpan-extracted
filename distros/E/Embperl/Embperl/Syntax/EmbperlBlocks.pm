
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
#   $Id: EmbperlBlocks.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Syntax::EmbperlBlocks ;

use Embperl::Syntax (':types') ;

use strict ;
use vars qw{@ISA %Blocks %BlocksOutput %BlocksOutputLink} ;



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
    my $self        = shift ;
    my $exchange    = shift ;

    $self = Embperl::Syntax::new ($self) ;

    if (!$self -> {-epbBlocks})
        {
        $self -> {-epbBlocks}     = $self -> CloneHash ({ %Blocks, %BlocksOutput }, ref $exchange?$exchange:undef) ;
        $self -> {-epbBlocksLink} = $self -> CloneHash ({ %Blocks, %BlocksOutputLink }, { 'unescape' => 2 }) ;

        $self -> AddToRoot ($self -> {-epbBlocks}) ;

        Init ($self, ref $exchange?$exchange:undef) ;

        $self -> AddInitCode ('use Data::Dumper;') ;
        }

    return $self ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new meta command
#
# ---------------------------------------------------------------------------------


sub AddMetaCmd

    {
    my ($self, $cmdname, $procinfo, $taginfo) = @_ ;

    my $tagtype = 'Embperl meta command' ;
    my $ttref ;
    die "'$tagtype' unknown" if (!($ttref = $self -> {-epbBlocks}{$tagtype})) ;
    my $ttfollow = ($ttref -> {'follow'} ||= {}) ;

    my $tag = $ttfollow -> {$cmdname} = { 
                                'text'      => $cmdname,
                                'nodetype'  => ntypTag,
                                'cdatatype' => ntypAttrValue,
                                'forcetype' => 1,
                                'unescape'  => 1,
                                (ref($taginfo) eq 'HASH'?%$taginfo:()),
                              } ;
    $tag -> {'procinfo'} = { $self -> {-procinfotype} => $procinfo } if ($procinfo) ;

    die "'$tagtype' unknown" if (!($ttref = $self -> {-epbBlocksLink}{$tagtype})) ;
    $ttfollow = ($ttref -> {'follow'} ||= {}) ;

    my $tag2 = $ttfollow -> {$cmdname} = { 
                                'text'      => $cmdname,
                                'nodetype'  => ntypTag,
                                'cdatatype' => ntypAttrValue,
                                'forcetype' => 1,
                                'unescape'  => 2,
                                (ref($taginfo) eq 'HASH'?%$taginfo:()),
                              } ;
    $tag2 -> {'procinfo'} = { $self -> {-procinfotype} => $procinfo } if ($procinfo) ;

    return $tag ;
    }


# ---------------------------------------------------------------------------------
#
#   Add new meta command that has an corresponding end meta command
#
# ---------------------------------------------------------------------------------


sub AddMetaCmdWithEnd

    {
    my ($self, $cmdname, $endname, $procinfo) = @_ ;

    my $tag = $self -> AddMetaCmd ($cmdname, $procinfo, {'endtag' => $endname} ) ;

    return $tag ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new meta command with start and end
#
# ---------------------------------------------------------------------------------


sub AddMetaCmdBlock

    {
    my ($self, $cmdname, $endname, $procinfostart, $procinfoend) = @_ ;

    my $tag ;
    my $pinfo = { %$procinfostart, 'stackname' => 'metacmd', 'push' => $cmdname };
    $tag = $self -> AddMetaCmd ($cmdname, $pinfo, {'endtag' => $endname} ) ;

    $pinfo = { %$procinfoend, 'stackname' => 'metacmd', 'stackmatch' => $cmdname };
    $tag = $self -> AddMetaCmd ($endname, $pinfo) ;

    return $tag ;
    }

# ---------------------------------------------------------------------------------
#
#   Add new block 
#
# ---------------------------------------------------------------------------------


sub AddMetaStartEnd 

    {
    my ($self, $cmdname, $endname, $procinfostart, $taginfostart) = @_ ;

    my $tag ;
    my $pinfo ;

    $tag = $self -> AddMetaCmd ($cmdname, $procinfostart, {'nodetype' => &ntypStartTag, (ref($taginfostart) eq 'HASH'?%$taginfostart:())}) ;

    $tag = $self -> AddMetaCmd ($endname, undef, {'nodetype' => &ntypEndTag, 'starttag' => $cmdname}) ;

    return $tag ;
    }


    

# ---------------------------------------------------------------------------------
#
#   Add new simple html tag (override to add meta commands inside html tags)
#
# ---------------------------------------------------------------------------------


sub AddTag

    {
    my $self = shift ;

    my $tag = $self -> Embperl::Syntax::HTML::AddTag (@_) ;

    #### add the Embperl Block inside the new HTML Tag ####

    $tag -> {inside} ||= {} ;
    my $inside = $tag -> {inside} ;    

    while (my ($k, $v) = each (%{$self -> {-epbBlocks}}))
        {
        $inside -> {$k} = $v ;
        }

    if (!$self -> {-epbHTMLInit})
        {
        #### if not already done add the Embperl Block inside the HTML Attributes ####

        $self -> {-epbHTMLInit} = 1 ;

        my $unescape = 0 ;
        foreach ('', 'Link')
            {
            my $attr   = $self -> {"-htmlAssignAttr$_"} ;
            my $blocks = $self -> {"-epbBlocks$_"} ;
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
        my $blocks = $self -> {"-epbBlocks"} ;
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
#   Definitions for Embperl Blocks
#
###################################################################################

sub Init

    {
    my ($self) = @_ ;

    $self -> AddMetaCmdWithEnd ('if', 'endif', 
                            {
                            perlcode    => 'if (%&<noname>%) { ', 
                            removenode  => 10,
                            mayjump     => 1,
                            stackname   => 'metacmd',
                            'push'      => 'if',
                            }) ;

    $self -> AddMetaCmdWithEnd  ('else', 'endif', 
                            { 
                            perlcode => '} else {',
                            removenode => 10,
                            mayjump     => 1,
                            stackname   => 'metacmd',
                            stackmatch  => 'if',
                            'push'      => 'if',
                            }) ;
    $self -> AddMetaCmdWithEnd  ('elsif', 'endif',
                            { 
                            perlcode => '} elsif (%&<noname>%) { ', 
                            removenode => 10,
                            mayjump     => 1,
                            stackname   => 'metacmd',
                            stackmatch  => 'if',
                            'push'      => 'if',
                            }) ;
    $self -> AddMetaCmd ('endif',
                            { 
                            perlcode => '}', 
                            removenode => 10,
                            mayjump     => 1,
                            stackname   => 'metacmd',
                            stackmatch  => 'if',
                            }) ;
    $self -> AddMetaCmdBlock  ('while', 'endwhile', 
                { 
                perlcode => 'while (%&<noname>%) { ', 
                removenode => 10,
                mayjump     => 1,
                },
                { 
                perlcode => '};', 
                removenode => 10,
                mayjump     => 1,
                }) ;
    $self -> AddMetaCmdBlock  ('foreach', 'endforeach',
                { 
                perlcode => 'foreach %&<noname>% { ', 
                removenode => 10,
                mayjump     => 1,
                },
                { 
                perlcode => '};', 
                removenode => 10,
                mayjump     => 1,
                }) ;
    $self -> AddMetaCmdBlock  ('do', 'until',
                { 
                perlcode => 'do { ', 
                removenode => 10,
                mayjump     => 1,
                },
                { 
                perlcode => '} until (%&<noname>%) ; ',
                removenode => 10,
                mayjump     => 1,
                }) ;
    $self -> AddMetaCmd ('var',
                { 
                compiletimeperlcode => 'use strict ; use vars qw{%%CLEANUP %&<noname>%} ; map { $CLEANUP{substr($_,1)} = 1 } qw{%&<noname>%} ;', 
                perlcode => 'use strict ;', 
                removenode => 3,
                }) ;
    $self -> AddMetaCmd ('next',
                { 
                perlcode => 'next;', 
                removenode => 3,
                }) ;
    $self -> AddMetaCmd ('last',
                { 
                perlcode => 'last;', 
                removenode => 3,
                }) ;
    $self -> AddMetaCmd ('redo',
                { 
                perlcode => 'redo;', 
                removenode => 3,
                }) ;
    $self -> AddMetaCmd ('next',
                { 
                perlcode => 'next;', 
                removenode => 3,
                }) ;
    $self -> AddMetaCmd ('hidden',
                { 
                perlcode => '_ep_hid(%$n%,%&\'<noname>%);', 
                removenode => 8,
                }) ;
    $self -> AddMetaCmd ('dump',
                { 
                compiletimeperlcode => q[ 
                   {
                   my $line = __LINE__ - 2 ;
                   my $code ;
                   my $out ;
                   my ($dest, @vars) = split (/\s*,\s*/, %&'<noname>%) ;
                   if ($dest ne 'pre' && $dest ne 'out' && $dest ne 'log' && $dest ne 'err')
                        {
                        unshift @vars, $dest ;
                        $dest = 'pre' ;
                        }

                   if ($vars[0] =~ /^\'|\"/)
                        {
                        $out = (shift @vars) . '.' ;
                        } 
                   $out = "Data::Dumper -> Dump ([" . join (',', map { s/^(\@|\%%)/\\\\$1/; $_ } @vars) . "],['" . join ("','", @vars) . "'])" ;
                   if ($dest eq 'pre')
                        {
                        $code = '%$c%' . "{ local \$escmode = 0; print OUT '<pre>' ; \$escmode = 7; my \$o = $out ; print OUT \$o, \"\\n\"; \$escmode = 0; print OUT \"<pre>\\n\" ; }" ; 
                        }
                   elsif ($dest eq 'out')
                        {
                        $code = '%$c%' . "{my \$o = $out ; print OUT \$o, \"\\n\"; }" ; 
                        }
                   elsif ($dest eq 'err')
                        {
                        $code = "{my \$o = $out . ' in " .  __FILE__ . " line " . $line . "'. \"\\n\"; print STDERR \$o ;}" ; 
                        }
                   elsif ($dest eq 'log')
                        {
                        $code = "{my \$o = $out . ' in " .  __FILE__ . " line " . $line . "'. \"\\n\"; print LOG \$o ;}" ; 
                        }
                   $Embperl::req -> component -> code ($code) ;
                   }
                   ],
                removenode => 3,
                compilechilds => 0,
                }) ;
    $self -> AddMetaCmd ('syntax',
                { 
                compiletimeperlcode => '$Embperl::req -> component -> syntax (Embperl::Syntax::GetSyntax(%&\'<noname>%, $Embperl::req -> component -> syntax -> name));', 
                removenode => 3,
                },
                { 
                parsetimeperlcode => '$Embperl::req  -> component -> syntax (Embperl::Syntax::GetSyntax(\'%%\', $Embperl::req -> component -> syntax -> name)) ;', 
                },
                ) ;
    $self -> AddMetaStartEnd ('sub', 'endsub',
                { 
                perlcode => 'sub _ep_sub_ ', 
                compiletimeperlcode => q[ 
                                          my $args = %&'<noname>% ;
                                            if ($args =~ /^([^ ]+)\s*\((.*?)\)\s*(.*?)$/s)
                                                {
                                                $Embperl::req -> component -> code ("sub _ep_sub_$1 { my ($2) = \@_ ; $3 ") ;
                                                }
                                            else
                                                {
                                                $args =~ /^([^ ]+)\s*(.*?)$/s ;
                                                $Embperl::req -> component -> code ("sub _ep_sub_$1 { $2 ") ;
                                                }
                                         ], 
                perlcodeend => ' };  sub #subname# { my @_ep_save ; Embperl::Cmd::SubStart($_ep_DomTree,%$q%,\\@_ep_save); my @_ep_ret ; my $_ep_ret ;  if (wantarray()) { @_ep_ret = _ep_sub_#subname# (@_)}else {$_ep_ret = _ep_sub_#subname# (@_);} Embperl::Cmd::SubEnd($_ep_DomTree,\\@_ep_save); return wantarray()?@_ep_ret:$_ep_ret } ; $_ep_exports{%^"subname%} = \&#subname# ; ', 
                compiletimeperlcodeend => q[ 
                                          my $args = %^'subname% ;
                                          $args =~ s/\s+.+$//s ;
                                          my $code = $Embperl::req -> component -> code ;
                                          $code =~ s/#subname#/$args/g ;
                                          $Embperl::req -> component -> code ($code);
                                         ], 
                removenode => 10,
                mayjump     => 1,
                stackname2   => 'subname',
                push2        => '%&<noname>%',
                switchcodetype => 2,
                callreturn => 1,
                },
                {
                addfirstchild => 1,
                },
                ) ;
    } 



%Blocks = (
    '-lsearch' => 1,
    'Embperl command escape' => {
        'text' => '[[',
        'nodename' => '[',
        'nodetype' => ntypCDATA,
        },
    'Embperl meta command' => {
        'text' => '[$',
        'end'  => '$]',
        'unescape' => 1,
        },
     'Embperl code' => {
        'text' => '[-',
        'end'  => '-]',
        'unescape' => 1,
        'procinfo' => {
            embperl => { 
                        perlcode    => [
                                '%$c%if (!defined (scalar(do{' . "\n" . '%#~0:$col%' . "\n" . '}))) %#~-0:$row% { if ($col == 0) { _ep_dcp (%^*htmltable%) ; last l%^*htmltable% ; } else { _ep_dcp (%^*htmlrow%) ; last l%^*htmlrow% ; }}',
                                '%$c%if (!defined (scalar(do{' . "\n" . '%#~0:$col%' . "\n" . '}))) { _ep_dcp (%^*htmlrow%) ; last l%^*htmlrow% ; }',
                                '%$c%if (!defined (scalar(do{' . "\n" . '%#~0:$row%' . "\n" . '}))) { _ep_dcp (%^*htmltable%) ; last l%^*htmltable% ; }',
                                '%$c%{' . "\n" . '%#0%' . "\n" . ';}',
                                ],
                        removenode  => 3,
                        mayjump     => 1,
                        compilechilds => 0,
                        },
            },
        },
     'Embperl global code' => {
        'text' => '[*',
        'end'  => '*]',
        'unescape' => 1,
        'procinfo' => {
            embperl => { 
                        perlcode    => '%$c%' . "\n" . '%#0%',
                        removenode  => 3,
                        mayjump     => 1,
                        compilechilds => 0,
                        },
            },
        },
     'Embperl startup code' => {
        'text' => '[!',
        'end'  => '!]',
        'unescape' => 1,
        'procinfo' => {
            embperl =>  { 
                        compiletimeperlcode => '%#0%;',
                        removenode  => 3,
                        compilechilds => 0,
                        }
            },
        },
     'Embperl comment' => {
        'text' => '[#',
        'end'  => '#]',
#        'inside' => \%MetaComment,
        'procinfo' => {
            embperl => { 
                compilechilds => 0,
                removenode  => 3, 
                },
            },
        },
     'Embperl output msg id' => {
        'text' => '[=',
        'end'  => '=]',
        'unescape' => 1,
         removespaces  => 72,
        'cdatatype' => ntypAttrValue,
        'procinfo' => {
            embperl => { 
                    perlcode => 
                        [
                        '_ep_rpid(%$x%,scalar(%&\'<noname>%));', 
			],
                    removenode  => 4,
                    compilechilds => 0,
                    }
            },
        },
      ) ;  
   
#%MetaComment = (
#    '-lsearch' => 1,
#     'Embperl comment' => {
#        'text' => '[#',
#        'end'  => '#]',
#        'inside' => \%MetaComment
#        },
#) ;


%BlocksOutput =
    (
     'Embperl output code' => {
        'text' => '[+',
        'end'  => '+]',
        'unescape' => 1,
        'procinfo' => {
            embperl => { 
                    perlcode => 
                        [
                        'if (!defined (_ep_rp(%$x%,scalar(%#~0:$col%)))) %#~-0:$row% { if ($col == 0) { _ep_dcp (%^*htmltable%) ; last l%^*htmltable% ; } else { _ep_dcp (%^*htmlrow%) ; last l%^*htmlrow% ; }}',
                        'if (!defined (_ep_rp(%$x%,scalar(%#~0:$col%)))) { _ep_dcp (%^*htmlrow%) ; last l%^*htmlrow% ; }',
                        'if (!defined (_ep_rp(%$x%,scalar(%#~0:$row%)))) { _ep_dcp (%^*htmltable%) ; last l%^*htmltable% ; }',
                        '_ep_rp(%$x%,scalar(%#0%));', 
			],
                    removenode  => 4,
                    mayjump => '%#~0:$col|$row|$cnt% %?*htmlrow% %?*htmltable%',
                    compilechilds => 0,
                    }
            },
        },
    ) ;

%BlocksOutputLink =
    (
     'Embperl output code URL' => {
        'text' => '[+',       
        'nodename' => '[+url',
        'end'  => '+]',
        'unescape' => 2,
        'procinfo' => {
            embperl => { 
                    perlcode => 
                        [
                        'if (!defined (_ep_rpurl(%$x%,scalar(%#~0:$col%)))) %#~-0:$row% { if ($col == 0) { _ep_dcp (%^*htmltable%) ; last l%^*htmltable% ; } else { _ep_dcp (%^*htmlrow%) ; last l%^*htmlrow% ; }}',
                        'if (!defined (_ep_rpurl(%$x%,scalar(%#~0:$col%)))) { _ep_dcp (%^*htmlrow%) ; last l%^*htmlrow% ; }',
                        'if (!defined (_ep_rpurl(%$x%,scalar(%#~0:$row%)))) {  _ep_dcp (%^*htmltable%) ; last l%^*htmltable% ; }',
                        '_ep_rpurl(%$x%,scalar(%#0%));', 
                        ],
                    removenode  => 4,
                    mayjump => '%#~0:$col|$row|$cnt% %?*htmlrow% %?*htmltable%',
                    compilechilds => 0,
                    }
            },
        },
    ) ;


1;


__END__

=pod

=head1 NAME

Embperl::Syntax::EmbperlBlocks - syntax for Embperl Blocks and metacommands

=head1 SYNOPSIS


=head1 DESCRIPTION

Class derived from Embperl::Syntax to define the syntax for 
Embperl Blocks and metacommands.

=head1 Methods

I<Embperl::Syntax::EmbperlBlocks> defines the following methods:

=head2 Embperl::Syntax::EmbperlBlocks -> new  /  $self -> new

Create a new syntax class. This method should only be called inside a constructor
of a derived class.


=head2 AddMetaCmd ($cmdname, $procinfo)

Add a new metacommand with name C<$cmdname> and use processor info from
C<$procinfo>. See I<Embperl::Syntax> for a definition of procinfo.

=head2 AddMetaCmdWithEnd ($cmdname, $endname, $procinfo)

Add a new metacommand with name C<$cmdname> and use processor info from
C<$procinfo>. Addtionaly specify that a matching C<$endname> metacommand
must be found to end the block, that is started by this metacommand.
See I<Embperl::Syntax> for a definition of procinfo.

=head2 AddMetaCmdBlock ($cmdname, $endname, $procinfostart, $procinfoend)

Add a new metacommand with name C<$cmdname> and and a second metacommand
C<$endname> which ends the block that is started by C<$cmdname>.
Use processor info from C<$procinfo>.
See I<Embperl::Syntax> for a definition of procinfo.



=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

Embperl::Syntax


