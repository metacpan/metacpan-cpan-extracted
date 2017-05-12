# -*- perl -*-
# Copyright (c) 2000, FundsXpress Financial Network, Inc.
# This library is free software released "AS IS WITH ALL FAULTS"
# and WITHOUT ANY WARRANTIES under the terms of the GNU Lesser
# General Public License, Version 2.1, a copy of which can be
# found in the "COPYING" file of this distribution.

# $Id: procmanager.t,v 1.9 2001/04/23 16:13:45 muaddie Exp $

use strict;
use Test qw(ok plan);

BEGIN { plan tests => 2; }

use GPLVote::SignDoc::Client;

my $pub_key = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzuC/yVPE4HSOU/mr2jBkQt5qZ56m4X8VByu1nrToaYGlKc7gv/ikKdsRc5/pj1JZ4Xb0Nw5DunNQ+ycV/ai21ib35H5qAGHcElLkt6bpKuhPxa6/ZHf+I4Su+0pHx1Dy3XfaxbXDK8OYQTXk+Na7Eagpf/u57YvERvSqCoorH+slhi9yNYuqSAcmBA7snkdOfg2hDLx58qAIapnCeyE/RJrI5V0fP1DUp3pUEa0RBaQYtmYCoPOA9Og1IwkKsb42mTMAozFjs7P+Lzorb5FYauca/33/8LqmCkb4LHTulzgUTBYYTx+GZ6RQrw0g652ZJMgMbNr2rrD6qPozZnHdZwIDAQAB';

my $doc_data = "test.site.com:3:[\"value   1\",\"value2\",\"value 3\"]:LIST\nЗначение 1\nЗначение 2\nЗначение 3";

my $doc_sign = 'mX/qkJkwshqkUZn3lD8qT9ivLXmRH/TECowDU+REbnNvR3CqW/ZCotluvvpBgxwzX73ZG4YQ9EU7UZPNc8MzhGtPBob9wY5AelGJYb4iRCTHLnEcOezPBico0dxAp8l+r0zzUOfFoicdj4Fe5gVBMKQ21M8JRA4MYN6ExZA0dbTLo5x5zDAi7KJlAwsGgliZtbs+yzmH8GjhX5valvpskYJSHZqT13akau62tZiOTT2ggqfn5n12HzMW2qY0N8GHXZa7kwnm9ncSx5dGEv0K09XbjxVg2i2CiMojuinK2sY3hagVDQJmZkYdvUVNkwIWtdTbgC3g51axm/9l9fUqAg==';

ok(user_sign_is_valid($pub_key, $doc_sign, $doc_data));

ok(encrypt($pub_key, 'small data'));

#ok(encrypt($pub_key, 'big data '.('X' x 65535)));


exit 0;
