=head1 NAME

Geneos::API - Handy Perl interface to ITRS Geneos XML-RPC Instrumentation API

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use Geneos::API;

    # open API to NetProbe running on host example.com and port 7036
    my $api = Geneos::API->new("http://example.com:7036/xmlrpc");

    # get the sampler "Residents" in the managed entity "Zoo"
    my $sampler = $api->get_sampler("Zoo", "Residents");

    # create view "Monkeys" in the group "Locals"
    my $view = $sampler->create_view("Monkeys", "Locals");

    # prepare some data
    my $monkeys = [
        ["Name",   "Type"             ],
        ["Funky",  "Red-tailed monkey"],
        ["Cheeky", "Tibetan macaque"  ]
    ];

    # populate the view
    $view->update_entire_table($monkeys);

    # get stream "News" on sampler "Channels" in the managed entity "Zoo"
    my $stream = $api->get_sampler("Zoo","Channels")->get_stream("News");

    # add a message to the stream
    $stream->add_message("Funky beats Cheeky in a chess boxing match!");

=head1 DESCRIPTION

C<Geneos::API> is a Perl module that implements ITRS XML-RPC Instrumentation API.
It can be used to create clients for both Geneos API and API Steams plug-ins.
The plug-in acts as an XML-RPC server.

Geneos C<Samplers>, C<Data Views> and C<Streams> are represented by instances of C<Geneos::API::Sampler>, C<Geneos::API::Sampler::View> and C<Geneos::API::Sampler::Stream> classes.
This provides easy to use building blocks for developing monitoring applications.

This module comes with its own XML-RPC module based on L<XML::LibXML> as ITRS implementation of XML-RPC does not conform to the XML-RPC standard and therefore most of the available XML-RPC modules cannot be used. The client uses L<LWP::UserAgent> and gives access to all the available constructor options provided by L<LWP::UserAgent>.

The module also provides customizable error and debug hanlders.

=head1 INSTALLATION

One of the easiest ways is to run:

    perl -MCPAN -e'install Geneos::API'

This will download and install the latest production version available from CPAN.

Alternatively, use any other method that suits you.

=head1 METHODS

=head2 Constructor

=head3 C<new>

    $api->new($url)
    $api->new($url, $options)

C<$url> is required and must be in the format:

C<http://host:port/path>

For example:

    my $api = Geneos::API->new("http://localhost:7036/xmlrpc");

XML-RPC Client is initialized upon call to the API constructor

=head3 Options

The constructor accepts a reference to the options hash as optional second parameter:

    my $api = Geneos::API->new("http://localhost:7036/xmlrpc", {
        api => {
            # XML-RPC API options:
            raise_error => 1,
        },
        ua  => {
            # UserAgent options:
            keep_alive => 20,
            timeout => 60,
        },
    });

=head4 B<api> - XML-RPC options

=over

=item * C<< raise_error >>

Force errors to raise exceptions via C<Carp::croak>

=item * C<< print_error >>

Force errors to raise warnings via C<Carp::carp>

=item * C<< error_handler >>

Custom error handler. See L</error_handler> section for more details.

=item * C<< debug_handler >>

Debug handler. See L</Debugging> section for more details.

=back

The order of precedence for error handling is as follows:

=over

=item * C<< error_handler >>

=item * C<< raise_error >>

=item * C<< print_error >>

=back

If neither is set, the errors won't be reported and L</error> method will need to be called to check if the latest call generated an error or not.

Example

    # force errors to raise exceptions:
    my $api = Geneos::API->new("http://example.com:7036/xmlrpc", {api=>{raise_error=>1,},});

=head4 B<ua> - UserAgent options

=over

=item * C<< any options supported by L<LWP::UserAgent> >>

=back

If no LWP::UserAgent options are passed to the constructor, the keep alive will be enabled with the total capacity of 10. In other words, the two calls below are identical:

    $api = Geneos::API->new("http://localhost:7036/xmlrpc")

    # is identical to
    $api = Geneos::API->new("http://localhost:7036/xmlrpc", {
        ua  => {
            keep_alive => 10,
        },
    });

    # but different to (keep alive disabled):
    $api = Geneos::API->new("http://localhost:7036/xmlrpc", {
        ua  => {},
    });

Note that if you pass the LWP::UserAgent options, the keep alive default won't be applied:

    # keep alive is not enabled
    $api = Geneos::API->new("http://localhost:7036/xmlrpc", {
        ua  => {
            timeout => 300,
        },
    });

Examples:

    # sets http timeout to 30 seconds and implicitly disables keep alive:
    $api = Geneos::API->new("http://example.com:7036/xmlrpc", {
        ua => {
           timeout=>30,
        },
    });

    # sets the agent name to "geneos-client/1.00"
    $api = Geneos::API->new("http://example.com:7036/xmlrpc", {
        ua => {
           agent=>"geneos-client/1.00",
        },
    });

=head2 API and API Streams Function Calls

There are three classes that represent Samplers, Views and Streams.

Samplers are represented by the internal C<Geneos::API::Sampler> class.
First, a sampler object must be created using C<get_sampler> method:

=head3 C<get_sampler>

    $api->get_sampler($managed_entity, $sampler_name)
    $api->get_sampler($managed_entity, $sampler_name, $type_name)

This method doesn't check whether the sampler exists. Use C<$type_name> parameter only if the sampler is a part of that type

Returns sampler object.

    $sampler = $api->get_sampler($managed_entity, $sampler_name, $type_name)

This will create a Sampler object representing a sampler with the name C<$sampler_name> in the managed entity C<$managed_entity>. You can call any method from the section L</"Sampler methods"> on this object.

To reference samplers which are part of a type, use $type_name parameter:

    # This will get sampler "Monkeys" in type "Animals" on managed entity "Zoo":
    $sampler_in_type = $api->get_sampler("Zoo", "Monkeys", "Animals")

    # If the sampler is assigned directly to managed entity:
    $sampler = $api->get_sampler("Zoo", "Monkeys")

Views are represented by the internal C<Geneos::API::Sampler::View> class.
In order to create an instance of this class, you can use:

    # if the view already exists
    $view = $sampler->get_view($view_name, $group_heading)

    # if the view does not exist yet and you want to create it
    $view = $sampler->create_view($view_name, $group_heading)

Once the view object is created, you can call any of the "View methods" on it.

Streams are represented by the internal C<Geneos::API::Sampler::Stream> class. In order to create an instance of this class, you can use:

    $stream = $sampler->get_stream($stream_name)

Once the object is created, you can call any of the L</"Stream methods"> on it.

=head2 Sampler methods

=head3 C<get_stream>

    $sampler->get_stream($stream_name)

The stream must already exist. This method will NOT check that the stream extists or not.

Returns an object representing the stream C<$stream_name>.

=head3 C<create_view>

    $sampler->create_view($view_name, $group_heading)

Creates a new, empty view C<$view_name> in the specified sampler under the specified C<$group_heading>.
This method will create a view and returns the object representing it. An error will be produced if the view already exists.

Returns C<OK> on successful completion.

=head3 C<get_view>

    $sampler->get_view($view_name, $group_heading)

The view must already exist. This method will NOT check that the view extists or not.
Use L</view_exists> method for that.

Returns an object representing the view C<$view_name>.

=head3 C<view_exists>

    $sampler->view_exists($view_name, $group_heading)

Checks whether a particular view exists in this sampler.

Returns C<1> if the view exists, C<0> otherwise.

=head3 C<remove_view>

    $sampler->remove_view($view_name)

Removes a view that has been created with create_view.

Returns C<OK> on successful completion.

=head3 C<get_parameter>

    $sampler->get_parameter($parameter_name)

Retrieves the value of a sampler parameter that has been defined in the gateway configuration.

Returns the parameter text written in the gateway configuration.

=head3 C<sign_on>

    $sampler->sign_on($period)

$period - The maximum time between updates before samplingStatus becomes FAILED

Commits the API client to provide at least one heartbeat or update to the view within the time period specified.

Returns C<OK> on successful completion.

=head3 C<sign_off>

    $sampler->sign_off()

Cancels the commitment to provide updates to a view.

Returns C<OK> on successful completion.

=head3 C<heartbeat>

    $sampler->heartbeat()

Prevents the sampling status from becoming failed when no updates are needed to a view and the client is signed on.

Returns C<OK> on successful completion.

=head2 View methods

=head3 C<add_table_row>

    $view->add_table_row($row_name,$data)

Adds a new, table row to the specified view and populates it with data.

Returns C<OK> on successful completion.

=head3 C<remove_table_row>

    $view->remove_table_row($row_name)

Removes an existing row from the specified view.

Returns C<OK> on successful completion.

=head3 C<add_headline>

    $view->add_headline($headline_name)

Adds a headline variable to the view.

Returns C<OK> on successful completion.

=head3 C<remove_headline>

    $view->remove_headline($headline_name)

Removes a headline variable from the view.

Returns C<OK> on successful completion.

=head3 C<update_variable>

    $view->update_variable($variable_name, $new_value)

Can be used to update either a headline variable or a table cell.
If the variable name contains a period (.) then a cell is assumed, otherwise a headline variable is assumed.

Returns C<OK> on successful completion.

=head3 C<update_headline>

    $view->update_headline($headline_name, $new_value)

Updates a headline variable.

Returns C<OK> on successful completion.

=head3 C<update_table_cell>

    $view->update_table_cell($cell_name, $new_value)

Updates a single cell in a table. The standard C<row.column> format should be used to reference a cell.

Returns C<OK> on successful completion.

=head3 C<update_table_row>

    $view->update_table_row($row_name, $new_value)

Updates an existing row from the specified view with the new values provided.

Returns C<OK> on successful completion.

=head3 C<add_table_column>

    $view->add_table_column($column_name)

Adds another column to the table.

Returns C<OK> on successful completion.

=head3 C<update_entire_table>

    $view->update_entire_table($new_table)

Updates the entire table for a given view. This is useful if the entire table will change at once or the table is being created for the first time.
The array passed should be two dimensional. The first row should be the column headings and the first column of each subsequent row should be the name of the row.
The array should be at least 2 columns by 2 rows. Once table columns have been defined, they cannot be changed by this method.

Returns C<OK> on successful completion.

=head3 C<column_exists>

    $view->column_exists($column_name)

Check if the headline variable exists.

Returns C<1> if the column exists, C<0> otherwise.

=head3 C<row_exists>

    $view->row_exists($row_name)

Check if the headline variable exists.

Returns C<1> if the row exists, C<0> otherwise.

=head3 C<headline_exists>

    $view->headline_exists($headline_name)

Check if the headline variable exists.

Returns C<1> if the headline variable exists, C<0> otherwise.

=head3 C<get_column_count>

    $view->get_column_count()

Return the column count of the view.

Returns the number of columns in the view. This includes the rowName column.

=head3 C<get_row_count>

    $view->get_row_count()

Return the headline count of the view.

Returns the number of headlines in the view. This includes the C<samplingStatus> headline.

=head3 C<get_headline_count>

    $view->get_headline_count()

Returns the number of headlines in the view. This includes the C<samplingStatus> headline.

=head3 C<get_column_names>

    $view->get_column_names()

Returns the names of existing columns in the view. This includes the rowNames column name.

=head3 C<get_row_names>

    $view->get_row_names()

Returns the names of existing rows in the view

=head3 C<get_headline_names>

    $view->get_headline_names()

Returns the names of existing headlines in the view.
This includes the C<samplingStatus> headline.

=head3 C<get_row_names_older_than>

    $view->get_row_names_older_than($timestamp)

C<$timestamp> - The timestamp against which to compare row update time.
The timestamp should be provided as Unix timestamp, i.e. number of seconds elapsed since UNIX epoch.

Returns the names of rows whose update time is older than the time provided.

=head2 Stream methods

=head3 C<add_message>

    $stream->add_message($message)

Adds a new message to the end of the stream.

Returns C<OK> on successful completion.

=head2 NetProbe Function Calls

=head3 C<managed_entity_exists>

    $api->managed_entity_exists($managed_entity)

Checks whether a particular Managed Entity exists on this NetProbe containing any API or API-Streams samplers.

Returns C<1> if the Managed Entity exists, C<0> otherwise

=head3 C<sampler_exists>

    $api->sampler_exists($managed_entity, $sampler_name)
    $api->sampler_exists($managed_entity, $sampler_name, $type_name)

Checks whether a particular API or API-Streams sampler exists on this NetProbe

Returns C<1> if sampler exists, C<0> otherwise

If the sampler in the question is part of the type - use the $type_name parameter.
See examples for L</get_sampler> method

=head3 C<gateway_connected>

    $api->gateway_connected()

Checks whether the Gateway is connected to this NetProbe

Returns C<1> if the Gateway is connected, C<0> otherwise

=head2 Gateway Function Calls

=head3 C<add_managed_entity>

    $api->add_managed_entity($managed_entity, $data_section)

Adds the managed entity to the particular data section

Returns C<1> on success, C<0> otherwise

=head2 Error handling

=head3 C<raise_error>

    $api->raise_error()

Get the raise_error attribute value

Returns C<1> is the raise_error attribute is set or C<0> otherwise

If the raise_error attribute is set, errors generated by API calls will be passed to C<Carp::croak>

=head3 C<remove_raise_error>

    $api->remove_raise_error()

Remove the raise_error attribute

=head3 C<print_error>

    $api->print_error()

Get the print_error attribute value

Returns C<1> is the print_error attribute is set or C<0> othersise

If the print_error attribute is set, errors generated by API calls will be passed to C<Carp::carp>

print_error attribute is ignored if raise_error is set.

=head3 C<remove_print_error>

    $api->remove_print_error()

Remove the print_error attribute

=head3 C<status_line>

    $api->status_line()

Returns the string C<< <code> <message> >>. Returns C<undef> if there is no error.

=head3 C<error>

    $api->error

Get the error produced by the last api call.

Returns reference to the error hash or undef if the last call produced no error.
The hash contains three elements:

=over

=item * code

HTTP or XML-RPC error code.

=item * message

Error string.

=item * class

The component that produced the error: C<HTTP> or C<XML-RPC>.

=back

Example

   my $e = $api->error;
   printf("code: %d\nmessage: %s\n", $e->{code}, $e->{message});

   # example output:
   code: 202
   message: Sampler does not exist

=head3 C<error_handler>

    $api->error_handler()

Allows you to provide your own behaviour in case of errors.

The handler must be passed as a reference to subroutine and it could be done as a constructor option:

    my $api = Geneos::API->new("http://localhost:7036/xmlrpc", {
        api => { error_handler => \&my_error_handler, },
    });

or via a separate method:

    $api->error_handler(\&my_error_handler)

The subroutine is called with two parameters: reference to the error hash and the api object itself.

For example, to die with a full stack trace for any error:

    use Carp;
    $api->error_handler( sub { confess("$_[0]->{code} $_[0]->{message}") } );

Please note that the custom error handler overrides the raise_error and print_error settings.

The error handler can be removed by calling:

    $api->remove_error_handler()

=head2 Debugging

The module comes with a debug handler. The handler must be passed as a reference to subroutine and it could be done as a constructor option:

    my $api = Geneos::API->new("http://localhost:7036/xmlrpc", {
        api => { debug_handler => \&my_debug_handler, },
    });

    # or via a separate method:
    $api->debug_handler(\&my_debug_handler)

The subroutine is called with one parameter: C<Geneos::API::XMLRPC> object.

The following C<Geneos::API::XMLRPC> methods might be useful for debugging purposes:

=over 4

=item * C<t0>

Returns the time at the start of the request. It's captured using Time::HiRes::gettimeofday
method: C<$t0 = [gettimeofday]>

=item * C<xmlrpc_request>

Returns the C<Geneos::API::XMLRPC::Request> object.

=item * C<xmlrpc_response>

Returns the C<Geneos::API::XMLRPC::Response> object.

=item * C<http_request>

Returns the C<HTTP::Request> object. See L<HTTP::Request> for more details.

=item * C<http_response>

Returns the C<HTTP::Response> object.  See L<HTTP::Response> for more details.

=back

The debug handler can be removed by calling:

    $api->remove_debug_handler()

Example.

The custom debug handler in this example will output the following stats:

=over 4

=item * Elapsed time

=item * HTTP request headers

=item * HTTP response headers

=back

    use Time::HiRes qw(tv_interval);

    $api->debug_handler(\&custom_debug_handler);

    sub custom_debug_handler {
        my $api_obj = shift;

        printf "# elapsed time: %f\n\n# request header:\n%s\n# response header:\n%s\n",
               tv_interval($api_obj->t0),
               $api_obj->http_request->headers_as_string,
               $api_obj->http_response->headers_as_string;
    }

Upon execution, it will produce output similar to:

    # elapsed time: 0.002529

    # request header:
    User-Agent: libwww-perl/6.04
    Content-Type: text/xml

    # response header:
    Connection: Keep-Alive
    Server: GENEOS XML-RPC
    Content-Length: 152
    Content-Type: text/xml
    Client-Date: Fri, 26 Dec 2014 16:18:10 GMT
    Client-Peer: 127.0.0.1:7036
    Client-Response-Num: 1

=head1 EXAMPLE

This is a Perl version of the C++/Java example from the ITRS documentation.

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Geneos::API;

    unless (@ARGV == 2) {
        warn "Usage: QueueSamplerClient serverHost serverPort\n";
        exit -1;
    }

    my ($host,$port) = @ARGV;

    my $api = Geneos::API->new("http://$host:$port/xmlrpc",{api=>{raise_error=>1,},});

    my $sampler = $api->get_sampler("myManEnt","mySampler");
    my $view = $sampler->create_view("queues","myGroup");

    $view->add_headline("totalQueues");
    $view->add_headline("queuesOffline");

    my $table = [
        ["queueName","currentSize","maxSize","currentUtilisation","status"],
        ["queue1",332,30000,"0.11","online"],
        ["queue2",0,90000,"0","offline"],
        ["queue3",7331,45000,"0.16","online"]
    ];

    $view->update_entire_table($table);
    $view->update_headline("totalQueues",3);
    $view->update_headline("queuesOffline",1);

    for(1..1000) {
        $view->update_table_cell("queue2.currentSize",$_);
        sleep 1;
    }

To run this example: setup the managed entity and the sampler as per the instructions given in the ITRS documentation, save this code as I<QueueSamplerClient>, make it executable and run:

    ./QueueSamplerClient localhost 7036

This assumes that the NetProbe runs on the localhost and port 7036

=head1 ONLINE RESOURCES AND SUPPORT

=over 4

=item * L<ITRS Group|http://www.itrsgroup.com/>

=item * L<XML-RPC Specification|http://xmlrpc.scripting.com/>

=item * Drop me an email if you have any questions with Geneos::API in the subject

=back

=head1 KNOWN ISSUES

Few issues have been discovered while testing ITRS Instrumentation API.
These issues are not caused by Geneos::API Perl module but ITRS implementation of the XML-RPC interface to Geneos.

=over 4

=item * Memory leak in the netprobe

Memory leak occurs when data view is removed via entity.sampler.removeView call

One way to reproduce this issue is to perform a serious of calls:

   ...
   entity.sampler.removeView
   entity.sampler.createView
   entity.sampler.view.updateEntireTable
   ...

The memory usage by the NetProbe process grows almost linear when the data view size is constant.

=item * Invalid parameters passed to XML-RPC method can crash netprobe

An entity.sampler.UpdateEntireTable call with a scalar parameter instead of 2 dimensional array crashes the NetProbe:

    <?xml version="1.0" encoding="utf-8"?>
    <methodCall>
      <methodName>entity.sampler.group-view.updateEntireTable</methodName>
      <params>
        <param>
          <value><string>scalar instead of array</string></value>
        </param>
      </params>
    </methodCall>

=back

Please contact ITRS directly for the latest status.

=head1 BUGS

Of course. Please raise a ticket via L<rt.cpan.org|https://rt.cpan.org/>

=head1 AUTHOR

Ivan Dmitriev, E<lt>tot@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Ivan Dmitriev

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

    ###############################################################
    #
    # package Geneos::API::XMLRPC::Response
    #
    # Parses XML-RPC response and converts it into Perl structure
    #
    ###############################################################

    package Geneos::API::XMLRPC::Response;

    use strict;

    use XML::LibXML qw(:libxml);

    # -----------
    # Constructor

    sub new {
        my $this = shift;
        my $class = ref($this) || $this;
        my $self = {
            _response => {},
            _error => undef,
        };

        bless $self, $class;
        $self->_init(@_);
    }

    # ---------------
    # Private methods

    sub _init {
        my ($self, $response) = @_;

        # Check if the HTTP request succeeded
        if ($response->is_success) {

            my $dom = XML::LibXML->load_xml(string => $response->decoded_content);
            process_node($self->{_response}, $dom->documentElement);

            if (exists $self->{_response}{fault}) {
                my $code = exists $self->{_response}{fault}{faultCode}
                         ? $self->{_response}{fault}{faultCode}
                         : -1;

                my $str  = exists $self->{_response}{fault}{faultString}
                         ? $self->{_response}{fault}{faultString}
                         : 'NO_ERROR_STRING';

                $self->error({class=>"XML-RPC", code=>$code, message=>$str,});
            }

        }
        else {
            $self->error({class=>"HTTP", code=>$response->code, message=>$response->message,});
        }

        return $self;
    }

    # --------------
    # Public methods

    sub is_success {!shift->error}

    sub params {shift->{_response}{params}}

    sub error {
        my ($self, $error) = @_;
        $self->{_error} = $error if $error;

        return $self->{_error};
    }

    # ---------------
    # Response parser

    sub process_node {
        my ($r, $node) = @_;

        for my $child ($node->childNodes) {

            if ($child->nodeName eq "struct") {
                process_struct($r, $child);
            }
            elsif ($child->nodeName eq "fault") {
                process_fault($r, $child);
            }
            elsif ($child->nodeName eq "params") {
                process_params($r, $child);
            }
            elsif ($child->nodeName eq "array") {
                process_array($r, $child);
            }
            elsif ($child->nodeName =~ m/^i4|int|boolean|string|double|dateTime\.iso8601|base64$/) {
                $$r = $child->textContent;
            }
            elsif ($child->nodeType == 3
                && $node->nodeName eq "value"
                && $node->childNodes->size == 1
            ) {
                $$r = $child->textContent;
            }
            else {
                process_node($r, $child);
            }
        }
    }

    sub process_fault {
        my ($r, $node) = @_;

        my ($value) = $node->findnodes("./value");

        process_node(\$r->{fault}, $value);
    }

    sub process_struct {
        my ($r, $node) = @_;

        foreach my $member ( $node->findnodes("./member") ) {
            my ($name)  = $member->findnodes("./name");
            my ($value) = $member->findnodes("./value");

            process_node(\$$r->{$name->textContent}, $value);
        }
    }

    sub process_array {
        my ($r, $node) = @_;

        foreach my $value ( $node->findnodes("./data/value") ) {
            process_node(\$$r->[++$#{$$r}], $value);
        }
    }

    sub process_params {
        my ($r, $node) = @_;

        $r->{params} = [];

        foreach my $param ( $node->findnodes("./param") ) {
            my ($value) = $param->findnodes("./value");
            process_node(\$r->{params}[++$#{$r->{params}}], $value);
        }
    }

    ###########################################
    #
    # package Geneos::API::XMLRPC::Request
    #
    # Converts method and Perl data structure
    # into an XML-RPC request body
    #
    ###########################################

    package Geneos::API::XMLRPC::Request;

    use XML::LibXML;

    # -----------
    # Constructor

    sub new {
        my $this = shift;
        my $class = ref($this) || $this;
        my $self = {};
        bless $self, $class;
        $self->_init(@_);
    }

    # ---------------
    # Private methods

    sub _init {
        my ($self, $method, @params) = @_;

        # remember the method and params
        $self->{_method} = $method;
        $self->{_params} = \@params;

        $self->{doc} = XML::LibXML::Document->new('1.0', 'utf-8');

        my $root = $self->{doc}->createElement("methodCall");
        $self->{doc}->setDocumentElement($root);

        # ------------------
        # Add the methodName

        my $methodName = $self->{doc}->createElement("methodName");
        $methodName->appendTextNode($method);
        $root->appendChild($methodName);

        # --------------
        # Add the params
        my $params = $self->{doc}->createElement("params");
        $root->appendChild($params);

        # ---------------------
        # Process the agruments
        foreach (@params) {
            my $param = $self->{doc}->createElement("param");
            $params->addChild($param);
            $self->parse($param, $_);
        }

        return $self;
    }

    # --------------
    # Public methods

    # accessor for the method
    sub method {shift->{_method}}

    # accessor for the params
    sub params {shift->{_params}}

    sub content {shift->{doc}->toString}

    sub parse {
        my ($self, $node, $p) = @_;

        my $value = $self->{doc}->createElement("value");
        $node->addChild($value);

        if ( ref($p) eq 'HASH' ) {
            $self->parse_hash($value,$p);
        }
        elsif ( ref($p) eq 'ARRAY' ) {
            $self->parse_array($value,$p);
        }
        elsif ( ref($p) eq 'CODE' ) {
            $self->parse_code($value,$p);
        }
        else {
            $self->parse_scalar($value,$p);
        }
    }

    # It seems that Geneos treats everything as a string
    # no need for anything sophisticated here

    sub parse_scalar {
        my ($self, $node, $scalar) = @_;

        $scalar ||= "";

        if (( $scalar =~ m/^[\-+]?\d+$/) && (abs($scalar) <= (0xffffffff >> 1))) {
            my $i = $self->{doc}->createElement("i4");
            $i->appendTextNode($scalar);
            $node->appendChild($i);
        }
        elsif ( $scalar =~ m/^[\-+]?\d+\.\d+$/ ) {
            my $d = $self->{doc}->createElement("double");
            $d->appendTextNode($scalar);
            $node->appendChild($d);
        }
        else {
            my $s = $self->{doc}->createElement("string");
            $s->appendTextNode($scalar);
            $node->appendChild($s);
        }
    }

    sub parse_hash {
        my ($self, $node, $hash) = @_;

        my $struct = $self->{doc}->createElement("struct");
           $node->appendChild($struct);

           foreach (keys %$hash) {
               my $member = $self->{doc}->createElement("member");
               $struct->appendChild($member);

               my $name = $self->{doc}->createElement("name");
               $name->appendTextNode($_);
               $member->appendChild($name);

               $self->parse($member, $hash->{$_});
           }
    }

    sub parse_array {
        my ($self, $node, $args) = @_;

        my $array = $self->{doc}->createElement("array");
        $node->appendChild($array);

        my $data = $self->{doc}->createElement("data");
        $array->appendChild($data);

        $self->parse($data, $_) for @$args;
    }

    sub parse_code {
        my ($self, $node, $code) = @_;

        my ($type, $data) = $code->();

        my $e = $self->{doc}->createElement($type);
        $e->appendTextNode($data);
        $node->appendChild($e);
    }

    ########################################################################
    #
    # package Geneos::API::XMLRPC
    #
    # XML-RPC client
    # The reason for yet another XML-RPC implementation is that
    # because Geneos XML-RPC does not conform to the XML-RPC standard:
    #
    # * '-', '(' and ')' characters may be used in the method names
    # * the values do not default to type 'string'
    #
    # Among other reasons, ensuring that HTTP1.1 is used to take advantage
    # of the keep alive feature supported by Geneos XML-RPC server
    #
    ########################################################################

    package Geneos::API::XMLRPC;

    use LWP::UserAgent;
    use Time::HiRes qw(gettimeofday);

    # -----------
    # Constructor

    sub new {
        my $this = shift;

        my $class = ref($this) || $this;
        my $self = {};
        bless $self, $class;

        $self->_init(@_);
    }

    # ---------------
    # Private methods

    sub _init {
        my ($self, $url, $opts) = @_;

        $self->{_url} = $url;

        $opts ||= {};
        $opts->{ua} ||= {};

        # set up the UserAgent
        $self->{_ua} = LWP::UserAgent->new(%{$opts->{ua}});

        return $self;
    }

    # --------------
    # Public methods

    sub request {
        my ($self, $method, @params) = @_;

        # record the start time
        $self->{_t0} = [gettimeofday];

        # prepare the XML-RPC request
        $self->{_xmlrpc_request} = Geneos::API::XMLRPC::Request->new($method, @params);

        # create an http request
        $self->{_http_request} = HTTP::Request->new("POST",$self->{_url});

        $self->{_http_request}->header('Content-Type' => 'text/xml');
        $self->{_http_request}->add_content_utf8($self->{_xmlrpc_request}->content);

        # send the http request
        $self->{_http_response} = $self->{_ua}->request($self->{_http_request});

        # parse the http response
        $self->{_xmlrpc_response} = Geneos::API::XMLRPC::Response->new($self->{_http_response});
    }

    # the LWP::UserAgent object
    sub user_agent {shift->{_ua}}

    # --------------------------------------
    # These methods are useful for debugging
    #

    # Request start time (epoch seconds)
    sub t0 {shift->{_t0}}

    # XML-RPC request: instance of Geneos::API::XMLRPC::Request
    sub xmlrpc_request  {shift->{_xmlrpc_request}}

    # XML-RPC response: instance of Geneos::API::XMLRPC::Response
    sub xmlrpc_response {shift->{_xmlrpc_response}}

    # HTTP request: instance of HTTP::Request
    sub http_request    {shift->{_http_request}}

    # HTTP response: instance of HTTP::Response
    sub http_response   {shift->{_http_response}}

    ###########################################################################
    # package Geneos::API::Base                                               #
    #                                                                         #
    # This base class implements error handling and interface to              #
    # Geneos::API::XMLRPC  that is used by Geneos::API, Geneos::API::Sampler, #
    # Geneos::API::Sampler::View and Geneos::API::Sampler::Stream classes     #
    #                                                                         #
    ###########################################################################

    package Geneos::API::Base;

    use Carp;

    our $VERSION = '1.00';

    sub new {bless({_error=>undef,}, shift)->_init(@_)}

    sub status_line {
        my $self = shift;

        if ($self->{_error}) {
            my $code    = $self->{_error}->{code}    || '000';
            my $message = $self->{_error}->{message} || 'Empty';
            return "$code $message";
        }
        else {
            return undef;
        }
    }

    sub call {
        my ($self, $method, @params) = @_;

        $self->_reset_error;

        # send the XMLRPC request to the NetProbe
        my $response = $self->api->request($self->_method($method), @params);

        # debug handler is passed the xmlrpc object
        $self->api->{_debug_handler}->($self->api->xmlrpc) if $self->api->{_debug_handler};

        # check the response
        if ($response->is_success) {
            $response->params->[0];
        }
        else {
            $self->_handle_error($response->error);
        }
    }

    sub error {shift->{_error}}

    sub _error {
        my ($self, $error) = @_;
        $self->{_error} = $error if $error;

        return $self->{_error};
    }

    sub _handle_error {
        my ($self, $error) = @_;

        # check if there is an error to handle
        unless (ref($error) eq 'HASH') {
            $error = {
                class   => '_INTERNAL',
                code    => '999',
                message => "Expected hashref but received '$error' instead",
            };
        }

        # record the error
        $self->_error($error);

        # execute the error handler code
        $self->api->{_error_handler}->($error, $self) if $self->api->{_error_handler};

        # always return undef
        return;
    }

    sub _reset_error {shift->{_error} = undef}

    #######################################
    #
    # package Geneos::API::Sampler::Stream
    #
    # Implements all Steam methods
    #
    #######################################

    package Geneos::API::Sampler::Stream;

    use base 'Geneos::API::Base';
    use Carp;

    # ---------------
    # Private methods

    sub _init {
        my ($self, $sampler, $stream) = @_;

        croak "Geneos::API::Sampler::Stream->new was called without SAMPLER!" unless $sampler;
        croak "Geneos::API::Sampler::Stream->new was called without STREAM!" unless $stream;

        $self->{_sampler} = $sampler;
        $self->{_stream}  = $stream;

        return $self;
    }

    sub _method {
        my $self = shift;
        join(".", $self->{_sampler}->entity, $self->{_sampler}->sampler, $self->{_stream}, @_);
    }

    # --------------
    # Public methods

    sub api {shift->{_sampler}->api}

    # API Streams Function Calls

    sub add_message {shift->call("addMessage", @_)}

    ######################################
    #
    # package Geneos::API::Sampler::View
    #
    # Implements all View methods
    #
    ######################################

    package Geneos::API::Sampler::View;

    use base 'Geneos::API::Base';
    use Carp;

    # ---------------
    # Private methods

    sub _init {
        my ($self, $sampler, $view, $group) = @_;

        croak "Geneos::API::Sampler::View->new was called without SAMPLER!" unless $sampler;
        croak "Geneos::API::Sampler::View->new was called without VIEW!" unless $view;
        croak "Geneos::API::Sampler::View->new was called without GROUP!" unless $group;

        $self->{_sampler} = $sampler;
        $self->{_view}    = $view;
        $self->{_group}   = $group;

        return $self;
    }

    sub _method {
        my $self = shift;
        join(".", $self->{_sampler}->entity, $self->{_sampler}->sampler, "$self->{_group}-$self->{_view}", @_);
    }

    # --------------
    # Public methods

    sub api {shift->{_sampler}->api}

    # API calls

    # ---------------------------------------------
    # Combines addTableRow and updateTableRow calls
    #
    sub add_table_row {
        my ($self, $name, $data) = @_;

        return unless $self->_add_table_row($name);

        # if there is data - add it to the row
        $data ? $self->update_table_row($name, $data) : 1;
    }

    # -----------------------------------------------------
    # Each method below is an XML-RPC call to the NetProbe
    #
    # The first argument passed to the call method is the
    # XML-RPC method name. The rest are parameters passed
    # with that call to the XML-RPC server:
    #
    # method->($method_name, @params)
    #

    sub _add_table_row {shift->call("addTableRow", @_)}

    sub remove_table_row {shift->call("removeTableRow", @_)}

    sub add_headline {shift->call("addHeadline", @_)}

    sub remove_headline {shift->call("removeHeadline", @_)}

    sub update_variable {shift->call("updateVariable", @_)}

    sub update_headline {shift->call("updateHeadline", @_)}

    sub update_table_cell {shift->call("updateTableCell", @_)}

    sub update_table_row {shift->call("updateTableRow", @_)}

    sub add_table_column {shift->call("addTableColumn", @_)}

    sub update_entire_table {shift->call("updateEntireTable", @_)}

    sub column_exists {shift->call("columnExists", @_)}

    sub row_exists {shift->call("rowExists", @_)}

    sub headline_exists {shift->call("headlineExists", @_)}

    sub get_column_count {shift->call("getColumnCount")}

    sub get_row_count {shift->call("getRowCount")}

    sub get_headline_count {shift->call("getHeadlineCount")}

    sub get_column_names {shift->call("getColumnNames")}

    sub get_row_names {shift->call("getRowNames")}

    sub get_headline_names {shift->call("getHeadlineNames")}

    sub get_row_names_older_than {shift->call("getRowNamesOlderThan", @_)}

    ##################################
    #
    # package Geneos::API::Sampler
    #
    # Implements all sampler methods
    #
    ##################################

    package Geneos::API::Sampler;

    use base 'Geneos::API::Base';
    use Carp;

    # ---------------
    # Private methods

    sub _init {
        my ($self, $api, $entity, $sampler, $type) = @_;

        croak "Geneos::API::Sampler->new was called without ENTITY!" unless $entity;
        croak "Geneos::API::Sampler->new was called without SAMPLER!" unless $sampler;

        $self->{_api}     = $api;
        $self->{_entity}  = $entity;
        $self->{_sampler} = $type ? "${sampler}($type)" : $sampler;

        return $self;
    }

    # ---------------------------------------------------------
    # XML-RPC methodName for the sampler calls looks like this:
    # entity.sampler.action
    #
    # in case the sampler is part of a type, the call becomes:
    # entity.sampler(type).action
    #

    sub _method {
        my $self = shift;
        join(".", $self->entity, $self->sampler, @_);
    }

    # -------------------------------------
    # Public methods

    sub api {shift->{_api}}
    sub sampler {shift->{_sampler}}
    sub entity {shift->{_entity}}

    sub get_stream {
        my $self = shift;
        $self->_reset_error;
        Geneos::API::Sampler::Stream->new($self, @_)
    }

    # -------------------------------------
    # returns an instance of the view class

    sub get_view {
        my $self = shift;
        $self->_reset_error;
        Geneos::API::Sampler::View->new($self, @_)
    }

    #############
    # API calls #
    #############

    sub create_view {
        my $self = shift;
        $self->call("createView", @_) ? Geneos::API::Sampler::View->new($self, @_) : undef;
    }

    # -------------------------------------------------------
    # Checks whether a particular view exists in this sampler
    #
    # Returns 1 if the view exists, 0 otherwise
    #

    sub view_exists {
        my ($self, $view, $group) = @_;
        $self->call("viewExists", "${group}-${view}");
    }

    sub remove_view {shift->call("removeView", @_)}

    # -----------------------------------------------
    # Retrieves the value of a sampler parameter that
    # has been defined in the gateway configuration
    #
    # Returns the parameter text written in the gateway configuration
    #

    sub get_parameter {shift->call("getParameter", @_)}

    sub sign_on {shift->call("signOn", @_)}

    sub sign_off {shift->call("signOff")}

    sub heartbeat {shift->call("heartbeat")}

    ######################################
    #
    # package Geneos::API
    #
    # Implements the Geneos XML-RPC API
    #
    ######################################

    package Geneos::API;

    our $VERSION = '1.00';

    use base 'Geneos::API::Base';
    use Carp;
    use Time::HiRes qw(tv_interval);

    use constant DEFAULT_TOTAL_CAPACITY => 10;

    # ---------------
    # Private methods

    sub _init {
        my ($self, $url, $opts) = @_;

        # the url must be present
        croak "Geneos::API->new was called without URL!" unless $url;

        # if options are passed - it must be a hashref
        if ($opts) {
            croak "Options for Geneos::API->new must be passed as a HASHREF!" unless ref($opts) eq 'HASH';
        }
        else {
            # init the options
            $opts ||= {};
        }

        # enable keep alive by default
        $opts->{ua} ||= {keep_alive=>DEFAULT_TOTAL_CAPACITY,};

        # no api options are set by default
        $opts->{api} ||= {};

        $self->{_xmlrpc} = Geneos::API::XMLRPC->new($url, $opts);
        $self->{_opts} = $opts;

        # ----------------------
        # init the error handler

        if (ref($opts->{api}{error_handler}) eq 'CODE') {
            $self->error_handler($opts->{api}{error_handler});
        }
        elsif ($opts->{api}{raise_error}) {
            $self->error_handler(
                sub {croak("$_[0]->{code} $_[0]->{message}")}
            );
        }
        elsif ($opts->{api}{print_error}) {
            $self->error_handler(
                sub {carp("$_[0]->{code} $_[0]->{message}")}
            );
        }

        # ----------------------
        # init the debug handler

        if ($opts->{api}{debug_handler}) {
            $self->debug_handler($opts->{api}{debug_handler});
        }

        return $self;
    }

    sub _method {shift;@_}

    # --------------
    # Public methods

    # ---------------------
    # get/set error handler

    sub error_handler {
        my ($self, $handler) = @_;

        if (ref($handler) eq 'CODE') {
            $self->{_error_handler} = $handler;
        }
        elsif ($handler) {
            carp("argument for error_handler must be a coderef but got: ", ref($handler));
        }

        return $self->{_error_handler};
    }

    # --------------------
    # remove error handler

    sub remove_error_handler {shift->{_error_handler}=undef;}

    # ---------------------
    # get/set debug handler

    sub debug_handler {
        my ($self, $handler) = @_;

        if (ref($handler) eq 'CODE') {
            $self->{_debug_handler} = $handler;
        }
        elsif ($handler) {
            carp("argument for debug_handler must be a coderef but got: ", ref($handler));
        }

        return $self->{_debug_handler};
    }

    # --------------------
    # remove debug handler

    sub remove_debug_handler {shift->{_debug_handler}=undef;}

    sub raise_error {shift->{_opts}{api}{raise_error}}

    sub remove_raise_error {shift->{_opts}{api}{raise_error}=undef;}

    sub print_error {shift->{_opts}{api}{print_error}}

    sub remove_print_error {shift->{_opts}{api}{print_error}=undef;}

    sub api{shift}

    # send XMLRPC request
    sub request {shift->{_xmlrpc}->request(@_)}

    # LWP::UserAgent object
    sub user_agent {shift->{_xmlrpc}->user_agent}

    # Geneos::API::XMLPRC object
    sub xmlrpc {shift->{_xmlrpc}}

    #############
    # API calls #
    #############

    # ------------------------
    # Creates a sampler object

    sub get_sampler {
        my $self = shift;
        $self->_reset_error;
        Geneos::API::Sampler->new($self,@_)
    }

    # -------------------------------------------------------------
    # Checks whether a particular API or API-Streams sampler exists
    # on this NetProbe. If the sampler is part of a type, it needs
    # to be passed as sampler_name(type_name)
    #
    # Returns 1 if the sampler exists, 0 otherwise
    #

    sub sampler_exists {
        my ($self, $me, $sampler, $type) = @_;
        $sampler = "${sampler}($type)" if $type;
        $self->call("_netprobe.samplerExists", "$me.$sampler");
    }

    # ---------------------------------------------------------
    # Checks whether the Gateway is connected to this NetProbe
    #
    # Returns 1 if the Gateway is connected, 0 otherwise
    #

    sub gateway_connected {shift->call("_netprobe.gatewayConnected")}

    # ------------------------------------------------------
    # Adds the managed entity to the particular data section
    #
    # Returns 1 on success, 0 otherwise
    #

    sub add_managed_entity {shift->call("_gateway.addManagedEntity", @_)}

    # ------------------------------------------------------------------
    # Checks whether a particular Managed Entity exists on this NetProbe
    # containing any API or API-Streams samplers
    #
    # Returns 1 if the Managed Entity exists, 0 otherwise
    #

    sub managed_entity_exists {shift->call("_netprobe.managedEntityExists", @_)}

    1;

__END__
