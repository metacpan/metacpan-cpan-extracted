use strict;
use warnings;
package Mail::SendGrid;
$Mail::SendGrid::VERSION = '0.09';
# ABSTRACT: interface to SendGrid.com mail gateway APIs

use 5.008;
use Moo 1.006;
use HTTP::Tiny 0.013;
use JSON 2.53;
use URI::Escape 3.30;
use Carp 1.20;

use Mail::SendGrid::Bounce;

has 'api_user'  => (is => 'ro', required => 1);
has 'api_key'   => (is => 'ro', required => 1);
has 'ua'        => (is => 'ro', default => sub { HTTP::Tiny->new(); });

my %valid_params =
(

    'bounces.get' =>
    {
        days       => '\d+',
        start_date => '\d\d\d\d-\d\d-\d\d',
        end_date   => '\d\d\d\d-\d\d-\d\d',
        limit      => '\d+',
        offset     => '\d+',
        type       => 'hard|soft',
        email      => '\S+@\S+',
    },

    'bounces.delete' =>
    {
        start_date => '\d\d\d\d-\d\d-\d\d',
        end_date   => '\d\d\d\d-\d\d-\d\d',
        type       => 'hard|soft',
        email      => '\S+@\S+',
    },

);

sub bounces
{
    my $self     = shift;
    my %opts     = @_;
    my $response;
    my $url;
    my $bounce_list;
    my (@bounces, $bounce);

    $response = $self->_make_request('bounces.get', \%opts, { date => 1 });

    if ($response->{success}) {
        $bounce_list = decode_json($response->{content});
        foreach my $bounce_details (@{ $bounce_list }) {
            $bounce = Mail::SendGrid::Bounce->new($bounce_details);
            push(@bounces, $bounce) if defined($bounce);
        }
    }

    return @bounces;
}

sub delete_bounces
{
    my $self = shift;
    my %opts     = @_;
    my $base_uri = 'https://sendgrid.com/api/bounces.delete.json';
    my $response;
    my $json;
    my $url;

    $response = $self->_make_request('bounces.delete', \%opts, {});

    if ($response->{success}) {
        $json = decode_json($response->{content});
        if ($json->{message} eq 'success') {
            return 1;
        } elsif (exists($json->{message})) {
            carp "bounces.delete failed - error message: $json->{message}\n";
        } else {
            carp "unexpected response from SendGrid: $response->{content}\n";
        }
    }

    return 0;
}

#
# _make_request
#
# Helper function to build the URL and then make the request to SendGrid
# $action is the part of the endpoint that identifies the action
#   eg for getting bounces, the base URL is https://sendgrid.com/api/bounces.get.json
#   and $action will be 'bounces.get'
# $optref is a hash reference that contains any options passed by the caller of the
#   public function
# $defaults is a hashref containing any defaults that we want to mix in,
#   regardless of what the user passed to the public function
#
sub _make_request
{
    my $self     = shift;
    my $action   = shift;
    my $optref   = shift;
    my $defaults = shift;
    my %params   = (
                    api_user => $self->api_user,
                    api_key  => $self->api_key,
                    %$defaults,
                   );
    my $url      = 'https://sendgrid.com/api/'.$action.'.json';
    my $response;

    foreach my $opt (keys %$optref) {
        if (not exists($valid_params{$action}->{$opt})) {
            carp "Mail::SendGrid unknown parameter '$opt' for $action";
            return 0;
        }
        if ((not defined($optref->{$opt})) || ($optref->{$opt} !~ /^($valid_params{$action}->{$opt})$/)) {
            carp "Mail::SendGrid invalid value '$optref->{$opt}' for parameter '$opt' to $action";
            return 0;
        }
        $params{$opt} = $optref->{$opt};
    }

    $url .= '?'.join('&', map { $_.'='.uri_escape($params{$_}) } keys %params);

    $response = $self->ua->get($url);
    if (not $response->{success}) {
        carp __PACKAGE__, " : $action HTTP request failed\n",
             " status code = $response->{status}\n",
             " reason      = $response->{reason}\n";
    }

    return $response;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::SendGrid - interface to SendGrid.com mail gateway APIs

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use Mail::SendGrid;
 
 $sendgrid = Mail::SendGrid->new('api_user' => '...', 'api_key' => '...');
 print "Email to the following addresses bounced:\n";
 foreach my $bounce ($sendgrid->bounces) {
     print "\t", $bounce->email, "\n";
 }
 
 $sendgrid->delete_bounces(email => 'neilb@cpan.org');

=head1 DESCRIPTION

This module provides easy access to the APIs provided by sendgrid.com, a service for sending emails.
At the moment the module just provides the C<bounces()> and C<delete_bounces()> methods.
Over time I'll add more of the SendGrid API.

=head1 METHODS

=head2 new

Takes two parameters, api_user and api_key, which were specified when you registered your account
with SendGrid. These are required.

=head2 bounces ( %params )

This requests bounces from SendGrid,
and returns a list of Mail::SendGrid::Bounce objects.
By default it will pull back all bounces, but you can use the following
parameters to constrain which bounces are returned:

=over 4

=item days => N

Number of days in the past for which to return bounces.
Today counts as the first day.

=item start_date => 'YYYY-MM-DD'

The start of the date range for which to retrieve bounces.
The date must be in ISO 8601 date format.

=item end_date => 'YYYY-MM-DD'

The end of the date range for which to retrieve bounces.
The date must be in ISO 8601 date format.

=item limit => N

The maximum number of bounces that should be returned.

=item offset => N

An offset into the list of bounces.

=item type => 'hard' | 'soft'

Limit the returns to either hard or soft bounces. A soft bounce is one which would have
a 4xx SMTP status code, a persistent transient failure. A hard bounce is one which would
have a 5xx SMTP status code, or a permanent failure.

=item email => 'email-address'

Only return bounces for the specified email address.

=back

For example, to get a list of all soft bounces over the last week, you would use:

  @bounces = $sendgrid->bounces(type => 'soft', days => 7);

=head2 delete_bounces( %options )

This is used to delete one or more bounces, or even all bounces;
the following options constrain which bounces are deleted.
For a description of the options, see L<"bounces">.

=over 4

=item *

start_date

=item *

end_date

=item *

type

=item *

email

=back

To delete all bounces, call this without any options:

  $sendgrid->delete_bounces();

=head1 SEE ALSO

=over 4

=item L<Mail::SendGrid::Bounce>

The class which defines the data objects returned by the bounces method.

=item SendGrid API documentation

L<http://sendgrid.com/docs/API%20Reference/Web%20API/bounces.html>

=back

=head1 REPOSITORY

L<https://github.com/neilb/Mail-SendGrid>

=head1 AUTHOR

Neil Bowers <neilb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
