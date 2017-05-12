#============================================================= -*-perl-*-
#
# Kite
#
# DESCRIPTION
#   Front-end for the Kite::* modules.  Currently just a placeholder
#   for a version number for the bundle.
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
#   $Id: Kite.pm,v 1.3 2000/10/17 11:58:16 abw Exp $
#
#========================================================================
 
package Kite;

require 5.004;

use strict;
use Kite::Base;
use base qw( Kite::Base );
use vars qw( $VERSION $ERROR $DEBUG );

$VERSION = 0.4;
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';


sub profile {
    my $class = shift;
    require Kite::Profile;
    return Kite::Profile->new(@_)
	|| $class->error($Kite::Profile::ERROR);
}


sub xml2ps {
    my $class = shift;
    require Kite::XML2PS;
    return Kite::XML2PS->new(@_)
	|| $class->error($Kite::XML2PS::ERROR);
}

sub xml_parser {
    my $class = shift;
    require Kite::XML::Parser;
    return Kite::XML::Parser->new(@_)
	|| $class->error($Kite::XML::Parser::ERROR);
}

1; 

__END__

=head1 NAME

Kite - collection of modules useful in Kite design and construction.

=head1 SYNOPSIS

    use Kite;

    my $profile = Kite->profile(...)
	|| die $Kite::ERROR;

    my $xml2ps = Kite->xml2ps(...)
        || die $Kite::ERROR;

    my $xml_parser = Kite->xml_parser(...)
        || die $Kite::ERROR;

=head1 DESCRIPTION

The Kite::* modules are a collection of Perl modules and scripts
written to help with various tasks in the design and construction of
traction kites.

The Kite module acts as a general interface to the other modules in 
the collection, providing factory methods for loading and instantiating
them.

=head1 METHODS

=head2 profile()

Loads the Kite::Profile module and calls the new() constructor.  All 
parameters are forwarded to the constructor.

This example:

    use Kite;
    
    my $profile = Kite->profile( name => 'My Profile', ... )
        || die $Kite::ERROR, "\n";

is equivalent to:

    use Kite::Profile;

    my $profile = Kite::Profile->new( name => 'My Profile', ... )
        || die $Kite::Profile::ERROR, "\n";

=head2 xml2ps()

Loads the Kite::XML2PS module and calls the new() constructor.  All 
parameters are forwarded to the constructor as per the previous 
example.

=head2 xml_parser()

Loads the Kite::XML::Parser module and calls the new() constructor.  All 
parameters are forwarded to the constructor as per the previous 
examples.

=head1 MODULES

The following modules are distributed with the Kite bundle.

=head2 Kite

Front-end for the Kite::* modules.  Contains factory methods for loading 
modules and instantiating objects of other Kite::* classes.

=head2 Kite::Base

Base class implementing common functionality such as error reporting.

=head2 Kite::Profile

Module defining an object class used to represent and manipulate
2D profiles.

=head2 Kite::XML2PS

Module to convert a curve definition from OpenKite XML format to
PostScript.  Provides automatic page tiling, path following text,
registration marks, etc.

=head2 Kite::XML::Parser

Module for parsing an XML file and generating a representative tree of
node (element) objects.

=head2 Kite::XML::Node

Base class for XML element nodes created by Kite::XML::Parser.

=head2 Kite::XML::Node::Kite

Derived node elements specific to Kite markup (e.g. Kite, Part,
Outline, Curve, Point, etc.)

=head2 Kite::PScript::Defs

Module defining a number of PostScript definitions useful for
generating PostScript documents for kite part layout, etc.

=head1 SCRIPTS

The following scripts are distributed with the Kite bundle.

=head2 okprof

Utility script providing a user interface to the Kite::Profile module.
Allows 2D profiles to be loaded and manipulated via simple commands.
See 'B<perldoc okprof>' or 'B<okprof -h>'.

=head2 okxml2ps

Utility script for converting XML kite part definition and layout 
markup to PostScript.  Uses the Kite::XML2PS module.

=head1 AUTHORS

Andy Wardley E<lt>abw@kfs.orgE<gt> is the primary author and current
maintainer of the Kite::* bundle.

Simon Stapleton E<lt>simon@tufty.co.ukE<gt> is another key contributor.

=head1 VERSION

This is version 0.4 of the Kite bundle.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<Kite::Profile>, L<Kite::XML2PS>, L<Kite::XML::Parser>,
L<Kite::XML::Node>, L<Kite::XML::Node::Kite>, L<Kite::PScript::Defs>, 
L<Kite::Base>, L<okprof> and L<okxml2ps>.

=cut

