package EveOnline::EveID;

use strict;
use warnings;
use v5.12;
use Moose::Role;
use namespace::autoclean;

has 'characterID'   =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

1;
