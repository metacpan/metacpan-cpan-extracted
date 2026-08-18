=head1 NAME

34_json_response_no_request.t - HAC-039: json_response()'s POD documents
"a missing response... comes back as { status => 'error', error => $message }
instead" of dying, but no test exercised calling it before any request had
been made. kvp_response() already had this exact scenario covered (HAC-007);
json_response() did not.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

my $result = eval { $api->json_response };

ok !$@, "json_response() with no prior request does not die (error: " . ($@ // '') . ")";
is $result->{status}, "error", "it returns the documented error status instead";
ok defined $result->{error}, "an error message is included";

done_testing;
