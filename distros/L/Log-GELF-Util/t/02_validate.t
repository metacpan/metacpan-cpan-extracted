use strict;
use Test::More 0.98;
use Test::Exception;
use Test::Warnings 0.005 qw(warning allow_warnings);

use Log::GELF::Util qw(validate_message);

throws_ok{
    validate_message();
}
qr/Mandatory parameter 'short_message' missing.*/,
'mandatory parameters missing';

throws_ok{
    validate_message(
        version        => '1.x',
        host           => 1,
        short_message  => 1,
    );
}
qr/version must be 1.1, supplied.*/,
'version check';

throws_ok{
    validate_message(
        host           => 1,
        short_message  => 1,
        level          => 'x',
    );
}
qr/level must be between 0 and 7 or a valid log level string/,
'level check';

throws_ok{
    validate_message(
        host           => 1,
        short_message  => 1,
        timestamp      => 'x',
    );
}
qr/bad timestamp/,
'timestamp check';

throws_ok{
    validate_message(
        host           => 1,
        short_message  => 1,
        bad            => 'to the bone.',
    );
}
qr/invalid field 'bad'.*/,
'bad field check';

throws_ok{
    validate_message(
        host           => 1,
        short_message  => 1,
        'bad name'     => 'to the bone.',
    );
}
qr/invalid field 'bad name'.*/,
'bad field check 2';

allow_warnings 1; #throws legit warnings
throws_ok{
    validate_message(
        host           => 1,
        short_message  => 1,
        facility       => {},
    );
}
qr/The 'facility' parameter.*/,
'bad facility check';

throws_ok{
    validate_message(
        host           => 1,
        short_message  => 1,
        line           => 'wrong',
    );
}
qr/line must be a number/,
'bad line check';
allow_warnings 0;

like( warning {
    validate_message(
        host           => 1,
        short_message  => 1,
        facility       => 1,
    );
},
qr/^facility is deprecated.*/,
'facility deprecated');

like( warning {
    validate_message(
        host           => 1,
        short_message  => 1,
        line       => 1,
    );
},
qr/^line is deprecated.*/,
'line deprecated');

like( warning {
    validate_message(
        host           => 1,
        short_message  => 1,
        file           => 1,
    );
},
qr/^file is deprecated.*/,
'file deprecated');

my $msg;
lives_ok{
    $msg = validate_message(
        host           => 1,
        short_message  => 1,
    );
}
'default version';

my $time = time;
is($msg->{version},     '1.1', 'correct default version');
like($msg->{timestamp}, qr/\d+\.\d+/, 'default timestamp');
is($msg->{level},       1, 'default level');

lives_ok{
    $msg = validate_message(
        host           => 1,
        short_message  => 1,
        level          => 2,
    );
}
'numeric level';
is($msg->{level},       2, 'default level');

lives_ok{
    $msg = validate_message(
        host           => 1,
        short_message  => 1,
        level          => 'err',
    );
}
'numeric level';
is($msg->{level}, 3, 'default level');

allow_warnings 1; #throws legit warnings
lives_ok{
    $msg = validate_message(
        host           => 1,
        short_message  => 1,
        facility       => 1,
    );
}
'facility check';
ok(exists $msg->{facility}, 'line exists');
is($msg->{facility}, '1', 'correct facility');

lives_ok{
    $msg = validate_message(
        host           => 1,
        short_message  => 1,
        line           => 1,
    );
}
'line check';
ok(exists $msg->{line}, 'line exists');
is($msg->{line}, '1', 'correct line');
allow_warnings 0;

done_testing(26);
