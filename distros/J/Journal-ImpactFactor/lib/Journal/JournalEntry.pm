package Journal::JournalEntry;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'name' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has  'issn' => (
    is  => 'rw',
    isa =>  'Str',
    );

has 'year_2008' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'year_2009' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'year_2010' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'year_2011' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'year_2012' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'year_2013_2014' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
