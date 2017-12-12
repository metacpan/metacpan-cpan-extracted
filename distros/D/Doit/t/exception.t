#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More 'no_plan';

use Doit;
use Doit::Exception 'throw'; # only needed for the import

######################################################################

eval {
    die Doit::Exception->new;
};
like $@, qr{^Died at .* line \d+\.\n\z}, 'default exception message';

eval {
    throw;
};
like $@, qr{^Died at .* line \d+\.\n\z}, 'default exception message, using throw';

######################################################################

eval {
    die Doit::Exception->new("only a message");
};
like $@, qr{^only a message at .* line \d+\.\n\z}, 'message with error location';

eval {
    throw "only a message";
};
like $@, qr{^only a message at .* line \d+\.\n\z}, 'message with error location, using throw';

######################################################################

eval {
    die Doit::Exception->new("message without caller\n");
};
like $@, qr{^message without caller\n\z}, 'message without caller';

eval {
    throw "message without caller\n";
};
like $@, qr{^message without caller\n\z}, 'message without caller, using throw';

######################################################################

eval {
    die Doit::Exception->new("message and data", foo => 'bar');
};
like $@, qr{^message and data at .* line \d+\.\n\z}, 'message and data';
is $@->{foo}, 'bar';

eval {
    throw "message and data", foo => 'bar';
};
like $@, qr{^message and data at .* line \d+\.\n\z}, 'message and data, using throw';
is $@->{foo}, 'bar';

__END__
