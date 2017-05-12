package HTTP::WebTest::Plugin::FileRequest;
use strict;
use URI::file;

# Utility package to allow opening a file from the local file system

use base qw(HTTP::WebTest::Plugin);

sub prepare_request {
    my $self = shift;
    my $url = $self->test_param('url');
    my $path = URI::file->new_abs($url);

    # get user agent object
    my $user_agent = $self->webtest->user_agent;

    # get request object
    my $request = $self->webtest->current_request;
    $request->uri($path);
    $request->method('GET');
}

1;

