#!/usr/bin/env perl

# Creation date: 2007-04-04 21:57:58
# Authors: don

use strict;
use Test;

# main
{
    BEGIN { plan tests => 4 };

    use JSON::DWIW;
    my $converter = JSON::DWIW->new({ use_exceptions => 1 });

    local $SIG{__DIE__};

    my $bad_str = '{"stuff":}';
    eval { my $data = $converter->from_json($bad_str); };

    ok($@);

    eval { my $data = JSON::DWIW->from_json($bad_str, { use_exceptions => 1 }); };

    ok($@);

    eval { my $data = JSON::DWIW::from_json($bad_str, { use_exceptions => 1 }); };

    ok($@);

    my $bad_data = { stuff => "\xf5blah" };
#     {
#         local $SIG{__WARN__} = sub {
#             my $msg = shift;
#             if ($msg =~ /malformed\s+utf-8/i) {
#                 # don't print the message
#                 return;
#             }
#             else {
#                 warn $msg;
#                 return;
#             }
#         };
        eval { my $str = $converter->to_json($bad_data); };
#     }

    ok($@);
    

}

exit 0;

###############################################################################
# Subroutines

