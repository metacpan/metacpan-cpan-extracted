package EveOnline::EveCache;

use strict;
use warnings;
use v5.12;
use Moose::Role;
use namespace::autoclean;

has 'currentTime'   =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'cachedUntil'   =>  (
    is  =>  'rw',
    isa =>  'Str',
    );


1;
