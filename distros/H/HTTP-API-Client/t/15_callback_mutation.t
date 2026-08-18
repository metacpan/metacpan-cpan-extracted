=head1 NAME

15_callback_mutation.t - regression test for HAC-016: a callback that adds
a new key to the data hash during its own execution must not trigger
Perl's "each() after insertion" undefined-behavior warning

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $api = HTTP::API::Client->new( content_type => "application/json" );

my $req = $api->post( "http://example.com", {
    a => sub {
        my ( $self, %o ) = @_;
        $o{data}{new_key} = "added-during-callback";
        return "a-value";
    },
    b => "plain",
}, {}, { test_request_object => 1 } );

ok !( grep { /each\(\)/ } @warnings ), "no each() undefined-behavior warning when a callback mutates the data hash"
    or diag "warnings: @warnings";

done_testing;
