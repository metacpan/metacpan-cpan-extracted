package EveOnline::Character;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'EveOnline::EveCache', 'EveOnline::EveID';

has 'name'  =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'corporationID' =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'corporationName'   =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'allianceID'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'allianceName'    =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'factionID'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'factionName'    =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

1;

