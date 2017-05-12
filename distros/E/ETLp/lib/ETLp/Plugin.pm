package ETLp::Plugin;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin - The base class for ETLp plugins

=head1 DESCRIPTION

All Plugins should inherit from this class:

    use MooseX::Declare;
    class My::ETLp::Plugin::WebService extends ETLp::Plugin {
        sub type {
            return 'my_web_service';
        }
        
        method run {
            .... <<code>> ....
        }
    }
    
Any plugins must provide the following methods

=head2 type

This should simply return the item type that the plugin seeks to service.
Note that the MooseX::Declare "method" keyword should bot be used

=head2 run

This is the code that performs the functionality of the plugin. If it is
an iterative plugin, it must accept the name of a file:

    method run(Str $filename) {
        .... <<code>> ....
    }

=cut

class ETLp::Plugin with ETLp::Role::Config {
    use ETLp::Exception;
    
    has 'config'        => (is => 'ro', isa => 'HashRef', required => 1);
    has 'item'          => (is => 'ro', isa => 'HashRef', required => 1);
    has 'original_item' => (is => 'ro', isa => 'HashRef', required => 1);
    has 'env_conf'      => (is => 'ro', isa => 'HashRef', required => 1);

    sub type {
        ETLpException->throw(error => "Abstract method 'type'");
    }

    method run {
        ETLpException->throw(error => "Abstract method 'run'");
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut

