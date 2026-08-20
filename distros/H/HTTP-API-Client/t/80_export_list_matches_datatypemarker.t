=head1 NAME

80_export_list_matches_datatypemarker.t - HAC-104: Client.pm hand-copied
DataTypeMarker.pm's @EXPORT list instead of deriving it, even though
DataTypeMarker.pm's own SYNOPSIS promises "use HTTP::API::Client; #
re-exports everything below". Nothing enforced that promise - a future
marker added to DataTypeMarker's @EXPORT without also updating Client.pm's
separate copy would work via 'use HTTP::API::DataTypeMarker' directly but
silently NOT be available via 'use HTTP::API::Client', with no error or
warning anywhere. Client.pm now derives its @EXPORT from
DataTypeMarker's own list instead of hand-copying it, so the two can never
drift apart again.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

is_deeply [ sort @HTTP::API::Client::EXPORT ],
    [ sort @HTTP::API::DataTypeMarker::EXPORT ],
    "Client.pm's \@EXPORT always matches DataTypeMarker.pm's, keeping the re-export promise honest";

done_testing;
