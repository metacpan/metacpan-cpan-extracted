package Gantry::Plugins::SOAP::RPC;

use strict;

use base 'Exporter';

use XML::Simple;
use SOAP::Lite;

our @EXPORT = qw(
    soap_in
    soap_out
    do_main
    do_wsdl
    return_error
);

my %registered_callbacks;

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    warn 'Use -PluginNamespace=something when you use '
        .   'Gantry::Plugins::SOAP::RPC' if ( $namespace eq 'Gantry' );

    return (
        { phase => 'pre_init', callback => \&steal_post_body }
    );
}

#-----------------------------------------------------------
# $self->steal_post_body( $r_or_cgi )
#-----------------------------------------------------------
sub steal_post_body {
    my $self     = shift;
    my $r_or_cgi = shift;

    $self->consume_post_body( $r_or_cgi );
}

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my $self        = shift;
    my $input       = $self->soap_in;
    my $action      = $input->{ action };
    my $output_data;

    $self->template_wrapper( 0 );
    $self->template_disable( 1 );
    $self->content_type( 'text/xml' );

    eval {
        $output_data = $self->$action( $input->{ data } );
    };
    if ( $@ =~ /Can't locate object method "$action"/ ) {
        return $self->return_error( "No such soap method: '$action'" );
    }
    elsif ( $@ ) {
        my $message = $@;
        return $self->return_error( "$message" );
    }

    return $self->soap_out( $action, $output_data );
} # END do_main

#-----------------------------------------------------------------
# $self->do_wsdl
#-----------------------------------------------------------------
sub do_wsdl {
    my $self = shift;

    $self->stash->view->template( 'wsdl.tt' );

    $self->stash->view->data( $self->get_soap_ops );

    delete $self->{__TEMPLATE_WRAPPER__};
    my $wsdl = $self->do_process();

    $self->template_disable( 1 );
    $self->content_type( 'text/xml' );

    return $wsdl;
} # END do_wsdl

sub soap_in {
    my $self = shift;

    my $input_struct = XMLin( $self->get_post_body );
    my $body         = $input_struct->{ 'soap:Body' };

    my ( $action )   = keys %{ $body };

    return {
        action => $action,
        data   => $body->{ $action },
    };
}

sub soap_out {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;

    my $descr  = $self->get_soap_ops();

    my $this_op;
    OP:
    foreach my $op ( @{ $descr->{ operations } } ) {
        next OP unless $op->{ name } eq $action;
        $this_op = $op;
        last OP;
    }

    if ( not defined $this_op ) {
        die "Couldn't find description of $action operation.";
    }

    my @soap_data;
    foreach my $return_descr ( @{ $this_op->{ returns } } ) {

        my $data_key  = $return_descr->{ name };
        my $data_type = $return_descr->{ type };

        my $value     = $data->{ $data_key };

        push @soap_data, SOAP::Data->new(
                name  => $data_key,
                type  => $data_type,
                value => $value,
        );
    }

    my $serializer = SOAP::Serializer->new();
    my $output     = $serializer->envelope(
            'method' => $action . "_response", @soap_data
    );

    return $output;
}

sub return_error {
    my ( $self, $error ) = @_;

    my $serializer = SOAP::Serializer->new();
    my $output     = $serializer->envelope(
            fault => 'soap:Server', $error
    );

    return $output;
}

1;

=head1 NAME

Gantry::Plugins::SOAP::RPC - RPC style SOAP support

=head1 SYNOPSIS

In your GEN module:

    use Your::App::BaseModule qw( -PluginNamespace=YourApp SOAP::RPC );
    # this will export these into your package:
    #    soap_in
    #    soap_out
    #    do_main
    #    do_wsdl
    #    return_error

    sub get_soap_ops {
        my $self = shift;

        return {
            soap_name      => 'Kids',
            location       => $self->location,
            namespace_base => 'localhost',
            operations     => [
                {
                    name => 'get_count',
                    expects => [
                        { name => 'table_name', type => 'xsd:string' },
                    ],
                    returns => [
                        { name => 'count', type => 'xsd:int' },
                    ],
                },
            ],
        };

    }

Add as many operations as you need.

In your stub:

    use Your::GEN::Module;

    sub get_count {
        my $self = shift;
        my $data = shift;

        return { ... };
    }

Your data will have whatever was in your client's soap request.  You
are responsible for diagnosing all errors and for returning the correct
structure (it should match the returns list).  But feel free to just
die when you spot an error, this module traps those and uses its
C<return_error> method which sends valid SOAP fault messages.

=head1 DESCRIPTION

This plugin is for rpc style SOAP requests only.  If you need document
style requests, you should use L<Gantry::Plugins::SOAP::Doc>.

Bigtop can help a lot with the use of this plugin.  Below is what you need
to do manually, should you choose that route.  But first, I'll explain what
is happening from overhead.

For each SOAP handler in your app, there should be one controller
(or a stub/GEN controller pair) placed on a location in your httpd conf.
If you do the normal thing, the GEN module (or controller if you don't have
a GEN) uses this module and accepts all the exports (the list is mainly
for documentation, since all of them are exported by default).

Two of the exports are Gantry handlers: C<do_main> and C<do_wsdl>.  This means
that the caller will look for the service itself at the location from
httpd.conf, while they will add /wsdl to get the WSDL file.  For example,
suppose you have this in your httpd.conf:

    <Location /appname/SOAP>
        SetHandler  perl-script
        PerlHandler YourApp::YourSoapStub
    </Location>

Then users will hit C</appname/SOAP> to get the service and
C</appname/SOAP/wsdl> to get the WSDL file.

This module registers a C<pre_init> callback which steals all of the
body of the POST from the client.  Then it lets Gantry do its normal
work.  So your stub methods will be called through a site object.

All SOAP requests are handled by C<do_main>, which this module exports.
It uses the internal C<soap_in> method to parse the input.  You must
import C<soap_in>, so it will be in the site object.  It fishes the
client's desired action out of the incoming SOAP request and calls
the method of the same name in the stub module.  That method receives
the SOAP request as parsed by XML::Simple's C<XMLin> function.
It must return the structure which will be returned to the client.

The action method's structure is then fed to C<soap_out> (which you
must also import) and the result is returned as a plain text/xml
SOAP message to the client.  C<SOAP::Lite>'s C<SOAP::Data> and
C<SOAP::Serializer> are used to the hard work of making output.

Here are the details of what your need to implement.

You need a C<namespace> method which returns the same name as the
C<-PluginNamespace>.

You also need a C<get_soap_ops> method which returns a hash describing your
WSDL file.  See the SYNOPSIS for an example.  Here's what the keys do:

=over 4

=item soap_name

This is used whenever SOAP requires a name.  Prefixes and suffices are
appended to it, as in NAME_Binding.

=item location

Normally, you should make this C<<$self->location>>, so that all requests
come to the same SOAP controller which produced the WSDL file.

=item namespace_base

This should be everything after C<http://> and before C<<$self->app_rootp>>
in the URL of the SOAP service.  Usually that is just the domain.

=item operations

An array reference of hashes describing the services you offer.  Each
element is a hash with these keys:

=over 4

=item name

The name of the action method in your stub controller, which will handle
the request.

=item expects

An array reference of parameters the method expects.  These have two
keys: name and type.  They type can be any valid xsd: type or any other
type in your WSDL file.  If you need to define types, see WSDL TYPES below.

=item returns

An array exactly like expects, except that it represents your promise
to the client of what will be in the SOAP response.

=back

=item get_callbacks

Called by Gantry's import method to register the callbacks for this module.

=back

=head1 WSDL TYPES

Gantry ships with wsdl.tt which it uses by default to construct the WSDL
file from the result of C<get_soap_ops>.  If you need to define types,
simply copy that template into your own root path and add the types
you need.  If you want to supply your own data to the template, just
implement your own C<get_soap_ops> and return whatever your template
expects.

=head1 METHODS

All of these are exported by default.  You may supply your own, or
accept the imports.  Failure to do one of those two is fatal.  Doing
both will earn you a subroutine redefinition warning.

=over 4

=item steal_post_body

Steals the body of the POST request before Gantry's engine can get to it.
This method must be registered to work.  Do that by using the plugin
as you use your base module:

    use Your::App qw(
        -PluginNamespace=module_name
        SOAP::RPC
    );

Note that you don't have to do this in the same place as you load the
engine.  In fact, that probably isn't a great idea, since it could lead
you down the primrose path to all of your modules using the plugin's
C<steal_post_body>, leaving you without form data.

Then, you must also implement a method called C<namespace> which returns
the same string as the C<-PluginNamespace>.

This method delegates its work to C<consume_post_body>, which is exported
by each engine.

=item do_main

The SOAP service.  Fishes the POST body with C<get_post_body> parses it
using C<soap_in>, dispatches to your action method, makes the SOAP response
with C<soap_out>, and returns it.

=item do_wsdl

Uses wsdl.tt to return a WSDL file for your service to the client.
It uses C<get_soap_ops> to know what to put in the WSDL file.
Its template is wsdl.tt.  You must call yours that, but feel free
to copy the standard one to an earlier element of the root template
path and edit it.

=item soap_in

For internal use.  Uses XML::Simple to parse the incoming SOAP request.

=item soap_out

For internal use.  Forms a valid (though simple) SOAP response.  Note
that this module may not be able to handle your complex types.
It uses C<SOAP::Lite>'s C<SOAP::Data> and C<SOAP::Serializer>
modules to generate the XML response.

=item return_error

Returns a valid SOAP fault response.  You must either accept this method
in your imports or write one yourself.  The standard error is not SOAP
aware.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2007, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
