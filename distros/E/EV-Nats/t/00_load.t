use strict;
use warnings;
use Test::More tests => 2;

use_ok 'EV';
use_ok 'EV::Nats';

diag "EV::Nats $EV::Nats::VERSION, EV $EV::VERSION, Perl $]";
