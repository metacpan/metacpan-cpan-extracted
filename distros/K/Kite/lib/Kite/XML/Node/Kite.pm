#============================================================= -*-perl-*-
#
# Kite::XML::Node::Kite
#
# DESCRIPTION
#   XML node representing a kite made of many parts.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# VERSION 
#   $Id: Kite.pm,v 1.2 2000/10/17 12:19:28 abw Exp $
#
#========================================================================
 
package Kite::XML::Node::Kite;

require 5.004;

use strict;
use Kite::XML::Node;
use base qw( Kite::XML::Node );
use vars qw( $ATTRIBUTES $ELEMENTS $VERSION $ERROR $AUTOLOAD );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$ERROR   = '';
$ATTRIBUTES  = {
    name  => '',
    title => '',
};
$ELEMENTS = {
    part => 'Kite::XML::Node::Part+',
};


#------------------------------------------------------------------------
package Kite::XML::Node::Part;

use base qw( Kite::XML::Node );
use vars qw( $ERROR $ATTRIBUTES $ELEMENTS );

$ERROR   = '';
$ATTRIBUTES  = {
    name => undef,
};
$ELEMENTS = {
    outline => 'Kite::XML::Node::Outline',
    markup  => 'Kite::XML::Node::Markup',
    layout  => 'Kite::XML::Node::Layout',
};


#------------------------------------------------------------------------
package Kite::XML::Node::Outline;

use base qw( Kite::XML::Node );
use vars qw( $ERROR $ELEMENTS );

$ERROR   = '';
$ELEMENTS = {
    curve => 'Kite::XML::Node::Curve+',
};

#------------------------------------------------------------------------
package Kite::XML::Node::Markup;

use base qw( Kite::XML::Node );
use vars qw( $ERROR $ELEMENTS );

$ERROR   = '';
$ELEMENTS = {
    curve => 'Kite::XML::Node::Curve+',
};


#------------------------------------------------------------------------
package Kite::XML::Node::Layout;

use base qw( Kite::XML::Node );
use vars qw( $ERROR $ATTRIBUTES );

$ERROR   = '';
$ATTRIBUTES  = { 
    x => undef,
    y => undef,
    angle => 0,
};


#------------------------------------------------------------------------
package Kite::XML::Node::Curve;

use base qw( Kite::XML::Node );
use vars qw( $ERROR $ATTRIBUTES $ELEMENTS @OPTIONAL );

$ERROR   = '';
$ATTRIBUTES  = { 
    linetype => 'normal',
};
$ELEMENTS = {
    point => 'Kite::XML::Node::Point+',
    text  => 'Kite::XML::Node::Text+',
};


#------------------------------------------------------------------------
package Kite::XML::Node::Point;

use base qw( Kite::XML::Node );
use vars qw( $ERROR $ATTRIBUTES );

$ERROR   = '';
$ATTRIBUTES  = { 
    x => undef,
    y => undef,
};


#------------------------------------------------------------------------
package Kite::XML::Node::Text;

use base qw( Kite::XML::Node );
use vars qw( $ERROR $ATTRIBUTES $ELEMENTS @OPTIONAL );

$ERROR   = '';
$ATTRIBUTES  = { 
    font => '',
    size => '',
};
$ELEMENTS = {
    CDATA => 1,
};


1;

__END__
	

=head1 NAME

Kite::XML::Node::Kite - XML nodes to represent kite markup

=head1 SYNOPSIS

    package Kite::XML::Node::Kite;

=head1 DESCRIPTION

TODO

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision: 1.2 $

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<Kite::XML::Node>, <Kite::XML::Node::Curve> and 
L<Kite::XML::Parser>.

=cut


