#!/usr/bin/perl
# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/
use strict; use warnings;

# DEBUG on
use FindBin qw( $Bin );
use lib $Bin .'/../lib/';
# DEBUG off

use Devel::CoverReport::DB;

use Test::More;

plan tests => 4;

my $db = Devel::CoverReport::DB->new(cover_db  => $Bin . q{/Samples/Simple/cover_db-20090919});

is_deeply(
    [ sort $db->runs() ],
    [ sort qw( 1253384580.6371.30504 1253384583.6372.60096 1253384586.6373.10649 1253384589.6374.07833 1253384591.6375.39890 )],
    'runs()'
);
is_deeply(
    [ sort $db->runs() ],
    [ sort qw( 1253384580.6371.30504 1253384583.6372.60096 1253384586.6373.10649 1253384589.6374.07833 1253384591.6375.39890 )],
    'runs() cached?'
);

is_deeply(
    [ sort $db->digests() ],
    [ sort qw( 0fa3fe41ed0ee4fabd7c4cf50b5672c6 1b376ab20fb1631502783d22a462faf4 1bf47540483258f246ae798715862591 254b06e053b1c2f976331229f57f6c69 3f940e134c0bc9dcb6f0c20df240d62f 54fe3b133d3c68648dc9cf43a0ed9887 62e1cf645086f26687089080f648a366 d7c659e1110227134421328fdf167c67 ) ],
    'digests()'
);
is_deeply(
    [ sort $db->digests() ],
    [ sort qw( 0fa3fe41ed0ee4fabd7c4cf50b5672c6 1b376ab20fb1631502783d22a462faf4 1bf47540483258f246ae798715862591 254b06e053b1c2f976331229f57f6c69 3f940e134c0bc9dcb6f0c20df240d62f 54fe3b133d3c68648dc9cf43a0ed9887 62e1cf645086f26687089080f648a366 d7c659e1110227134421328fdf167c67 ) ],
    'digests() cached?'
);

# vim: fdm=marker
