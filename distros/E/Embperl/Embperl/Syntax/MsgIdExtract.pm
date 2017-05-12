
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
#   $Id: MsgIdExtract.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Syntax::MsgIdExtract ;

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
    my $self = shift ;

    $self = Embperl::Syntax::new ($self) ;

    if (!$self -> {-epbMsgIdExtract})
        {
        $self -> {-epbMsgIdExtract}     = $self -> CloneHash (\%Blocks) ;

        $self -> AddToRoot ($self -> {-epbMsgIdExtract}) ;
        }

    return $self ;
    }



%Blocks = (
    '-lsearch' => 1,
    'Embperl command escape' => {
        'text' => '[[',
        'nodename' => '[',
        'nodetype' => ntypCDATA,
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
        'procinfo' => {
            embperl => { 
                    perlcode => 
                        [
                        '$Embperl::Syntax::MsgIdExtract::Ids{%#\'0%} = q{} if (!exists ($Embperl::Syntax::MsgIdExtract::Ids{%#\'0%})) ;', 
			],
                    removenode    => 4,
                    compilechilds => 0,
                    }
            },
        },
     'Embperl output msg id gettext' => {
        'text' => 'gettext',
        'end'  => ')',
        'unescape' => 1,
        follow  => {
            'bracktes' =>
                {
                'text' => '(',
                'end'  => ')',
                follow  => {
                    'Quote ""' => 
                        {
                        'text'   => '"',
                        'end'    => '"',
                        removespaces  => 72,
                        'procinfo' => {
                            embperl => { 
                                    perlcode => 
                                        [
                                        '$Embperl::Syntax::MsgIdExtract::Ids{%#\'0%} = q{} if (!exists ($Embperl::Syntax::MsgIdExtract::Ids{%#\'0%})) ;', 
			                ],
                                    removenode    => 4,
                                    compilechilds => 0,
                                    }
                            },
                        },
                    'Quote \'\'' => 
                        {
                        'text'   => '\'',
                        'end'    => '\'',
                        removespaces  => 72,
                        'procinfo' => {
                            embperl => { 
                                    perlcode => 
                                        [
                                        '$Embperl::Syntax::MsgIdExtract::Ids{%#\'0%} = q{} if (!exists ($Embperl::Syntax::MsgIdExtract::Ids{%#\'0%})) ;', 
			                ],
                                    removenode    => 4,
                                    compilechilds => 0,
                                    }
                            },
                        },
                    },
                },
            },
        },
      ) ;  
   

1;


__END__

=pod

=head1 NAME

Embperl::Syntax::MsgIdExtract - define syntax for i18n using Embperl blocks

=head1 SYNOPSIS


=head1 DESCRIPTION

Class derived from Embperl::Syntax to define the syntax for the
internationalisation using "[= =]" Embperl blocks and metacommands.

See L<Embperl>, section I18N for details.

=head1 Methods

I<Embperl::Syntax::MsgIdExtract> defines the following methods:

=head2 Embperl::Syntax::MsgIdExtract -> new  /  $self -> new

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


