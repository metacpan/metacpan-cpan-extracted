package Discord::Client::REST::Error;

use v5.26;
use strict;
use warnings;
use parent 'Discord::Client::Error';

our $VERSION = '0.001';

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::REST::Error - REST failure details

=head1 DESCRIPTION

REST failures use this subclass of L<Discord::Client::Error> as the third value
in a Future failure tuple:

    my ($message, $category, $error) = $request->failure;

Inherits C<new>, C<message>, C<category>, C<status>, C<discord_code>, C<request_id>,
C<details>, C<close_code> and C<event>. SDK errors redact known credentials and
sensitive fields in validation details. Request IDs come from C<X-Request-ID>
or C<CF-Ray>. See L<Discord::Client::REST/ERRORS AND CANCELLATION> for categories.

=head1 LICENSE

Apache License 2.0.

=cut
