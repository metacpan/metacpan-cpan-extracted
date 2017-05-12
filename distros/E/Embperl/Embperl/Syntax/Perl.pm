
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
#   $Id: Perl.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 
package Embperl::Syntax::Perl ;

use Embperl::Syntax qw{:types} ;
use Embperl::Syntax ;

use strict ;
use vars qw{@ISA} ;

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
    my $class = shift ;

    my $self = Embperl::Syntax::new ($class) ;

    if (!$self -> {-perlInit})
        {
        $self -> {-perlInit} = 1 ;    
        
        $self -> AddInitCode (undef, '$_ep_node=%$x%+2; %#1% ;', undef,
                            {
                            removenode  => 32,
                            compilechilds => 0,
                            }) ;

        }


    return $self ;
    }




1; 

__END__

=pod

=head1 NAME

Embperl::Syntax::Perl - define Perl syntax for Embperl

=head1 SYNOPSIS

Execute ({inputfile => 'code.pl', syntax => 'Perl'}) ;

=head1 DESCRIPTION

This syntax cause Embperl to interpret the whole file as Perl script
without any markup.

=head1 Author

Gerald Richter <richter at embperl dot org>


=cut


