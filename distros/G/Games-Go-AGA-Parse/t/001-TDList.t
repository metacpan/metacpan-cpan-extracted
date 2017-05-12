#!/usr/bin/perl -w
#===============================================================================
#
#     ABSTRACT:  test script for Games::Go::AGA::Parse::Tdlist
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      CREATED:  Fri Dec  3 10:55:46 PST 2010
#===============================================================================

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 77;
use Carp;

use_ok('Games::Go::AGA::Parse::TDList');

my $parser = new_ok(
    'Games::Go::AGA::Parse::TDList' =>
        [ filename => 'fake_file',
        ],
);

my $result = $parser->parse_line('Xaa, Aaa   32 Full   5.1 4/23/2009 Mnoo CZ');
is ($result->{last_name},  'Xaa',        'all fields, last name');
is ($result->{first_name}, 'Aaa',        'all fields, first name');
is ($result->{id},         'USA32',      'all fields, ID');
is ($result->{membership}, 'Full',       'all fields, membership');
is ($result->{rank},       '5.1',        'all fields, rank');
is ($result->{date},       '4/23/2009',  'all fields, date');
is ($result->{club},       'Mnoo',       'all fields, club');
is ($result->{state},      'CZ',         'all fields, state');


# no first name is OK
$result = $parser->parse_line('Xba       33 Youth  5.0  5/24/1901 MNOP CA');
is ($result->{last_name},  'Xba',        'missing first_name, last name');
is ($result->{first_name}, '',           'missing first_name, first name');
is ($result->{id},         'USA33',      'missing first_name, ID');
is ($result->{membership}, 'Youth',      'missing first_name, membership');
is ($result->{rank},       '5',          'missing first_name, rank');
is ($result->{date},       '5/24/1901',  'missing first_name, date');
is ($result->{club},       'MNOP',       'missing first_name, club');
is ($result->{state},      'CA',         'missing first_name, state');

# no ID - strange, but no exception - downstream should catch it
$result = $parser->parse_line('Xca, Aab     Full   4d   6/23/2009 Mnoq CB');
is ($result->{last_name},  'Xca',        'missing_ID, last name');
is ($result->{first_name}, 'Aab',        'missing_ID, first name');
is ($result->{id},         '',           'missing_ID, ID');
is ($result->{membership}, 'Full',       'missing_ID, membership');
is ($result->{rank},       '4d',         'missing_ID, rank');
is ($result->{date},       '6/23/2009',  'missing_ID, date');
is ($result->{club},       'Mnoq',       'missing_ID, club');
is ($result->{state},      'CB',         'missing_ID, state');

# no membership is allowed (may not be AGA member)
$result = $parser->parse_line('Xda, Aac  35        4.8  7/23/2009 MNor CC');
is ($result->{last_name},  'Xda',        'missing membership, last name');
is ($result->{first_name}, 'Aac',        'missing membership, first name');
is ($result->{id},         'USA35',      'missing membership, ID');
is ($result->{membership}, '',           'missing membership, membership');
is ($result->{rank},       '4.8',        'missing membership, rank');
is ($result->{date},       '7/23/2009',  'missing membership, date');
is ($result->{club},       'MNor',       'missing membership, club');
is ($result->{state},      'CC',         'missing membership, state');

# invalid membership throws exception
throws_ok {
    $result = $parser->parse_line('Xxx, Aaa     20x Fullx     -20 4/24/1901 CO');
} qr/^Invalid membership/s, 'invalid membership throws exception';

# no rank -> 0.0
$result = $parser->parse_line('Xea, Aad  36 Full        8/23/2009 Mnos CD');
is ($result->{last_name},  'Xea',        'missing rank, last name');
is ($result->{first_name}, 'Aad',        'missing rank, first name');
is ($result->{id},         'USA36',      'missing rank, ID');
is ($result->{membership}, 'Full',       'missing rank, membership');
is ($result->{rank},       '',           'missing rank, rank');
is ($result->{date},       '8/23/2009',  'missing rank, date');
is ($result->{club},       'Mnos',       'missing rank, club');
is ($result->{state},      'CD',         'missing rank, state');

# invalid rank throws exception
throws_ok {
    $result = $parser->parse_line('Xxx, Aaa     20x Full     22d 4/24/1901 CO');
} qr/^Invalid rank/s, 'invalid rank throws exception';


# no date is OK
$result = $parser->parse_line('Xfa, Aae  37 Full   4.6            mnot CE');
is ($result->{last_name},  'Xfa',        'missing date, last name');
is ($result->{first_name}, 'Aae',        'missing date, first name');
is ($result->{id},         'USA37',      'missing date, ID');
is ($result->{membership}, 'Full',       'missing date, membership');
is ($result->{rank},       '4.6',        'missing date, rank');
is ($result->{date},       '',           'missing date, date');
is ($result->{club},       'mnot',       'missing date, club');
is ($result->{state},      'CE',         'missing date, state');

# no club is OK
$result = $parser->parse_line('Xga, Aaf  38 Full   5k   9/23/2009      CF');
is ($result->{last_name},  'Xga',        'missing club, last name');
is ($result->{first_name}, 'Aaf',        'missing club, first name');
is ($result->{id},         'USA38',      'missing club, ID');
is ($result->{membership}, 'Full',       'missing club, membership');
is ($result->{rank},       '5k',         'missing club, rank');
is ($result->{date},       '9/23/2009',  'missing club, date');
is ($result->{club},       '',           'missing club, club');
is ($result->{state},      'CF',         'missing club, state');

# no state is OK
$result = $parser->parse_line('Xga, Aaf  38 Full   25K 10/23/2009 MNOU');
is ($result->{last_name},  'Xga',        'missing state, last name');
is ($result->{first_name}, 'Aaf',        'missing state, first name');
is ($result->{id},         'USA38',      'missing state, ID');
is ($result->{membership}, 'Full',       'missing state, membership');
is ($result->{rank},       '25K',        'missing state, rank');
is ($result->{date},       '10/23/2009', 'missing state, date');
is ($result->{club},       'MNOU',       'missing state, club');
is ($result->{state},      '',           'missing state, state');


$result = $parser->parse_line('Chung, Seongtaek             19692 Non      6.3            TGG  --             ');
is ($result->{last_name},  'Chung',     'bad_line, last name');
is ($result->{first_name}, 'Seongtaek', 'bad_line, first name');
is ($result->{id},         'USA19692',  'bad_line, ID');
is ($result->{membership}, 'Non',       'bad_line, membership');
is ($result->{rank},       '6.3',       'bad_line, rank');
is ($result->{date},       '',          'bad_line, date');
is ($result->{club},       'TGG',       'bad_line, club');
is ($result->{state},      '--',        'bad_line, state');

eval {
    $result = $parser->parse_line('Xxx, Aaa     20 Fullx     -20 4/24/1901 CO');
};

if (my $x = Exception::Class->caught('Games::Go::AGA::Parse::Exception')) {
    eval {
        Games::Go::AGA::Parse::Exception->throw(
            error       => $x->error,
            filename    => 'foo',
            line_number => 321,
        );
    };
    if (my $x = Exception::Class->caught('Games::Go::AGA::Parse::Exception')) {
        like ($x->full_message, qr/Invalid membership/s, 'exception re-thrown');
    }
    elsif ($@) {
        fail("new exception: $@");
    }
    else {
        fail("failed to catch re-thrown exception");
    }
}
else {
    fail("failed to catch exception");
}
__DATA__

This is sample TDList format.  Of course, this line is invalid.

Augustin, Reid                2122 Full   5.1  4/23/2009 PALO CA
Xxx, Reid                     20 Full     -20  4/24/1901 CO
Augustin, Yyx                 21 Comp     1.1  4/25/1929 SFGC MI
Augustin, Yyy                 99 Comp     1.2  4/26/1929 Berk MI
Augustin, Yyz                 2111 Comp   1.3  4/27/1929 AbCd MI

