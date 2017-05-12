package EveOnline::Contact;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'EveOnline::EveCache', 'EveOnline::EveID';

has 'contactID' =>  (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'contactName'   =>  (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'inWatchlist'   =>  (
    is  =>  'rw',
    isa =>  'Bool',
    );

has 'standing'  =>  (
    is  =>  'rw',
    isa =>  'Int'
    );

1;
