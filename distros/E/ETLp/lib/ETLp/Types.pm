package ETLp::Types;

use MooseX::Declare;

=head1 NAME

ETLp::Types - define types for parameter checking

=head1 DESCRIPTION

Any non core Moose types must be defined before they can be used for
checks on method parameters

=cut

class ETLp::Types {
    use Moose::Util::TypeConstraints;
    
    class_type('DateTime');
    class_type('ETLp::Schema::Result::EtlpJob');
    class_type('ETLp::Schema::Result::EtlpItem');
    class_type('ETLp::Schema::Result::EtlpFileProcess');

    # Valid Oracle SQL*Loader modes 
    subtype 'SQLLoaderMode'
        => as 'Str'
        => where { /^(?:append|truncate|insert|replace)$/i };
       
    subtype 'PositiveInt'
        => as 'Int'
        => where { $_ > 0 }
        => message { "The number you provided, $_, was not a positive number" };
};

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut
