use strict;
use warnings;
use Test::More;
use Time::HiRes;

use IO::Prompt::Timeout qw(:all);

subtest 'Dies when no argument.' => sub {
    eval {
        prompt();
    };
    ok($@, 'died');
};

subtest 'Given default.' => sub {
    my $message = 'prompt';
    my $default = 'yes';
    local $ENV{PERL_IOPT_USE_DEFAULT} = 1;
    my $result = prompt($message, default => $default);
    is($result, $default, 'default taken');
};

subtest 'Should time out.' => sub {
    my $before = Time::HiRes::time;
    prompt('test', timeout => 1);
    my $after = Time::HiRes::time;
    my $lag = $after - $before;
    ok(has_prompt_timed_out(), 'timed out.');
    diag $lag;
    ok($lag > 0.5 && $lag < 1.5, 'timed out by specified time');

};

done_testing;

__END__

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
