package Gantry::Plugins::SOAP::Doc;

use strict;

use base 'Exporter';

use XML::Simple;
use XML::LibXML;
use POSIX qw( strftime );

our @EXPORT = qw(
    soap_out
    do_wsdl
    return_error
    soap_namespace
    soap_namespace_set
    soap_current_time
);

my %registered_callbacks;

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    warn 'Use -PluginNamespace=something when you use '
        .   'Gantry::Plugins::SOAP::Doc' if ( $namespace eq 'Gantry' );

    return (
        { phase => 'pre_init', callback => \&steal_post_body },
        { phase => 'post_init', callback => \&soap_serialize_xml }
    );
}

#-----------------------------------------------------------
# $class->new( \%attrs )
#-----------------------------------------------------------
sub new {
    my $class = shift;
    my $attrs = shift;

    my $self  = {
        __SOAP_NAMESPACE__ => $attrs->{ target_namespace } || '',
        %{ $attrs }
    };

    return bless $self, $class;
}

#-----------------------------------------------------------
# $self->soap_serialize_xml()
#-----------------------------------------------------------
sub soap_serialize_xml {
    my( $self ) = @_;

    my %params;

    if ( $self->get_post_body() ) {

        my $xmlobj = XML::LibXML->new();    
        my $dom    = $xmlobj->parse_string( $self->get_post_body() ) 
            or die "parsing XML $!";

        my @bodyNodes = $dom->getElementsByLocalName( 'Body' );

        _serialize( \%params, $bodyNodes[0] );
    }


    if ( $ENV{QUERY_STRING} ) {
        foreach my $q_param ( split( '&', $ENV{QUERY_STRING} ) ) {
            my( $k, $v ) = split( '=', $q_param );
        
            $params{$k} = $v if defined $v; 
        }
    }
    
    $self->params( \%params ); 
}

#-----------------------------------------------------------
# _serialize( \%params, node )
#-----------------------------------------------------------
sub _serialize {
    my( $params, $node ) = @_;
    
    my @nodes = $node->childNodes();
    
    foreach my $cnode ( @nodes ) {    
        if ( $cnode->hasChildNodes() ) {
            _serialize( $params, $cnode );
        }
        elsif ( $cnode->textContent =~ /\S/ ) {
            $params->{$cnode->parentNode->localname} = $cnode->textContent;
        }             
    }

}

#-----------------------------------------------------------
# $self->steal_post_body( $r_or_cgi )
#-----------------------------------------------------------
sub steal_post_body {
    my $self     = shift;
    my $r_or_cgi = shift;

    $self->consume_post_body( $r_or_cgi );
}

#-----------------------------------------------------------
# $self->soap_namespace(  )
#-----------------------------------------------------------
sub soap_namespace {
    my $self = shift;

    return $self->{__SOAP_NAMESPACE__};
}

#-----------------------------------------------------------
# $self->soap_namespace_set(  )
#-----------------------------------------------------------
sub soap_namespace_set {
    my $self      = shift;
    my $new_value = shift;

    $self->{__SOAP_NAMESPACE__} = $new_value;
}

#-----------------------------------------------------------
# $self->soap_out( $data )
#-----------------------------------------------------------
sub soap_out {
    my $self     = shift;
    my $data     = shift;
    my $ns_style = shift;
    my $pretty   = shift;

    my $ns     = $self->soap_namespace || 'http://example.com/ns';
    my $args   = build_args( {
        data     => $data,
        pretty   => $pretty,
        ns_style => $ns_style,
        ns       => $ns
    } );

    eval {
        $self->template_wrapper( 0 );
        $self->template_disable( 1 );
        $self->content_type( 'text/xml' );
    };
    # errors come from calling Gantry methods on instances of this class
    # used by client scripts

    my $prefix_ns = '';
    if ( $ns_style eq 'prefix' ) {
        $prefix_ns = qq!xmlns:tns="$ns"!;
    }

    return <<"EO_XML";
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               $prefix_ns
               xmlns:xs="http://www.w3.org/2001/XMLSchema" >
<soap:Body>
$args
</soap:Body>
</soap:Envelope>
EO_XML
}

#-----------------------------------------------------------------
# $self->soap_current_time(  )
# Thanks to Joe McMahon and his SOAP::DateTime module for
# the format below.
#-----------------------------------------------------------------
sub soap_current_time {
    my @time_pieces = gmtime;
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @time_pieces );
} # END _get_current_time

#-----------------------------------------------------------
# build_args( $request_args, $pretty_flag, $depth )
# This is not a method, but it is RECURSIVE.  Initial
# callers need supply only the first argument.
#-----------------------------------------------------------
sub build_args { # recursive
    my $all_params   = shift;
    my $request_args = $all_params->{ data   };
    my $pretty       = $all_params->{ pretty };
    my $depth        = $all_params->{ depth  } || 0;
    my $retval       = '';

    my $ns_prefix    = '';
    my $internal_ns  = '';

    if ( $all_params->{ ns_style } eq 'prefix' ) {
        $ns_prefix = 'tns:';
    }
    elsif ( $all_params->{ ns } ) {
        $internal_ns  = qq!\n    xmlns="$all_params->{ ns }"!;
    }

    return $request_args unless ref( $request_args ) eq 'ARRAY';

    # pretty printed for debugging:
    my $indent       = ( $pretty ) ? ' ' x ( 2 * $depth ) : '';
    my $nl           = ( $pretty ) ? "\n"                 : '';
    
    foreach my $arg ( @{ $request_args } ) {
        my ( $key, $values ) = %{ $arg };
        
        if ( defined $values ) {
            my $start_tag    = "$indent<$ns_prefix$key$internal_ns>";
            my $child_output = build_args( {
                data     => $values,
                pretty   => $pretty,
                depth    => $depth + 1,
                ns_style => $all_params->{ ns_style },
            } );
            my $end_tag      = "</$ns_prefix$key>$nl";
            
            # now pretty print it pretty please
            if ( ref( $values ) eq 'ARRAY' ) {
                $start_tag = "$start_tag$nl";
                $end_tag   = "$indent$end_tag";
            }

            $retval       .= "$start_tag$child_output$end_tag";
        }
        else {  # values is undef or the empty string
            $retval .= "$indent<$ns_prefix$key/>$nl";
        }
    }

    return $retval;
} # end of build_args

#-----------------------------------------------------------
# $self->return_error( $error_text )
#-----------------------------------------------------------
sub return_error {
    my ( $self, $error ) = @_;

    return <<"EO_XML_FAULT";
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema" >
  <soap:Body>
    <soap:Fault>
    <faultcode>soap:Server</faultcode>
    <faultstring>$error</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
EO_XML_FAULT
}

#-----------------------------------------------------------------
# $self->do_wsdl
#-----------------------------------------------------------------
sub do_wsdl {
    my $self = shift;

    $self->stash->view->template( 'wsdldoc.tt' );

    $self->stash->view->data( $self->get_soap_ops );

    delete $self->{__TEMPLATE_WRAPPER__};
    my $wsdl = $self->do_process();

    $self->template_disable( 1 );
    $self->content_type( 'text/xml' );

    return $wsdl;
} # END do_wsdl

#-----------------------------------------------------------------
# $self->send_xml
#-----------------------------------------------------------------
sub send_xml {
    my $self        = shift;
    my $request_xml = shift;

    require LWP::UserAgent;

    my $user_agent = LWP::UserAgent->new();
    $user_agent->agent( 'Sunflower/1.0' );

    my $request = HTTP::Request->new(
        POST => $self->{ post_to_url }
    );

    $request->content_type( 'text/xml; charset=utf-8' );
    $request->content_length( length $request_xml );
    $request->header( 'Host' => $self->{ host } ) if $self->{ host };
    $request->header( 'SoapAction' => $self->{ action_url } );
    $request->content( $request_xml );

    return $user_agent->request( $request );
}

1;

=head1 NAME

Gantry::Plugins::SOAP::Doc - document style SOAP support

=head1 SYNOPSIS

In a controller:

    use Your::App::BaseModule qw(
         -PluginNamespace=YourApp
         SOAP::Doc
    );
    # This exports these into the site object:
    #    soap_out
    #    do_wsdl
    #    return_error

    do_a_soap_action {
        my $self        = shift;
        my $data        = $self->get_post_body();
        my $parsed_data = XMLin( $data );

        # Use data to process the request, until you have a
        # structure like:

        my $ret_struct = [
            {
                yourResponseType => [
                    { var  => value  },
                    { var2 => value2 },
                    { var3 => undef  }, # for required empty tags
                    { nesting_var => [
                        { subvar => value },
                    ] }
                ]
            }
        ] );

        return $self->soap_out( $ret_struct, 'prefix', 'pretty' );
    }

=head1 DESCRIPTION

This module supports document style SOAP.  If you need rpc style,
see L<Gantry::Plugins::SOAP::RPC>.

This module must be used as a plugin, so it can register a pre_init callback
to take the POSTed body from the HTTP request before the engine can
mangle it, in a vain attempt to make form parameters from it.

The document style SOAP request must find its way to your do_ method
via its soap_action URL and Gantry's normal dispatching mechanism.  Once
the do_ method is called, your SOAP request is available via the
C<get_post_body> accessor exported by each engine.  That request is
exactly as received.  You probably want to use XML::Simple's XMLin
function to extract your data.  I would do that for you here, but
you might need to set attributes of the parsing like ForceArray.

When you have finished processing the request, you have two choices.
If it did not go well, call C<return_error> to deliver a SOAP
fault to client.  Using die or croak is a bad idea as that will return
a regular Gantry error message which is obviously not SOAP compliant.

If you succeeded in handling the request, return an array of hashes.
Each hash is keyed by XML tag (not including namespace prefix).
The value can be a scalar or an array of hashes like the top level one.
If the value is C<undef>, an empty tag will be generated.

Generally, you need to take all of the exports from this module, unless
you want to replace them with your own versions.

If you need to control the namespace of the returned parameters, call
C<soap_namespace_set> with the URL of the namespace before returning.
If you don't do that the namespace will default to
C<http://example.com/ns>.

=head1 METHODS

=over 4

=item new

For use by non-web scripts.  Call this with a hash of attributes.  Currently
only the C<target_namespace> key is used.  It sets the namespace.
Once you get your object, you can call C<soap_out> on it as you would
in a Gantry conroller.

=item get_callbacks

Only for use by Gantry.pm.

This is used to register C<steal_post_body> as a pre init callback with Gantry.

=item steal_post_body

Not for external use.

Just a carefully timed call to C<consume_post_body> exported by each engine.
This is registered as a pre_init callback, so it gets the body before
normal form parameter parsing would.

You may retrieve with the post body with C<get_post_body> (also exported
by each engine).  No processing of the request is done.  You will receive
whatever the SOAP client generated.  That should be XML, but even that
depends on the client.

=item soap_current_time

Returns the UTC in SOAP format.

=item soap_serialize_xml

This method is registered as a callback. Durning the post_init phase it will
create a hash from the $self->get_post_body() and store the result in 
$self->params();
 
=item soap_namespace

Called internally to retrieve the namespace for the XML tags in your
SOAP response.  Call C<soap_namespace_set> if you need to set a
particular namespace (some clients will care).  Otherwise, the default
namespace C<http://example.com/ns> will be used.

=item soap_namespace_set

Use this to set the namespace for your the tags in your XML response.
The default namespace is C<http://example.com/ns>.

=item soap_out

Parameters:

=over 4

=item structure

actual data to send to the client.  See L<SYNOPSIS> and L<DESCRIPTION>.

=item namespace_style

prefix or internal.  Use prefix to define the namespace in the soap:Envelope
declaration and use it as a prefix on all the return parameter tags.
Use internal if you want the prefix to be defined in the outer tag
of the response parameters.

To set the value of the namespace, call C<soap_namespace_set> before
calling this method.

=item pretty

true if you want pretty printing, false if not

By default returned XML will be whitespace compressed.  If you want
it to be pretty printed for debugging, pass any true value to this method
as the second parameter, in a scenario like this:

    my $check_first = $self->soap_out(
            $structure, 'prefix', 'pretty_please'
    );
    warn $check_first;
    return $check_first;

=back

Call this with the data to return to the client.  If that client cares
about the namespace of the tags in the response, call C<soap_namespace_set>
first.  See the L<SYNOPSIS> for an example of the structure you must
pass to this method.  See the L<DESCRIPTION> for an explanation of
what you can put in the structure.

You should return the value returned from this method directly.  It turns
off all templating and sets the content type to text/xml.

=item build_args

Mostly for internal use.

C<soap_out> uses this to turn your structure of return values into an XML
snippet.  If you need to re-implement C<soap_out>, you could call this
directly.  The initial call should pass the same structure C<soap_out>
expects and (optionally) a pretty print flag.  The returned value is the
snippet of return params only.  You would then need to build the SOAP
envelope, etc.

=item return_error

This method returns a fault XML packet for you. Use it instead of die or croak.

=item do_wsdl

This method uses the C<wsdldoc.tt> in your template path to return
a WSDL file to your client.  The view.data passed to that template
comes directly from a call to C<get_soap_ops>, which you must implement
(even it it returns nothing).

=item send_xml

For clients.  Sends the xml to the SOAP server.  You must have called
new with C<action_url> and C<post_to_url> for this method to work.  In
particular, servers which use this as a plugin cannot normally call
this method.  First, they must call new to make an object of this
class.

Parameters: an object of this class, the xml to send (get it from calling
C<soap_out>).

Returns: response from remote server (actually whatever request on the
LWP user agent retruns, try calling content on that object)

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>
Tim Keefer, E<lt>tim@timkeefer.com<gt>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2007, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
