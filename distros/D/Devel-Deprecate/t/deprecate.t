#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';    # tests => 1;
use lib 't/lib';
use TestDeprecate;

use Devel::Deprecate 'deprecate';
use DateTime;

ok defined &deprecate, 'deprecate() should be exported to our namespace';

#
# OK, let's go to town, baby
#
# Test basic deprecation -- non-fatal
#

check { deprecate(reason => 'Cuz I said so') };
ok !$CONFESS, 'Calling deprecate() with only a reason should not be fatal';
like $CLUCK, qr/Cuz I said so/, '... and it should cluck() the reason';

my $yesterday          = DateTime->today->subtract(days => 1);
my $today              = DateTime->today;
my $tomorrow           = DateTime->today->add(days => 1);
my $day_after_tomorrow = DateTime->today->add(days => 2);

#
# check warn dates
#

check { deprecate(reason => "Wasn't born yet", warn => $tomorrow) };
ok !is_deprecated, 'Is not deprecated if the warn date is in the future';

check { deprecate(reason => "Was born today", warn => $today) };
ok is_deprecated, 'Is deprecated if the warn date is today';
like $CLUCK, qr/Was born today/, '... and cluck() if appropriate';

check { deprecate(reason => "Was born today", warn => $today, die => $tomorrow) };
ok is_deprecated,
        'Is deprecated if the warn date is today and we die in the future';
like $CLUCK, qr/Was born today/, '... and cluck() if appropriate';
like $CLUCK, qr/\QThis warning becomes FATAL on (@{[$tomorrow->ymd]})/,
        '... and telling us when the warning becomes fatal';

my $reason = <<END;
This is
a multi-line
reason
END
sub foo {
    deprecate(reason => $reason, warn => $today, die => $tomorrow);
}
foo();
print $CLUCK;

check { deprecate(reason => "Was born today", warn => $today) };
like $CLUCK, qr/Was born today/, '... or cluck() if appropriate';

check { deprecate(reason => "Was born yesterday", warn => $yesterday) };
ok is_deprecated, 'Is deprecated if the warn date is in the past';
like $CLUCK, qr/Was born yesterday/, '... and cluck() if appropriate';

#
# check ymd strings
#

check { deprecate(reason => "Wasn't born yet", warn => $tomorrow->ymd) };
ok !is_deprecated,
        'Is not deprecated if the warn date is in the future and in YMD format';

check { deprecate(reason => "Was born today", warn => $today->ymd) };
ok is_deprecated, 'Is deprecated if the warn date is today and in YMD format';
like $CLUCK, qr/Was born today/, '... and cluck() if appropriate';

check {
    deprecate(
        reason => "Was born today",
        warn   => $today->ymd,
        die    => $tomorrow->ymd
    );
};
ok is_deprecated,
        'Is deprecated if the warn date is today and we die in the future and in YMD format';
like $CLUCK, qr/Was born today/, '... and cluck() if appropriate';
like $CLUCK, qr/\QThis warning becomes FATAL on (@{[$tomorrow->ymd]})/,
        '... and telling us when the warning becomes fatal';

#
# check die dates
#

check { deprecate(reason => "Wasn't born yet", die => $tomorrow) };
ok is_deprecated, 'Is deprecated if future die date and no warn';

check {
    deprecate(
        reason => "Wasn't born yet",
        warn   => $tomorrow,
        die    => $day_after_tomorrow
    );
};
ok !is_deprecated, 'Is not deprecated if future die and warn dates';

check { deprecate(reason => "Was born today", die => $today) };
ok is_deprecated, 'Is deprecated if the die date is today';
like $CONFESS, qr/Was born today/, '... and confess() if appropriate';

check { deprecate(reason => "Was born yesterday", die => $yesterday) };
ok is_deprecated, 'Is deprecated if the die date is in the past';
like $CONFESS, qr/Was born yesterday/, '... and confess() if appropriate';

#
# Test 'if'
#

check { deprecate(reason => "Was born today", warn => $today, if => 1) };
ok is_deprecated, 'Is deprecated if the warn date is today and "if" is true';
like $CLUCK, qr/Was born today/, '... and cluck() if appropriate';

check {
    deprecate(reason => "Was born today", warn => $today, if => sub { 1 });
};
ok is_deprecated, 'Is deprecated if the warn date is today and "if" is true';
like $CLUCK, qr/Was born today/, '... and cluck() if appropriate';

check { deprecate(reason => "Was born today", warn => $today, if => 0) };
ok !is_deprecated,
        'Is not deprecated if the warn date is today and "if" is false';

check {
    deprecate(reason => "Was born today", warn => $today, if => sub { 0 });
};
ok !is_deprecated,
        'Is not deprecated if the warn date is today and "if" is false';
