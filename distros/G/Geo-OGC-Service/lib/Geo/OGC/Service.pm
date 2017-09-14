=pod

=head1 NAME

Geo::OGC::Service - Perl extension for geospatial web services

=head1 SYNOPSIS

In a service.psgi file write something like this

  use strict;
  use warnings;
  use Plack::Builder;
  use Geo::OGC::Service;
  use Geo::OGC::Service::XXX;
  my $server = Geo::OGC::Service->new({
      config => '/var/www/etc/test.conf',
      services => {
          XXX => 'Geo::OGC::Service::XXX',
      }
  });
  builder {
      mount "/XXX" => $server->to_app;
      mount "/" => $default_app;
  };

The bones of a service class are

  package Geo::OGC::Service::XXX;
  sub process_request {
    my ($self, $responder) = @_;
    my $writer = $responder->([200, [ 'Content-Type' => 'text/plain',
                                      'Content-Encoding' => 'UTF-8' ]]);
    $writer->write("I'm ok!");
    $writer->close;
  }

Geo::OGC::Service::WFS exists in the CPAN and Geo::OGC::Service::WMTS
will be there real soon now.

=head1 DESCRIPTION

Geo::OGC::Service is a subclass of Plack::Component and a middleware
between a web client and an actual content providing service object.
A Geo::OGC::Service object has a to_app method for booting a web
service.

A Geo::OGC::Service object creates a specialized service object as a
result of a web service request. The specialized service object is a
hash reference blessed into an appropriate class (the class is deduced
from GET parameter, POSTed service name, or from the script name in
the case of RESTful services). The new object contains keys env,
request, plugin, config, service, and optionally posted, filter, and
parameters.

=over

=item env

The PSGI $env.

=item request

A Plack::Request object constructed from the $env;

=item plugin 

The plugin object given as an argument to Geo::OGC::Service in its
constructor as a top level attribute or as a service specific
attribute.

=item config 

The constructed configuration for the web service.

=item service 

The name of the requested service.

=item parameters 

A hash made from Plack::Request->parameters (thus removing its multi
value nature). The keys are all converted to lower case and the values
are decoded to Perl's internal format assuming they are in the
encoding defined $request->content_encoding (or UTF-8).

=item posted 

A XML::LibXML documentElement of the POSTed XML. The XML is decoded
into Perl's internal format.

=item filter 

A XML::LibXML documentElement contructed from a filter GET
parameter. The XML is decoded into Perl's internal format.

=back

=head2 SERVICE CONFIGURATION

Setting up a PSGI service consists typically of three things: 

1) write a service.psgi file (see above) and put it somewhere like

   /var/www/service/service.psgi 

2) Set up starman service and add to its init-file line something like

   exec starman --daemonize --error-log /var/log/starman/log --l localhost:5000 /var/www/service/service.psgi

3) Add a proxy service to your httpd configuration. For Apache it
would be something like this:

   <Location /Service>
     ProxyPass http://localhost:5000
     ProxyPassReverse http://localhost:5000
   </Location>

Setting up a geospatial web service through this module requires a
configuration file, for example

/var/www/etc/service.conf

(make sure this file is not served by your httpd)

The configuration must be in JSON format. I.e., something like

  {
    Common: {
        "CORS": {
                "Allow-Origin" : "*",
                "Allow-Headers" : "Content-Type, X-Requested-With"
        },
        "Content-Type": "text/xml; charset=utf-8",
        "TARGET_NAMESPACE": "http://ogr.maptools.org/"
    },
    WFS: {
        "resource": "http://$HTTP_HOST/WFS",
        "version": "1.1.0",
        "TARGET_NAMESPACE": "http://ogr.maptools.org/",
        "PREFIX": "ogr",
        "Transaction": "Insert,Update,Delete",
        "FeatureTypeList": [
            {
            }
        ]
    },
    "WMS": {
        "resource": "http://$HTTP_HOST/WMS"
    },
    "TMS": {
        "resource": "http://$HTTP_HOST/TMS"
    },
    "WMTS": {
        "resource": "http://$HTTP_HOST/WMTS"
    },
    "TileSets": [
    ],
    "BoundingBox3857": {
        "SRS": "EPSG:3857",
        "minx": 2399767,
        "miny": 8645741,
        "maxx": 2473612,
        "maxy": 8688005
    }
  }

The keys and structure of this file depend on the type of the
service(s) you are setting up. "CORS" is the only one that is
recognized by this module. "CORS" is either a string denoting the
allowed origin or a hash of "Allow-Origin", "Allow-Methods",
"Allow-Headers", and "Max-Age".

$HTTP_HOST and $SCRIPT_NAME are replaced in runtime to the HTTP_HOST
and SCRIPT_NAME values respectively in the environment given by Plack.

=head2 EXPORT

None by default.

=head2 METHODS

=cut

package Geo::OGC::Service;

use 5.010000; # say // and //=
use Carp;
use Modern::Perl;
use Encode qw(decode encode);
use Plack::Request;
use Plack::Builder;
use JSON;
use XML::LibXML;
use Clone 'clone';
use XML::LibXML::PrettyPrint;

use parent qw/Plack::Component/;

binmode STDERR, ":utf8"; 

our $VERSION = '0.14';

=pod

=head3 new

This creates a new Geo::OGC::Service app. You need to call it in the
psgi file as a class method with a named parameter hash reference. The
parameters are

  config, services

config is required and it is a path to a file or a reference to an
anonymous hash containing the configuration for the services. The top
level keys are service names. If it is a file, it is expected to be
JSON. A configuration in a file may use top level Common hash and
references. A reference is a key,value pair, where the value begins
with 'ref:/' followed by a top level key name. The Common block is
cloned and references are solved and cloned into each service
configuration.

services is a reference to a hash of service names associated with
names of classes, which will process service requests. The key of the
hash is the requested service.

=cut

sub new {
    my ($class, $parameters) = @_;
    my $self = Plack::Component->new($parameters);
    if (not ref $self->{config}) {
        open my $fh, '<', $self->{config} or croak "Can't open file '$self->{config}': $!\n";
        my @json = <$fh>;
        close $fh;
        $self->{config} = decode_json "@json";
        expand_config($self->{config});
        $self->{config}{debug} //= 0;
    }
    croak "A configuration file is needed." unless $self->{config};
    croak "No services are defined." unless $self->{services};
    return bless $self, $class;
}

sub expand_config {
    my $config = shift;
    my $had_ref;
    do {
        $had_ref = 0;
        for my $j (keys %$config) {
            $had_ref += config_ref($config->{$j}, $config);
        }
    } while ($had_ref);
    for my $j (keys %$config) {
        next if $j eq 'Common';
        next if $j =~ /^BoundingBox/;
        next unless ref $config->{$j} eq 'HASH';
        for my $c (keys %{$config->{Common}}) {
            $config->{$j}{$c} //= clone($config->{Common}{$c});
        }
    }
}

sub config_ref {
    my ($config, $refs) = @_;
    my $had_ref = 0;
    if (ref $config eq 'ARRAY') {
        for my $j (@$config) {
            $had_ref += config_ref($j, $refs);
        }
    }
    elsif (ref $config eq 'HASH') {
        for my $j (keys %$config) {
            my $r = $config->{$j};
            if (ref $r) {
                $had_ref += config_ref($r, $refs);
            } else {
                if ($r =~ /^ref:/) {
                    my $target = config_target($refs, $r);
                    croak "config reference not found: '$r'." unless $target;
                    $config->{$j} = clone($target);
                    $had_ref = 1;
                }
            }
        }
    }
    return $had_ref;
}

sub config_target {
    my ($config, $ref) = @_;
    my @path = split /\//, $ref;
    shift @path;
    if (ref $config eq 'HASH') {
        return $config->{$path[0]};
    }
    return undef;
}

=pod

=head3 call

This method is called internally by the method to_app of
Plack::Component. The method fails unless this module
is running in a psgi.streaming environment. Otherwise,
it returns a subroutine, which calls the respond method.

=cut

sub call {
    my ($self, $env) = @_;
    if (! $env->{'psgi.streaming'}) { # after Lyra-Core/lib/Lyra/Trait/Async/PsgiApp.pm
        return [ 500, ["Content-Type" => "text/plain"], ["Internal Server Error (Server Implementation Mismatch)"] ];
    }
    return sub {
        my $responder = shift;
        $self->respond($responder, $env);
    }
}

=pod

=head3 respond

This method is called for each request from the Internet. The call is
responded during the execution of the subroutine.

In the default case this method constructs a new service object using
the method 'service' and calls its process_request method with PSGI
style $responder object as a parameter.

This subroutine may fail while interpreting the request, or while
processing the request.

=cut

sub respond {
    my ($self, $responder, $env) = @_;
    # TODO: logging
    if ($env->{REQUEST_METHOD} eq 'OPTIONS') {
        $responder->([200, ['Content-Length' => 0,
                            'Content-Type' => 'text/plain', 
                            Geo::OGC::Service::Common::CORS($self)]]);
    } else {
        my $service;
        eval {
            $service = $self->service($responder, $env);
        };
        if ($@) {
            print STDERR "$@";
            error($responder, { exceptionCode => 'ResourceNotFound',
                                ExceptionText => "Internal error while interpreting the request." } );
        } elsif ($service) {
            eval {
                $service->process_request($responder);
            };
            if ($@) {
                print STDERR "$@";
                error($responder, { exceptionCode => 'ResourceNotFound',
                                    ExceptionText => "Internal error while processing the request." } );
            }
        }
    }
}

=pod

=head3 service

This method does a preliminary interpretation of the request and
converts it into a service object, which is returned. 

The returned service object contains

  config => the configuration for this type of service
  env => the PSGI environment

and may contain

  plugin => plugin object

  posted => XML::LibXML DOM document element of the posted data
  filter => XML::LibXML DOM document element of the filter
  parameters => hash of rquest parameters obtained from Plack::Request

config is the service specific part of the config given to this
Geo::OGC::Service object in its constructor, possibly worked to clone
the Common block and references. The service should treat it strictly
read-only as it is shared between workers.

plugin is the plugin object that was given to this Geo::OGC::Service
object in its constructor.

Note: all keys in request parameters are converted to lower case in
parameters.

This subroutine may fail due to a request for an unknown service. The
error is reported as an XML message using OGC conventions.

=cut

sub service {
    my ($self, $responder, $env) = @_;

    my $request = Plack::Request->new($env);
    my $parameters = $request->parameters;

    my $service = { 
        env => $env, 
        request => $request,
        # will get below:
        # plugin
        # posted
        # filter
        # parameters
        # service
        # config
    };

    my $encoding = $request->content_encoding // 'utf8';
    
    my %names;
    for my $key (sort keys %$parameters) {
        $names{lc($key)} = $key;
        $parameters->{$key} = decode $encoding => $parameters->{$key};
    }

    my $post = $names{postdata} // $names{'xforms:model'};
    $post = $post ? $parameters->{$post} : decode($encoding, $request->content);
  
    if ($post) {
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $post);
        };
        if ($@) {
            error($responder, { exceptionCode => 'ResourceNotFound',
                                ExceptionText => "Error in posted XML:\n$@" } );
            return;
        }
        $service->{posted} = $dom->documentElement();
    } else {
        for my $key (keys %names) {
            if ($key eq 'filter' and $parameters->{$names{filter}} =~ /^</) {
                my $filter = $parameters->{$names{filter}};
                my $s = '<ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">';
                $filter =~ s/<ogc:Filter>/$s/;
                my $parser = XML::LibXML->new(no_blanks => 1);
                my $dom;
                eval {
                    $dom = $parser->load_xml(string => $filter);
                };
                if ($@) {
                    error($responder, { exceptionCode => 'ResourceNotFound',
                                        ExceptionText => "Error in XML filter:\n$@" } );
                    return;
                }
                $service->{filter} = $dom->documentElement();
            } else {
                $service->{parameters}{$key} = $parameters->{$names{$key}};
            }
        }
    }

    # service may also be an attribute in the top element of posted XML
    my $service_from_posted = sub {
        my $node = shift;
        return undef unless $node;
        return $node->getAttribute('service');
    };

    # RESTful way to define the service
    my $service_from_script_name = sub {
        my $env = shift;
        my ($script_name) = $env->{SCRIPT_NAME} =~ /(\w+)$/;
        return $script_name;
    };

    my $requested_service = $parameters->{service} // 
        $service_from_posted->($service->{posted}) // 
        $service_from_script_name->($env) // ''; 

    if (exists $self->{services}{$requested_service}) {
        $service->{service} = $requested_service;
        my $class = $self->{services}{$requested_service};
        if (ref $class) {
            $service->{plugin} = $class->{plugin};
            $class = $class->{service};
        }
        $service->{plugin} //= $self->{plugin};
        my $config = $self->{config};
        $service->{config} = get_config($config, $requested_service);
        if ($service->{config}{resource}) {
            my $host = $env->{HTTP_HOST};
            $service->{config}{resource} =~ s/\$HTTP_HOST/$host/ if $host;
            my $script = $env->{SCRIPT_NAME};
            $service->{config}{resource} =~ s/\$SCRIPT_NAME/$script/ if $script;
        }
        return bless $service, $class;
    }

    error($responder, { exceptionCode => 'InvalidParameterValue',
                        locator => 'service',
                        ExceptionText => "'$requested_service' is not a known service to this server" } );
    return undef;
}

# the value of the key, whose name is the service
# may be the config for the service 
# or it may be the name of the key
# whose value is the config for the service
sub get_config {
    my ($config, $service) = @_;
    if (exists $config->{$service}) {
        if (ref $config->{$service}) {
            return $config->{$service};
        }
        if (ref $config->{$config->{$service}}) {
            return $config->{$config->{$service}};
        }
        return undef;
    }
    return $config;
}

=pod

=head3 error($responder, $msg)

Stream an error report as an XML message of type

  <?xml version="1.0" encoding="UTF-8"?>
  <ExceptionReport>
      <Exception exceptionCode="$msg->{exceptionCode}" locator="$msg->{locator}">
          <ExceptionText>$msg->{ExceptionText}<ExceptionText>
      <Exception>
  </ExceptionReport>

=cut

sub error {
    my ($responder, $msg, $headers) = @_;
    my $writer = Geo::OGC::Service::XMLWriter::Caching->new($headers);
    $writer->open_element('ExceptionReport', { version => "1.0" });
    my $attributes = { exceptionCode => $msg->{exceptionCode} };
    my $content;
    $content = [ ExceptionText => $msg->{ExceptionText} ] if exists $msg->{ExceptionText};
    if (exists $msg->{locator}) {
        $attributes->{locator} = $msg->{locator};
    }
    $writer->element('Exception', $attributes, $content);
    $writer->close_element;
    $writer->stream($responder);
}

=pod

=head1 Geo::OGC::Service::Common

A base type for all OGC services.

=head2 SYNOPSIS

  $service->DescribeService($writer);
  $service->Operation($writer, $operation, $protocols, $parameters);

=head2 DESCRIPTION

The class contains methods for common tasks for all services.

=head2 METHODS

=cut

package Geo::OGC::Service::Common;
use Modern::Perl;

=pod

=head3 CORS

Return the CORS headers as a list according to the configuration. CORS
may be in the configuration as a scalar or as a hash. A scalar value
is taken as a value for Access-Control-Allow-Origin. A hash may have
the following keys. (Note the missing prefix Access-Control-.)

      key                      default value
  -----------------  ----------------------------------
  Allow-Origin              
  Allow-Credentials
  Expose-Headers
  Max-Age                        60*60*24
  Allow-Methods                  GET,POST
  Allow-Headers    origin,x-requested-with,content-type

=cut

sub CORS {
    my $self = shift;
    # default CORS response headers:
    my %default = ( 
        'Allow-Origin' => '',
        'Allow-Credentials' => '',
        'Expose-Headers' => '',
        'Max-Age' => 60*60*24,
        'Allow-Methods' => 'GET,POST',
        'Allow-Headers' => 'origin,x-requested-with,content-type'
        );
    # where CORS is in the configuration
    my $config = $self->{config}{Common}{CORS} // $self->{config}{CORS};
    my @cors;
    if (ref $config eq 'HASH') {
        for my $key (keys %default) {
            my $val = $config->{$key} // $default{$key};
            push @cors, ('Access-Control-'.$key => $val);
        }
    } else {
        $default{'Allow-Origin'} = $config;
        for my $key (keys %default) {
            my $val = $default{$key};
            push @cors, ('Access-Control-'.$key => $val);
        }
    }
    return @cors;
}

=pod

=head3 DescribeService($writer)

Create ows:ServiceIdentification and ows:ServiceProvider elements.

=cut

sub DescribeService {
    my ($self, $writer) = @_;
    $writer->element('ows:ServiceIdentification', 
                     [['ows:Title' => $self->{config}{Title} // "Yet another $self->{service} server"],
                      ['ows:Abstract' => $self->{config}{Abstract} // ''],
                      ['ows:ServiceType', {codeSpace=>"OGC"}, "OGC $self->{service}"],
                      ['ows:ServiceTypeVersion', $self->{config}{ServiceTypeVersion} // '1.0.0'],
                      ['ows:Fees' => $self->{config}{Fees} // 'NONE'],
                      ['ows:AccessConstraints' => $self->{config}{AccessConstraints} // 'NONE']]);
    $writer->element('ows:ServiceProvider',
                     [['ows:ProviderName' => $self->{config}{ProviderName} // 'Nobody in particular'],
                      ['ows:ProviderSite', { 'xlink:type'=>"simple", 
                                             'xlink:href' => $self->{config}{ProviderSite} // '' }],
                      ['ows:ServiceContact' => $self->{config}{ServiceContact}]]);
}

=pod

=head3 Operation($writer, $operation, $protocols, $parameters)

Create ows:Operation element and its ows:DCP and ows:Parameter sub
elements.

=cut

sub Operation {
    my ($self, $writer, $operation, $protocols, $parameters) = @_;
    my @p;
    for my $p (@$parameters) {
        for my $n (keys %$p) {
            push @p, [$self->Parameter($n, $p->{$n})];
        }
    }
    my $constraint;
    $constraint = [ 'ows:Constraint' => {name => 'GetEncoding'}, $protocols->{Get} ] if ref $protocols->{Get};
    my @http;
    push @http, [ 'ows:Get' => { 'xlink:type'=>'simple', 'xlink:href'=>$self->{config}{resource} }, $constraint ]
        if $protocols->{Get};
    push @http, [ 'ows:Post' => { 'xlink:type'=>'simple', 'xlink:href'=>$self->{config}{resource} } ]
        if $protocols->{Post};
    $writer->element('ows:Operation' => { name => $operation }, [['ows:DCP' => ['ows:HTTP' => \@http ]], @p]);
}

sub Parameter {
    my ($self, $name, $values) = @_;
    my $wrap = $values->[0] =~ /allowedvalues/i;
    $values = $values->[1] if $wrap;
    my @values;
    for my $value (@$values) {
        push @values, ['ows:Value' => $value];
    }
    @values = ('ows:AllowedValues' => [@values]) if $wrap;
    return ('ows:Parameter', { name => $name }, \@values);
}

=pod

=head1 Geo::OGC::Service::XMLWriter

A helper class for writing XML.

=head2 SYNOPSIS

  my $writer = Geo::OGC::Service::XMLWriter::Caching->new();
  $writer->open_element(
        'wfs:WFS_Capabilities', 
        { 'xmlns:gml' => "http://www.opengis.net/gml" });
  $writer->element('ows:ServiceProvider',
                     [['ows:ProviderName'],
                      ['ows:ProviderSite', {'xlink:type'=>"simple", 'xlink:href'=>""}],
                      ['ows:ServiceContact']]);
  $writer->close_element;
  $writer->stream($responder);

or 

  my $writer = Geo::OGC::Service::XMLWriter::Streaming->new($responder);
  $writer->prolog;
  $writer->open_element('MyXML');
  while (a long time) {
      $writer->element('MyElement');
  }
  $writer->close_element;
  # $writer is closed when it goes out of scope

=head2 DESCRIPTION

The classes Geo::OGC::Service::XMLWriter (abstract),
Geo::OGC::Service::XMLWriter::Streaming (concrete), and
Geo::OGC::Service::XMLWriter::Caching (concrete) are provided as a
convenience for writing XML to the client.

The element method has the syntax

  $writer->element($tag[, $attributes][, $content])

or

  $writer->element($element)

where $element is a reference to an array [$tag[, $attributes][,
$content]].

$attributes is a reference to a hash

$content is nothing, undef, '/>', plain content (string), an element
(as above), a list of elements, or a reference to a list of
elements. If there is no $content or $content is undef, a self-closing
tag is written. If $content is '/>' a closing tag is written.

Setting $tag to 0 or 1, allows writing plain content.

If $attribute{$key} is undefined the attribute is not written at all.

=cut

package Geo::OGC::Service::XMLWriter;
use Modern::Perl;
use Encode qw(decode encode is_utf8);
use Carp;

sub element {
    my $self = shift;
    my $tag = shift;
    return unless defined $tag;
    if (ref($tag) eq 'ARRAY') {
        for my $element ($tag, @_) {
            $self->element(@$element);
        }
        return;
    }
    my $attributes;
    $attributes = shift if @_ and ref($_[0]) eq 'HASH';
    if (@_ && defined($_[0]) && $_[0] eq '/>') {
        $self->write("</$tag>");
        return;
    }
    if ($tag =~ /^\d/) {
        $self->write($_[0]);
        return;
    }
    $self->write("<$tag");
    if ($attributes) {
        for my $a (keys %$attributes) {
            my $attr = $attributes->{$a};
            if (defined $attr) {
                $attr = decode utf8 => $attr unless is_utf8($attr);
                $self->write(" $a=\"$attr\"");
            }
        }
    }
    if (@_ == 0 || !defined($_[0])) {
        $self->write(" />");
    } else {
        $self->write(">");
        for my $element (@_) {
            next unless defined($element);
            if (ref $element eq 'ARRAY') {
                $self->element(@$element);
            } elsif (ref $element) {
                croak ref($element)." can't be used as an XML element.";
            } elsif ($element eq '>') {
            } else {
                if (is_utf8($element)) {
                    $self->write($element);
                } else {
                    $self->write(decode utf8 => $element);
                }
            }
        }
        $self->write("</$tag>");
    }
}

sub open_element {
    my $self = shift;
    my $element = shift;
    my $attributes;
    for my $x (@_) {
        $attributes = $x, next if ref($x) eq 'HASH';
    }
    $self->write("<$element");
    if ($attributes) {
        for my $a (keys %$attributes) {
            my $attr = $attributes->{$a};
            if (defined $attr) {
                $attr = decode utf8 => $attr unless is_utf8($attr);
                $self->write(" $a=\"$attr\"");
            }
        }
    }
    $self->write(">");
    $self->{open_element} = [] unless $self->{open_element};
    push @{$self->{open_element}}, $element;
}

sub close_element {
    my $self = shift;
    my $element = pop @{$self->{open_element}};
    $self->write("</$element>");
}

=pod

=head1 Geo::OGC::Service::XMLWriter::Streaming

A helper class for writing XML into a stream.

=head2 SYNOPSIS

  my $w = Geo::OGC::Service::XMLWriter::Streaming($responder, $headers, $declaration);

Using $w as XMLWriter sets writer, which is obtained from $responder,
to write XML. The writer is closed when $w is destroyed.

$headers and $declaration are optional. The defaults are
'Content-Type' => 'text/xml; charset=utf-8' and '<?xml version="1.0"
encoding="UTF-8"?>'.

=cut

package Geo::OGC::Service::XMLWriter::Streaming;
use Modern::Perl;

our @ISA = qw(Geo::OGC::Service::XMLWriter Plack::Util::Prototype); # can't use parent since Plack is not yet

sub new {
    my ($class, $responder, $headers, $declaration) = @_;
    my %headers;
    if (ref $headers) {
        %headers = @$headers;
    } else {
        $headers{'Content-Type'} = $headers;
    }
    $headers{'Content-Type'} //= 'text/xml; charset=utf-8';
    my $self = $responder->([200, [%headers]]);
    $self->{declaration} = $declaration //= '<?xml version="1.0" encoding="UTF-8"?>';
    return bless $self, $class;
}

sub prolog {
    my $self = shift;
    $self->write($self->{declaration});
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

=pod

=head1 Geo::OGC::Service::XMLWriter::Caching

A helper class for writing XML into a cache.

=head2 SYNOPSIS

 my $w = Geo::OGC::Service::XMLWriter::Caching($headers, $declaration);
 $w->stream($responder);

Using $w to produce XML caches the XML. The cached XML can be
written by a writer obtained from a $responder.

$headers and $declaration are optional. The defaults are as in
Geo::OGC::Service::XMLWriter::Streaming.

=cut

package Geo::OGC::Service::XMLWriter::Caching;
use Modern::Perl;
use Encode qw(decode encode is_utf8);

our @ISA = qw(Geo::OGC::Service::XMLWriter);

sub new {
    my ($class, $headers, $declaration) = @_;
    my %headers;
    if (ref $headers) {
        %headers = @$headers;
    } else {
        $headers{'Content-Type'} = $headers;
    }
    $headers{'Content-Type'} //= 'text/xml; charset=utf-8';
    my $self = {
        cache => [],
        headers => \%headers,
        declaration => $declaration //= '<?xml version="1.0" encoding="UTF-8"?>'
    };
    $self->{cache} = [];
    return bless $self, $class;
}

sub write {
    my $self = shift;
    my $line = shift;
    push @{$self->{cache}}, $line;
}

sub to_string {
    my $self = shift;
    my $xml = $self->{declaration};
    for my $line (@{$self->{cache}}) {
        $xml .= $line;
    }
    return $xml;
}

sub stream {
    my $self = shift;
    my $responder = shift;
    my $debug = shift;
    my $writer = $responder->([200, [ %{$self->{headers}} ]]);
    $writer->write($self->{declaration});
    my $xml = '';
    for my $line (@{$self->{cache}}) {
        $writer->write(encode utf8 => $line);
        $xml .= $line if $debug;
    }
    $writer->close;
    if ($debug) {
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
        my $dom = $parser->load_xml(string => $xml);
        $pp->pretty_print($dom);
        say STDERR $dom->toString;
    }
}

1;
__END__

=head1 SEE ALSO

Discuss this module on the Geo-perl email list.

L<https://list.hut.fi/mailman/listinfo/geo-perl>

For PSGI/Plack see 

L<http://plackperl.org/>

=head1 REPOSITORY

L<https://github.com/ajolma/Geo-OGC-Service>

=head1 AUTHOR

Ari Jolma, E<lt>ari.jolma at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015- by Ari Jolma

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
