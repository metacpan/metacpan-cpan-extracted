
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
#   $Id: Text.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 
package Embperl::Syntax::Text ;

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

    return $self ;
    }




1; 

__END__

=pod

=head1 NAME

Embperl::Syntax::Text - define text syntax for Embperl

=head1 SYNOPSIS

Execute ({inputfile => 'sometext.htm', syntax => 'Text'}) ;

=head1 DESCRIPTION

This syntax does simply literal pass the text thru. That's useful if you
want to include text, without any interpretation. (e.g. with EmbperlObject)

=head1 Author

Gerald Richter <richter at embperl dot org>

=head1 See Also

Embperl::Syntax


=cut


