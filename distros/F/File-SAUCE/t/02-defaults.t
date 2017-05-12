use Test::More tests => 29;

use strict;
use warnings;
use Time::Piece;

BEGIN {
    use_ok( 'File::SAUCE' );
}

my $date = localtime->ymd;

my $sauce = File::SAUCE->new;
isa_ok( $sauce, 'File::SAUCE' );

is( $sauce->has_sauce, undef,   'Has Sauce (undef)' );
is( $sauce->sauce_id,  'SAUCE', 'SAUCE Id' );
is( $sauce->version,   '00',    'Version' );
is( $sauce->title,     '',      'Title' );
is( $sauce->author,    '',      'Author' );
is( $sauce->group,     '',      'Group' );
isa_ok( $sauce->date, 'Time::Piece', 'Date' );
is( $sauce->date->ymd,            $date,       'Date' );
is( $sauce->filesize,             0,           'Filesize' );
is( $sauce->datatype_id,          0,           'Datatype Id' );
is( $sauce->datatype,             'None',      'Datatype' );
is( $sauce->filetype_id,          0,           'Filetype Id' );
is( $sauce->filetype,             'Undefined', 'Filetype' );
is( $sauce->tinfo1,               0,           'Tinfo 1' );
is( $sauce->tinfo1_name,          undef,       'Tinfo 1 (name)' );
is( $sauce->tinfo2,               0,           'Tinfo 2' );
is( $sauce->tinfo2_name,          undef,       'Tinfo 2 (name)' );
is( $sauce->tinfo3,               0,           'Tinfo 3' );
is( $sauce->tinfo3_name,          undef,       'Tinfo 3 (name)' );
is( $sauce->tinfo4,               0,           'Tinfo 4' );
is( $sauce->tinfo4_name,          undef,       'Tinfo 4 (name)' );
is( $sauce->comment_id,           'COMNT',     'Comment Id' );
is( scalar @{ $sauce->comments }, 0,           'Comments (number of)' );
isa_ok( $sauce->comments, 'ARRAY', 'Comments' );
is( $sauce->filler,   ' ' x 22, 'Filler' );
is( $sauce->flags_id, 0,        'Flags' );
is( $sauce->flags,    'None',   'Flags (name)' );
