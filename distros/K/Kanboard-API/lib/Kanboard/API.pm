package Kanboard::API;    ## no critic

use v5.40;
use strict;
use warnings;
use Moo;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64;
use JSON;

=head1 NAME

Kanboard::API - A Perl interface to the Kanboard API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Kanboard::API is a Perl interface to the Kanboard API. It provides a simple way to interact with a Kanboard instance.

    use Kanboard::API;

    my $kanboard = Kanboard::API->new(username => 'yourusername|jsonrpc', password => 'apikey', endpoint => 'https://yourkanboardinstance.com');
    ...

=head1 ATTRIBUTES

=head2 username

The username to use for authentication. Defaults to "jsonrpc".

=cut

has username => ( is => 'ro', default => 'jsonrpc' );

=head2 password

The password to use for authentication.

=cut

has password => ( is => 'ro', required => 1 );

=head2 endpoint

The JSON RPC Endpoint of the Kanboard instance.

=cut

has endpoint => ( is => 'ro', required => 1 );

=head2 ua

The LWP::UserAgent object used to make requests.

=cut

has 'ua' => (
    is      => 'lazy',
    builder => sub { LWP::UserAgent->new },
);

=head1 PRIVATE METHODS

=head2 _request

=cut

sub _request( $self, $method, $params = [] ) {
    my $auth    = encode_base64( "$self->{username}:$self->{password}", "" );
    my $headers = [
        'Content-Type'  => 'application/json',
        'Authorization' => "Basic $auth",
    ];
    my $request_json = {
        jsonrpc => "2.0",
        id      => 1,
        method  => $method,
        params  => $params // [],
    };
    my $body = encode_json($request_json);
    my $request =
      HTTP::Request->new( 'POST', $self->endpoint, $headers, $body );

    my $response = $self->ua->request($request);

    if ( $response->is_success ) {
        my $content      = $response->decoded_content;
        my $content_json = decode_json($content);
        if ( $content_json->{error} ) {
            die
              "$content_json->{error}{message} - $content_json->{error}{data}";
        }
        return $content_json->{result};
    }
    else {
        die $response->status_line;
    }
}

=head1 PUBLIC METHODS

=head2 get_version


Purpose: Get the application version
Parameters: none
Result: version (Example: 1.0.12, master)


=cut

sub get_version( $self) {
    return $self->_request('getVersion');
}

=head2 get_me


Purpose: Get the current user profile
Parameters:
    None
Result on success: user properties
Result on failure: empty list


=cut

sub get_me( $self) {
    return $self->_request('getMe');
}

=head2 create_project


Purpose: Create a new project
Parameters:
    name (string, required)
    description (string, optional)
    owner_id (integer, optional)
    identifier (string, optional)
Result on success: project ID
Result on failure: false


=cut

sub create_project( $self, $params) {
    return $self->_request('createProject', $params);
}

=head2 remove_project


Purpose: Remove a project
Parameters:
    project_id (integer, required)
Result on success: true
Result on failure: false


=cut

sub remove_project( $self, $params) {
    return $self->_request('removeProject', $params);
}

=head2 get_project


Purpose: Get project details
Parameters:
    project_id (integer, required)
Result on success: project properties
Result on failure: empty list


=cut

sub get_project( $self, $params) {
    return $self->_request('getProject', $params);
}

=head2 create_task


Purpose: Create a new task
Parameters:
    title (string, required)
    project_id (integer, required)
    description (string, optional)
    category_id (integer, optional)
    owner_id (integer, optional)
    color_id (string, optional)
    column_id (integer, optional)
    swimlane_id (integer, optional)
    priority (integer, optional)
    date_due (timestamp, optional)
Result on success: task ID
Result on failure: false


=cut

sub create_task( $self, $params) {
    return $self->_request('createTask', $params);
}

=head2 remove_task


Purpose: Remove a task
Parameters:
    task_id (integer, required)
Result on success: true
Result on failure: false


=cut

sub remove_task( $self, $params) {
    return $self->_request('removeTask', $params);
}

=head2 get_task


Purpose: Get task details
Parameters:
    task_id (integer, required)
Result on success: task properties
Result on failure: empty list


=cut

sub get_task( $self, $params) {
    return $self->_request('getTask', $params);
}

=head2 get_all_tasks


Purpose: Get all tasks for a project
Parameters:
    project_id (integer, required)
Result on success: list of tasks
Result on failure: empty list


=cut

sub get_all_tasks( $self, $params) {
    return $self->_request('getAllTasks', $params);
}

=head2 get_board


Purpose: Get all necessary information to display a board
Parameters:
    project_id (integer, required)
Result on success: board properties
Result on failure: empty list


=cut

sub get_board( $self, $params) {
    return $self->_request('getBoard', $params);
}


=head1 AUTHOR

Dan Barbarito, C<< <dan at barbarito.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-kanboard-api at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kanboard-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Kanboard::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Kanboard-API>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Kanboard-API>

=item * Search CPAN

L<https://metacpan.org/release/Kanboard-API>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Dan Barbarito.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

  1;    # End of Kanboard::API
