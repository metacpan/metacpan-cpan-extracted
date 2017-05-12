#!perl -w
use strict;
use Test::More;

use Dist::Maker;
use Dist::Maker::Command::init;
use Dist::Maker::Command::new;

note 'Dist::Maker';
my($opts, @args) = Dist::Maker->parse_options(
    qw(--verbose 4 foo --bar)
);
is_deeply $opts, { verbose => 4 };
is_deeply \@args, [qw(foo --bar)];

($opts, @args) = Dist::Maker->parse_options(
    qw(foo --verbose 4 --bar)
);
is_deeply $opts, { verbose => 4 };
is_deeply \@args, [qw(foo --bar)];

note 'Dist::Maker::Command::init';
($opts, @args) = Dist::Maker::Command::init->parse_options(
    qw(--dry-run --force foo bar)
);

is_deeply $opts, { 'dry-run' => 1, 'force' => 1 };
is_deeply \@args, [qw(foo bar)];

($opts, @args) = Dist::Maker::Command::init->parse_options(
    qw(-n -f foo bar)
);

is_deeply $opts, { 'dry-run' => 1, 'force' => 1 };
is_deeply \@args, [qw(foo bar)];

note 'Dist::Maker::Command::new';
($opts, @args) = Dist::Maker::Command::new->parse_options(
    qw(--dry-run --force foo bar)
);

is_deeply $opts, { 'dry-run' => 1, 'force' => 1 };
is_deeply \@args, [qw(foo bar)];

($opts, @args) = Dist::Maker::Command::new->parse_options(
    qw(-n -f foo bar)
);

is_deeply $opts, { 'dry-run' => 1, 'force' => 1 };
is_deeply \@args, [qw(foo bar)];

done_testing;
