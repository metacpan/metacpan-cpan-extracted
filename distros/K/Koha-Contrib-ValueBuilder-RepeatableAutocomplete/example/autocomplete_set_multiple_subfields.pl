#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use utf8;

use Koha::Contrib::ValueBuilder::RepeatableAutocomplete;

return Koha::Contrib::ValueBuilder::RepeatableAutocomplete->build_builder_inline_multiple(
    {   target_map => [
            { subfield => 'b', type => 'selected', key   => 'value' },
            { subfield => '2', type => 'literal',  literal => 'rdacontent' }
        ],
        data => [
            { label => 'aufgeführte Musik', value => 'prm' },
            { label => 'Bewegungsnotation', value => 'ntv' },
        ]
    }
);

