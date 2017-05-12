package EveOnline::AccountStatus;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'EveOnline::EveCache';

has 'paidUntil' =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'createDate'    =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'logonCount'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'logonMinutes'  =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'currentTime'   =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
