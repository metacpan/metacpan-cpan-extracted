package TestServer::Misc;
use base qw( TestServer::Plugin );
use strict;
use warnings;
use 5.010;

use JSON::PP;
use Data::Dumper::Concise;

sub import {
    my $class = __PACKAGE__;
    $class->register_dispatch(
        '/test'                        => sub { $class->test(@_) },
        '/rest/api/latest/test'        => sub { $class->test(@_) },
        'POST /rest/api/latest/test'   => sub { $class->test(@_) },
        'PUT /rest/api/latest/test'    => sub { $class->test(@_) },
        'DELETE /rest/api/latest/test' => sub { $class->test(@_) },

        'POST /rest/api/latest/data_upload' => sub { $class->upload(@_) },

        '/rest/api/latest/configuration' =>
            sub { $class->configuration_response(@_) },
    );
}

sub test {
    my ( $class, $server, $cgi ) = @_;
    my $method = $cgi->request_method;
    my $path   = $cgi->path_info;
    $class->response($server, { $method => 'SUCCESS' });
    say "# successful $method $path request";
}

sub upload {
    my ( $class, $server, $cgi ) = @_;
    my $method = $cgi->request_method;
    my $file = $cgi->param( 'file' );
    my $retval = $cgi->uploadInfo( $file );
    $retval->{name} = "$file";
    while (my $line = <$file>) {
        $retval->{data} .= $line;
    }
    $retval->{$method} = 'SUCCESS';
    $class->response($server, $retval);
}

sub configuration_response {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    $class->response($server, $class->configuration_data($server, $cgi));
}

sub configuration_data {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    return {
      attachmentsEnabled => JSON::PP::true,
      issueLinkingEnabled => JSON::PP::true,
      subTasksEnabled => JSON::PP::true,
      timeTrackingConfiguration => {
        defaultUnit => "minute",
        timeFormat => "pretty",
        workingDaysPerWeek => 5,
        workingHoursPerDay => 8
      },
      timeTrackingEnabled => JSON::PP::true,
      unassignedIssuesAllowed => JSON::PP::true,
      votingEnabled => JSON::PP::true,
      watchingEnabled => JSON::PP::true
    };
}

1;
