use strict;
use warnings;
use Test::More tests => 8;
use Search::Tools::UTF8;
use_ok('HTML::HiLiter');

ok( my $hiliter = HTML::HiLiter->new( query => 'foo', print_stream => 0 ),
    "new HiLiter" );
ok( my $buf     = Search::Tools->slurp('t/docs/latin1.html'), "slurp latin1.html" );
ok( my $hilited = $hiliter->run( \$buf ),          "hilite latin1.html" );
ok( is_latin1($buf),         "latin1 is latin1" );
ok( !is_valid_utf8($buf),    "latin1 is not valid UTF-8" );
ok( is_valid_utf8($hilited), "hilited text is UTF-8" );
like(
    $hilited,
    qr(<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>),
    "meta charset now utf-8"
);
