use strict;
use Test::More 0.98;
use Test::Exception;

use Log::GELF::Util qw(parse_size parse_level);

throws_ok{
    my %msg = parse_size();
}
qr/0 parameters were passed.*/,
'parse_size mandatory parameters missing';

throws_ok{
    my %msg = parse_size({});
}
qr/Parameter #1.*/,
'parse_size wrong type';

throws_ok{
    my %msg = parse_size(-1);
}
qr/chunk size must be "lan", "wan", a positve integer, or 0 \(no chunking\)/,
'parse_size invalid numeric value';

throws_ok{
    my %msg = parse_size('wrong');
}
qr/chunk size must be "lan", "wan", a positve integer, or 0 \(no chunking\)/,
'parse_size invalid string value';

my $size;
lives_ok{
    $size = parse_size(1);
}
'numeric size';
is($size, 1, 'correct numeric size');

lives_ok{
    $size = parse_size('lan');
}
'string lan size';
is($size, 8152, 'correct lan size');

lives_ok{
    $size = parse_size('LAN');
}
'string LAN size';
is($size, 8152, 'correct LAN size');

lives_ok{
    $size = parse_size('wan');
}
'string wan size';
is($size, 1420, 'correct numeric size');

lives_ok{
    $size = parse_size('WAN');
}
'string WAN size';
is($size, 1420, 'correct WAN size');

throws_ok{
   parse_level();
}
qr/0 parameters were passed.*/,
'parse_level mandatory parameters missing';

throws_ok{
   parse_level({});
}
qr/Parameter #1.*/,
'parse_level wrong type';

throws_ok{
   parse_level(-1);
}
qr/level must be between 0 and 7 or a valid log level string/,
'parse_level invalid numeric value';

throws_ok{
   parse_level(8);
}
qr/level must be between 0 and 7 or a valid log level string/,
'parse_level invalid numeric value - too big';

throws_ok{
    parse_level('wrong');
}
qr/level must be between 0 and 7 or a valid log level string/,
'parse_level invalid string value';

my $level;
lives_ok{
    $level = parse_level(0);
}
'correct numeric level';
is($level, 0, 'correct numeric level min');

lives_ok{
    $level = parse_level(7);
}
'correct numeric level';
is($level, 7, 'correct numeric level max');

my $level_no = 0;
foreach my $lvl_name (
    qw(
        emerg
        alert
        crit
        err
        warn
        notice
        info
        debug
    )
) {
    lives_ok{
        $level = parse_level($lvl_name);
    }
    "level $lvl_name ok";
    
    is($level, $level_no++, "level $lvl_name correct value");
}

$level_no = 0;
foreach my $lvl_name (
    qw(
        emergency
        alert
        critical
        error
        warning
        notice
        information
        debug
    )
) {
    lives_ok{
        $level = parse_level($lvl_name);
    }
    "level long $lvl_name ok";
    
    is($level, $level_no++, "level long $lvl_name correct value");
}

done_testing(55);
