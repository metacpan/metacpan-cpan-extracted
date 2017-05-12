package EveOnline::SkillQueue;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'characterID'   =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'queuePosition' =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'typeID'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'level' =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'startSP'   =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'endSP' =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'startTime' =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'endTime' =>  (
    is  =>  'rw',
    isa =>  'Str',
    );


1;


 

