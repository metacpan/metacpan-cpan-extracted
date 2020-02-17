use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;
use JSON qw/decode_json/;

use Duadua::CLI;

{
    ok(Duadua::CLI->_show_usage('NOEXIT'));
}

{
    my $command = 'script/duadua';

    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '--version'
    );
    is $?, 256, '--version';

    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '-v'
    );
    is $?, 256, '-v';

    system(
        $^X, (map { "-I$_" } @INC),
        $command,
    );
    is $?, 512, 'no args'; # as help

    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '--help'
    );
    is $?, 256, '--help';

    system(
        $^X, (map { "-I$_" } @INC),
        $command,
        '-h'
    );
    is $?, 256, '-h';
}

{
    my $d = Duadua::CLI->new('UA');
    isa_ok $d, 'Duadua::CLI';
    isa_ok $d->d, 'Duadua';
    my $ua_list = $d->opt('ua_list');
    is $ua_list->[0], 'UA';
}

{
    my $d = Duadua::CLI->new('UA');
    my ($stdout, $stderr) = capture {
        $d->run;
    };
    is $stderr, '';
    my $h = decode_json($stdout);
    is $h->{name}, 'UNKNOWN';
    is $h->{version}, '-';
    is $h->{is_bot}, 0;
}

{
    no warnings 'redefine';
    local *Duadua::CLI::_is_opened_stdin = sub { 1 };
    my $ua = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';
    my ($stdout, $stderr) = capture {
        open my $IN, '<', \$ua;
        local *STDIN = $IN;
        Duadua::CLI->new->run;
    };
    is $stderr, '';
    my $h = decode_json($stdout);
    is $h->{name}, 'Googlebot';
    is $h->{version}, '2.1';
    is $h->{is_bot}, 1;
}

done_testing;
