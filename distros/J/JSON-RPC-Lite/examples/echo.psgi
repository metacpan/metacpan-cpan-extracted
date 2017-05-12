use strict;
use FindBin;
use lib qq{$FindBin::Bin/../lib};
use JSON::RPC::Lite;

method 'echo' => sub { $_[0] };

as_psgi_app;
