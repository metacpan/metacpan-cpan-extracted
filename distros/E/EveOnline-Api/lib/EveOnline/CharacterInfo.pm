package EveOnline::CharacterInfo;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'EveOnline::EveCache', 'EveOnline::EveID';

has 'characterName' =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'race'  =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'bloodline' =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'accountBalance'    =>  (
    is  =>  'rw',
    isa =>  'Num',
    );

has 'skillPoints'   =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'shipName'  =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'shipTypeID'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'shipTypeName'  =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'corporationID' =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'corporation'   =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'corporationDate'   =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'allianceID'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'alliance'  =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'allianceDate'  =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'lastKnownLocation' =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'securityStatus'    =>  (
    is  =>  'rw',
    isa =>  'Num',
    );

1;
