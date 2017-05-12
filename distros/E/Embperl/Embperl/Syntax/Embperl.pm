
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
#   $Id: Embperl.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Syntax::Embperl ;

use Embperl::Syntax qw{:types} ;
use Embperl::Syntax::EmbperlHTML ;
use Embperl::Syntax::EmbperlBlocks ;

@ISA = qw(Embperl::Syntax::EmbperlBlocks Embperl::Syntax::EmbperlHTML) ;


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
    
    my $self = Embperl::Syntax::EmbperlBlocks::new ($class) ;
    Embperl::Syntax::EmbperlHTML::new ($self) ;

    return $self ;
    }


1 ;
__END__

=pod

=head1 NAME

Embperl::Syntax::Embperl - Embperl syntax module for Embperl. 

=head1 SYNOPSIS

[$ syntax Embperl $]

=head1 DESCRIPTION

This module provides the default syntax for Embperl and include all defintions
from EmbperlHTML and EmbperlBlocks.

=head1 Author

Gerald Richter <richter at embperl dot org>

=head1 See Also

Embperl::Syntax, Embperl::Syntax::EmbperlHTML, Embperl::Syntax::EmbperlBlocks

