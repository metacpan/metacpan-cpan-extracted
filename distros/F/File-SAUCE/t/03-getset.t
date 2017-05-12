use Test::More tests => 61;

use strict;
use warnings;
use Time::Piece;
use Time::Seconds;

BEGIN {
    use_ok( 'File::SAUCE' );
}

my $date = ( localtime ) - ONE_DAY;

my %info = (
    sauce_id    => 'ECUAS',
    version     => '11',
    title       => 'Title',
    author      => 'Author',
    group       => 'Group',
    date        => $date,
    filesize    => 1024,
    datatype_id => 1,
    filetype_id => 1,
    tinfo1      => 1,
    tinfo2      => 1,
    tinfo3      => 1,
    tinfo4      => 1,
    comment_id  => 'TNMOC',
    comments    => [ qw( test comments ) ],
    filler      => 'X' x 22,
    flags_id    => 1
);

my $sauce = File::SAUCE->new( %info );

isa_ok( $sauce, 'File::SAUCE' );

check_metadata( $sauce );

$sauce->clear;

for ( keys %info ) {
    $sauce->$_( $info{ $_ } );
}

check_metadata( $sauce );

$sauce->date( '20040802' );
is( $sauce->date->ymd, '2004-08-02', 'Date (string)' );

sub check_metadata {
    my $sauce = shift;
    is( $sauce->has_sauce, undef,    'Has Sauce (undef)' );
    is( $sauce->sauce_id,  'ECUAS',  'SAUCE Id' );
    is( $sauce->version,   '11',     'Version' );
    is( $sauce->title,     'Title',  'Title' );
    is( $sauce->author,    'Author', 'Author' );
    is( $sauce->group,     'Group',  'Group' );
    isa_ok( $sauce->date, 'Time::Piece', 'Date' );
    is( $sauce->date->ymd,   $date->ymd,  'Date' );
    is( $sauce->filesize,    1024,        'Filesize' );
    is( $sauce->datatype_id, 1,           'Datatype Id' );
    is( $sauce->datatype,    'Character', 'Datatype' );
    is( $sauce->filetype_id, 1,           'Filetype Id' );
    is( $sauce->filetype,    'ANSi',      'Filetype' );
    is( $sauce->tinfo1,      1,           'Tinfo 1' );
    is( $sauce->tinfo1_name, 'Width',     'Tinfo 1 (name)' );
    is( $sauce->tinfo2,      1,           'Tinfo 2' );
    is( $sauce->tinfo2_name, 'Height',    'Tinfo 2 (name)' );
    is( $sauce->tinfo3,      1,           'Tinfo 3' );
    is( $sauce->tinfo3_name, undef,       'Tinfo 3 (name)' );
    is( $sauce->tinfo4,      1,           'Tinfo 4' );
    is( $sauce->tinfo4_name, undef,       'Tinfo 4 (name)' );
    is( $sauce->comment_id,  'TNMOC',     'Comment Id' );
    isa_ok( $sauce->comments, 'ARRAY', 'Comments' );
    is( scalar @{ $sauce->comments }, 2,           'Comments (number of)' );
    is( $sauce->comments->[ 0 ],      'test',      'Comments (line 1)' );
    is( $sauce->comments->[ 1 ],      'comments',  'Comments (line 2)' );
    is( $sauce->filler,               'X' x 22,    'Filler' );
    is( $sauce->flags_id,             1,           'Flags' );
    is( $sauce->flags,                'iCE Color', 'Flags (name)' );
}
