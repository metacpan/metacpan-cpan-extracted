package DBI::Gofer::Transport::mod_perl;

use strict;
use warnings;

our $VERSION = 1.017; # keep in sync with Makefile.PL

use UNIVERSAL qw(can);
use Sys::Hostname qw(hostname);
use List::Util qw(min max sum);

use DBI 1.605, qw(dbi_time);
use DBI::Gofer::Execute;
use Socket;

use constant MP2 => ( ($ENV{MOD_PERL_API_VERSION}||0) >= 2 or eval "require Apache2::Const");
BEGIN {
  if (MP2) {
    require Apache2::Connection;
    require Apache2::RequestIO;
    require Apache2::RequestRec;
    require Apache2::RequestUtil;
    require Apache2::Response;
    require Apache2::Const;
    Apache2::Const->import(qw(OK DECLINED SERVER_ERROR));
    require APR::Base64;
    *encode_base64 = \&APR::Base64::encode;
    *decode_base64 = \&APR::Base64::decode;
    *escape_html = sub {
        my $s = shift;
        $s =~ s/&/&amp;/g;
        $s =~ s/</&lt;/g;
        $s =~ s/>/&gt;/g;
        return $s;
    }
  }
  else {
    require Apache::Constants;
    Apache::Constants->import(qw(OK DECLINED SERVER_ERROR));
    require Apache::Util;
    Apache::Util->import(qw(escape_html));
    require MIME::Base64;
    MIME::Base64->import(qw(encode_base64 decode_base64));
  }
}

use DBI::Gofer::Serializer::DataDumper;

use base qw(DBI::Gofer::Transport::Base);

our $transport = __PACKAGE__->new();

our %executor_configs = ( default => { } );
our %executor_cache;
our $show_client_hostname_in_status = 1;
our $datadumper_serializer = DBI::Gofer::Serializer::DataDumper->new;

_install_apache_status_menu_items(
    DBI_gofer => [ 'DBI Gofer', \&_apache_status_dbi_gofer ],
);


sub handler : method {
    my $self = shift;
    my $r = shift;
    my $time_received = dbi_time();
    my $headers_in = $r->headers_in;

    my ($frozen_request,  $request,  $request_serializer);
    my ($frozen_response, $response, $response_serializer);
    my $executor;

    my $http_status = SERVER_ERROR;
    my $remote_ip = $headers_in->{Client_ip}    # e.g., cisco load balancer
        || $headers_in->{'X-Forwarded-For'}     # e.g., mod_proxy (XXX may contain more than one ip)
        || $r->connection->remote_ip;

    eval {
        $executor = $self->executor_for_apache_request($r);

        my $request_content_length = $headers_in->{'Content-Length'};
        # XXX get content-type by response_content_type() meth call on serializer?
        # (need to think-through content-type, transfer-encoding, disposition etc etc
        my $response_content_type = 'application/x-perl-gofer-response-binary';
        # XXX should probably contol flow via method: GET vs POST
        my $of = "";
        if (!$request_content_length) { # assume GET request
            my $args = $r->args || '';
            my %args = map { (split('=',$_,2))[0,1] } split /[&;]/, $args, -1;
            my $req = $args{req}
                or die "No req argument or Content-Length ($args)\n";
            $frozen_request = decode_base64($req);

            if ($args{_dd}) { # XXX temp hack
                $response_serializer = $datadumper_serializer;
                $response_content_type = 'text/plain';
                if ($args{_dd} eq 'request') { # XXX even more of a temp hack
                    $request = $transport->thaw_request($frozen_request);
                    $r->pnotes(gofer_request => $request);
                    $frozen_response = $datadumper_serializer->serialize($request);
                    goto send_frozen_response;
                }
            }
        }
        else {
            my $content_type = $headers_in->{'Content-Type'};
            die "Unsupported gofer Content-Type"
                unless $content_type eq 'application/x-perl-gofer-request-binary';
            $r->read($frozen_request, $request_content_length);
            if (length($frozen_request) != $request_content_length) {
                die sprintf "Gofer request length (%d) doesn't match Content-Length header (%d)",
                    length($frozen_request), $request_content_length;
            }
        }

        $request = $transport->thaw_request($frozen_request);
        $r->pnotes(gofer_request => $request);

        $response = $executor->execute_request( $request );
        $r->pnotes(gofer_response => $response);

        $frozen_response = $transport->freeze_response($response, $response_serializer);

    send_frozen_response:
        $r->content_type($response_content_type);
        # setup http headers
        # See http://perl.apache.org/docs/general/correct_headers/correct_headers.html
        # provide Content-Length for KeepAlive so it works if people want it
        $r->headers_out->{'Content-Length'} = do { use bytes; length($frozen_response) };

        $r->print($frozen_response);

        $http_status = OK;
    };
    if ($@) {
        # for errors at this level we don't send a serialized Gofer Response 
        # (but we do create one for logging/stats purposes)

        $http_status = SERVER_ERROR;

        # discard any response that might have been prepared already
        # (e.g., an exception is thrown after execute_request returns)
        $response = undef;

        my $error = $@;
        my $action;
        if (ref $error) {
            # allow the exception to override some things
            $http_status = $error->{http_status} if $error->{http_status};
            $action      = $error->{http_action} if $error->{http_action};
            $response    = $error->{gofer_response} if $error->{gofer_response};
            $error       = $error->{error_text}  if $error->{error_text};
            $error       = $error->text if can($error, 'text');
        }

        chomp $error;
        $error .= sprintf " in %s request from %s, http status %d",
                $headers_in->{'Content-Type'}||$r->method, $remote_ip, $http_status;

        # record the error (via cleanup handler below) so we can see it later
        # remotely if track_recent is enabled.
        # if exception didn't include a response for logging then create one
        $response ||= $executor->new_response_with_err($DBI::stderr||1, $error);
        $r->pnotes(gofer_response => $response);
        $frozen_response = $transport->freeze_response($response);

        my $default_action = sub {   # default error response behaviour
            my ($r, $errstr, $http_status) = @_;
            warn "$errstr\n";
            $r->status($http_status);
            $r->content_type("text/plain");
            $r->custom_response($http_status, sprintf "%s. (%s %s, DBI %s, on %s pid $$)",
                $errstr, __PACKAGE__, $VERSION, $DBI::VERSION, hostname());
            return $http_status;
        };
        $action ||= $default_action;

        $http_status = $action->($r, $error, $http_status, $default_action);
    }

    my $update_stats_sub = sub {
        $executor->update_stats(
            $request,   # may not be defined if error thawing
            $response,  # always present
            # if we've used a non-default serializer (ie Data::Dumper)
            # then don't store the frozen items because we may not
            # be able to thaw it. (XXX needs better approach
            # such as also storing the serializer refs)
            ($request_serializer ) ? undef : $frozen_request,
            ($response_serializer) ? undef : $frozen_response,
            $time_received,
            { from => $remote_ip, },
            { r => $r, transport => $transport, },
        ) if $executor;

        return DECLINED;
    };

    # Defer stats until the cleanup phase
    # (push_handlers PerlCleanupHandler works but leaks under MP2)
    (MP2) ? $r->pool->cleanup_register( $update_stats_sub )
          : $r->push_handlers('PerlCleanupHandler', $update_stats_sub );

    return $http_status;
}


sub executor_for_apache_request {
    my ($self, $r) = @_;
    my $uri = $r->uri;

    return $executor_cache{ $uri } ||= do {

        my $r_dir_config = $r->dir_config;
        # get all configs for this location in sequence ('closest' last)
        my @location_configs = $r_dir_config->get('GoferConfig');

        my $merged_config = $self->_merge_named_configurations( "$uri $$", \@location_configs, 1 );
        my $gofer_execute_class = $merged_config->{gofer_execute_class} || 'DBI::Gofer::Execute';
        $gofer_execute_class->new($merged_config);
    }
}


sub _merge_named_configurations {
    my ($self, $tag, $location_configs_ref, $verbose) = @_;
    my @location_configs = @$location_configs_ref;

    push @location_configs, 'default' unless @location_configs;


    # merge all configs for this location in sequence, later override earlier
    my %merged_config;
    for my $config_name ( @location_configs ) {
        my $config = $executor_configs{$config_name};
        if (!$config) {
            # die if an unknown config is requested but not defined
            # (don't die for 'default' unless it was explicitly requested)
            die "$tag: GoferConfig '$config_name' not defined";
        }
        my $gofer_execute_class = $config->{gofer_execute_class} || 'DBI::Gofer::Execute';
        my $proto_config = $gofer_execute_class->valid_configuration_attributes();
        my @info;
        while ( my ($item_name, $proto_type) = each %$proto_config ) {
            next if not exists $config->{$item_name};
            my $item_value = $config->{$item_name};
            if (ref $proto_type eq 'HASH') {
                my $merged = $merged_config{$item_name} ||= {};
                push @info, "$item_name={ @{[ %$item_value ]} }" if $verbose && keys %$item_value;
                $merged->{$_} = $item_value->{$_} for keys %$item_value;
            }
            else {
                $merged_config{$item_name} = $item_value;
                if ($verbose && exists $config->{$item_name}) {
                    my $v = $item_value;
                    $v =~ s/\(0x\w+\)$// if ref $v;
                    push @info, "$item_name=$v";
                }
            }
        }
        warn "$tag: GoferConfig $config_name: @info\n" if @info;
    }
    return \%merged_config;
}


sub add_configurations {           # one-time setup from httpd.conf
    my ($self, $configs) = @_;
    while ( my ($config_name, $config) = each %$configs ) {
        my $gofer_execute_class = $config->{gofer_execute_class} || 'DBI::Gofer::Execute';
        my $proto_config = $gofer_execute_class->valid_configuration_attributes();
        my @bad = grep { not exists $proto_config->{$_} } keys %$config;
        die "Invalid keys in $self configuration '$config_name': @bad\n"
            if @bad;
        # XXX should check the types here?
    }
    # update executor_configs with new ones
    $executor_configs{$_} = $configs->{$_} for keys %$configs;
}


# --------------------------------------------------------------------------------

sub _install_apache_status_menu_items {
    my %apache_status_menu_items = @_;
    my $apache_status_class;
    if (MP2) {
        $apache_status_class = "Apache2::Status" if eval {
            require Apache2::Module;
            Apache2::Module::loaded('Apache2::Status');
        };
    }
    elsif ($INC{'Apache.pm'}                       # is Apache.pm loaded?
        and Apache->can('module')               # really?
        and Apache->module('Apache::Status')) { # Apache::Status too?
        $apache_status_class = "Apache::Status";
    }
    if ($apache_status_class) {
        while ( my ($url, $menu_item) = each %apache_status_menu_items ) {
            $apache_status_class->menu_item($url => @$menu_item);
        }
    }
}


sub _apache_status_dbi_gofer {
    my ($r, $q) = @_;
    my $url = $r->uri;
    my $args = $r->args;
    require Data::Dumper;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Useqq     = 1;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 0;
    local $Data::Dumper::Purity    = 0;

    my @s = ("<pre>",
        "<b>DBI::Gofer::Transport::mod_perl $VERSION</b> - <b>DBI $DBI::VERSION</b><p>",
    );
    my $time_now = dbi_time();

    my $path_info = $r->path_info;
    # workaround TransHandler being disabled
    $path_info = $url if not defined $path_info;
    # remove leading perl-status, if present (some versions do this, or else no path_info above)
    $path_info =~ s!^/perl-status!!;

    # hack to enable simple actions to be invoked via the status interface
    # format "...:foo" or "...:foo,opt1=bar,opt2=baz"
    my $action = ($path_info =~ s/:([\w,=]+)$//) ? $1 : '';

    if ($path_info) {

        my $executor = $executor_cache{$path_info}
            or return [ "No Gofer executor found for '$path_info'" ];

        ($action, my @actions) = split /,/, $action;
        my %action_opts = map { split /=/, $_, 2 } @actions;

        my $stats = $executor->{stats} ||= {};
        my $queue_name = "recent_". ($action_opts{recent}||'requests');
        my $queue = $stats->{$queue_name};
        return [ "No $queue_name found for '$path_info'" ]
            unless ref $queue eq 'ARRAY';

        if ($action) {
                # change to hash of code refs and add links to the actions into the output
            if ($action eq 'reset_stats') {
                $executor->{stats} = { _reset_stats_at => scalar localtime(time) };
                $stats = {};
            }
            elsif ($action eq 'recent_as_urls') {
                my $host = $r->get_server_name;
                my $port = $r->get_server_port;
                @s = ();
                for my $rr (@$queue) {
                    my $b64_request = encode_base64($rr->{request});
                    push @s, "http://$host:$port$path_info?req=$b64_request\n";
                }
                return \@s;
            }
            elsif ($action eq 'view') {
                # fall through
            }
            else {
                return [ "Unknown action '$action' ignored for $path_info" ];
            }
        }

        # don't Data::Dumper all the recent_requests & recent_errors
        local $stats->{recent_requests} = @{$stats->{recent_requests}||[]};
        local $stats->{recent_errors}   = @{$stats->{recent_errors}  ||[]};
        push @s, escape_html( Data::Dumper::Dumper($executor) );
        push @s, "<hr>";

        my ($idle_total, $dur_total, $time_received_prev, $duration_prev) = (0,0,0,0);
        my @redo_urls;
        my (%from, %dup_reqs);
        for my $rr (@$queue) {
            my $time_received = $rr->{time_received};
            my $duration = $rr->{duration};
            my $idle = ($time_received_prev) ? abs($time_received-$time_received_prev)-$duration_prev : 0;
            $rr->{_time_received} ||= localtime($time_received);
            my $from = $rr->{meta}{from};
            $from{ $from }{requests}++ if $from;

            # mark idle periods - handy when testing
            push @s, "<hr>" if $time_received_prev and $idle > 10;

            if (my $request = $rr->{request}) {
                my $b64_request = encode_base64($rr->{request});
                push @redo_urls, "$path_info?req=$b64_request";
                push @s, sprintf qq{\tredo: <a href="%s?req=%s">raw</a>, <a href="%s?_dd=1&req=%s">dump</a>},
                    $path_info, $b64_request,
                    $path_info, $b64_request;

                my $is_dupreq = $dup_reqs{ $rr->{request} }++;

                my $request_html = eval {
                    my $request  = $rr->{request_object}
                        || $transport->thaw_request($rr->{request});
                    escape_html( $request->summary_as_text({
                        at => $rr->{_time_received},
                        age => int($time_now-$time_received),
                        idle => $idle,
                        size => length($rr->{request}),
                        ($from) ? (from => $from) : (),
                        ($is_dupreq) ? (is_dup => $is_dupreq) : (),
                    }) );
                } || escape_html("ERROR THAWING REQUEST: $@");

                # bold the word _dup if it's a dup
                $request_html =~ s{\b is_dup \b}{<b>is_dup</b>}x if $is_dupreq;
                push @s, $request_html;
            }
            else {
                push @s, "<i>(no request data)</i>\n";
            }

            my $response_html = eval {
                my $response = $rr->{response_object}
                    || $transport->thaw_response($rr->{response});
                $from{ $from }{errors}++ if $from && $response->err;
                escape_html( $response->summary_as_text({
                    duration => $duration,
                    ($rr->{response}) ? (size => length $rr->{response}) : (),
                }) );
            } || escape_html("ERROR THAWING RESPONSE: $@");
            push @s, $response_html;

            push @s, "\n";

            $idle_total += $idle;
            $dur_total  += $duration;
            ($time_received_prev, $duration_prev) = ($time_received, $duration);
        }
        push @s, "<hr>\n";
        if (@$queue) {
            my $time_span = $dur_total+$idle_total;
            push @s, sprintf "Summary for the %d requests shown above (covering %d seconds for pid $$)...\n",
                scalar @$queue, $time_span;

            my @rr_requ_size = map { length($_->{request}||'') }  @$queue;
            push @s, sprintf "Request  size: min %4d, avg %4d, max %4d (sum %d \@ %dB/sec)\n",
                min(@rr_requ_size), sum(@rr_requ_size)/@rr_requ_size, max(@rr_requ_size),
                sum(@rr_requ_size), sum(@rr_requ_size)/$time_span;

            my @rr_resp_size = map { length($_->{response}||'') } @$queue;
            push @s, sprintf "Response size: min %4d, avg %4d, max %4d (sum %d \@ %dB/sec)\n",
                min(@rr_resp_size), sum(@rr_resp_size)/@rr_resp_size, max(@rr_resp_size),
                sum(@rr_resp_size), sum(@rr_resp_size)/$time_span;

            my @rr_resp_dur = map { $_->{duration} } @$queue;
            push @s, sprintf "Response time: min %.3fs, avg %.3fs, max %.3fs\n",
                min(@rr_resp_dur), sum(@rr_resp_dur)/@rr_resp_dur, max(@rr_resp_dur), sum(@rr_resp_dur);

            push @s, sprintf "Request rate: %.1f/min (occupancy: %.1f%% with %.3fs busy and %.3fs idle)\n",
                    @$queue/($time_span/60),
                    $dur_total/($dur_total+$idle_total)*100, $dur_total, $idle_total
                if $queue_name eq 'recent_requests';

            if ( my @dups = grep { $_ > 1 } values %dup_reqs ) {
                push @s, sprintf "Duplicate requests: %d distinct duplicates, total %d duplicates\n",
                    scalar @dups, sum(@dups);
            }

            if ($show_client_hostname_in_status) { # use DNS lookup
                eval {
                    local $SIG{ALRM} = "TIMEOUT DNS ".__PACKAGE__;
                    alarm(5);
                    for my $from (keys %from) {
                        next unless $from =~ /^\d+\./;
                        my $new = sprintf "%s %s",
                            gethostbyaddr(inet_aton($from),AF_INET) || "?",
                            $from;
                        $from{ $new } = delete $from{ $from };
                    }
                    alarm(0);
                };
                alarm(0);
                warn $@ if $@;
            }
            push @s, sprintf "Recent request distribution from %d sources:\n", scalar keys(%from)
                if keys(%from);
            push @s, sprintf "%-20s: %3d, errors %d\n",
                    $_, $from{$_}{requests}, $from{$_}{errors}||0
                for sort keys %from;
        }
        return \@s;
    }

    push @s, "No Gofer executors cached" unless %executor_cache;
    for my $path (sort keys %executor_cache) {
        my $executor = $executor_cache{$path};
        (my $tag = $path) =~ s/\W/_/g;
        push @s, sprintf qq{<a href="#%s"><b>%s</b></a>\n}, $tag, $path;
    }
    push @s, "<hr>\n";
    $url =~ s/\Q$path_info$//; # remove path_info from $url
    for my $path (sort keys %executor_cache) {
        my $executor = $executor_cache{$path};
        (my $tag = $path) =~ s/\W/_/g;
        my $stats = $executor->{stats};
        local $stats->{recent_requests} = @{$stats->{recent_requests}||[]};
        push @s, sprintf qq{<a name="%s" href="%s"><b>%s</b></a> = }, $tag, "$url$path?$args", $path;
        push @s, escape_html( Data::Dumper::Dumper($executor) );
    }
    return \@s;
}

1;

__END__

=head1 NAME
    
DBI::Gofer::Transport::mod_perl - http mod_perl server-side transport for DBD::Gofer

=head1 SYNOPSIS

In httpd.conf:

    <Location /gofer>
        SetHandler perl-script 
        PerlHandler DBI::Gofer::Transport::mod_perl
    </Location>

For a corresponding client-side transport see L<DBD::Gofer::Transport::http>.

=head1 DESCRIPTION

This module implements a DBD::Gofer server-side http transport for mod_perl.
After configuring this into your httpd.conf, users will be able to use the DBI
to connect to databases via your apache httpd.

=head1 CONFIGURATION

=head2 Gofer Configuration

Rather than provide a DBI proxy that will connect to any database as any user,
you may well want to restrict access to just one or a few databases.

Or perhaps you want the database passwords to be stored only in httpd.conf so
you don't have to maintain them in all your clients. In this case you'd
probably want to use standard https security and authentication.

These kinds of configurations are supported by DBI::Gofer::Transport::mod_perl.

The most simple configuration looks like:

    <Location /gofer>
        SetHandler perl-script
        PerlHandler DBI::Gofer::Transport::mod_perl
    </Location>

That's equivalent to:

    <Perl>
        DBI::Gofer::Transport::mod_perl->add_configurations({
            default => {
                # ...DBI::Gofer::Transport::mod_perl configuration here...
            },
        });
    </Perl>

    <Location /gofer/example>
        SetHandler perl-script
        PerlSetVar GoferConfig default
        PerlHandler DBI::Gofer::Transport::mod_perl
    </Location>

Refer to L<DBI::Gofer::Transport::mod_perl> documentation for details of the
available configuration items, their behaviour, and their default values.

The DBI::Gofer::Transport::mod_perl->add_configurations({...}) call defines named configurations.
The C<PerlSetVar GoferConfig> clause specifies the configuration to be used for that location.

A single location can specify multiple configurations using C<PerlAddVar>:

        PerlSetVar GoferConfig default
        PerlAddVar GoferConfig example_foo
        PerlAddVar GoferConfig example_bar

in which case the added configurations are merged into the current
configuration for that location.  Conflicting entries in later configurations
override those in earlier ones (for hash references the contents of the hashes
are merged). In this way a small number of configurations can be mix-n-matched
to create specific configurations for specific location urls.

A typical usage might be to define named configurations for each specific
database being used and then define a coresponding location for each of those.
That would also allow standard http location access controls to be used
(though at the moment the http transport doesn't support http authentication).

That approach can also provide a level of indirection by avoiding the need for
the clients to know and use the actual DSN. The clients can just connect to the
specific gofer url with an empty DSN. This means you can change the DSN being used
without having to update the clients.

=head2 Apache Configuration

=head3 KeepAlive

The gofer http transport will use HTTP/1.1 persistent connections if possible.
You may want to tune the server-side settings KeepAlive, keepAliveTimeout, and
MaxKeepAliveRequests.

=head1 Apache::Status

DBI::Gofer::Transport::mod_perl installs an extra "DBI Gofer" menu item into
the Apache::Status menu, so long as the Apache::Status module is loaded first.

This is very useful.

Clicking on the DBI Gofer menu items leads to a page showing the configuration
and statistics for the Gofer executor object associated with each C<Location>
using the DBI::Gofer::Transport::mod_perl handler in the httpd.conf file.

Gofer executor objects are created and cached on first use so when the httpd is
(re)started there won't be any details to show.

Each Gofer executor object shown includes a link that will display more detail
of that particular Gofer executor. Currently the only extra detail shown is a
listing showing recent requests and responses followed by a summary. There's a
lot of useful information here. The number of recent recent requests and
responses shown is controlled by the C<track_recent> configuration value.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-dbi-gofer-transport-mod_perl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 METHODS

=head2 add_configurations

  DBI::Gofer::Transport::mod_perl->add_configurations( \%hash_of_hashes );

Takes a reference to a hash containing gofer configuration names and their
corresponding configuration details.

These are added to a cache of gofer configurations. Any existing
configurations with the same names are replaced.

A warning will be generated for each configuration that contains any invalid keys.

=head2 executor_for_apache_request

  $executor = $self->executor_for_apache_request( $r );

Takes an Apache request object and returns a DBI::Gofer::Execute object with
the appropriate configuration for the url of the request.

The executors are cached so a new DBI::Gofer::Execute object will be created
only for the first gofer request at a specific url. Subsequent requests get the
cached executor.

=head2 handler

This is the method invoked by Apache mod_perl to handle the request.

=head1 TO DO

Add way to reset the stats via the Apache::Status ui.

Move generic executor config code into DBI::Gofer::Executor::Config or somesuch so other transports can use it.

=head1 AUTHOR

Tim Bunce, L<http://www.linkedin.com/in/timbunce>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Tim Bunce, Ireland. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<DBD::Gofer> and L<DBD::Gofer::Transport::http>.

=cut

# vim: ts=8:sw=4:et
