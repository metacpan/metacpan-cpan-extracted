use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply like ok plan subtest use_ok ) ], tests => 20;
use Test::Fatal qw( exception lives_ok );
use Test::Warn  qw( warning_like );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( getopts ) or BAIL_OUT "Cannot loade module '$module'!"
}

like exception { $module->import( '_private' ) }, qr/not exported/, 'Export error';

subtest 'Validate $spec parameter' => sub {
  plan tests => 6;

  local @ARGV = ();
  my %opts;
  like exception { getopts undef, %opts }, qr/isn't a non-empty string of alphanumeric/, 'Undefined value is not allowed';
  like exception { getopts '',     %opts }, qr/isn't a non-empty string of alphanumeric/, 'Empty value is not allowed';
  like exception { getopts 'a:-b', %opts }, qr/isn't a non-empty string of alphanumeric/, "'-' character is not allowed";
  like exception { getopts ':a:b', %opts }, qr/isn't a non-empty string of alphanumeric/,
    "Leading ':' character is not allowed";
  like exception { getopts 'aba:', %opts }, qr/multiple times/, 'Same option character is not allowed';
  ok getopts( 'a:b', %opts ), 'Succeeded'
};

subtest 'Validate $opts parameter' => sub {
  plan tests => 1;

  my %opts = ( a => 'foo' );
  like exception { getopts 'a:b', %opts }, qr/isn't empty/, 'Result %opts hash has to be empty'
};

subtest 'Single option without option-argument (flag)' => sub {
  plan tests => 3;

  local @ARGV = qw( -b );
  ok getopts( 'b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { b => 1 }, 'Flag has value 1';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Single option with option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo );
  ok getopts( 'a:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo' }, 'Option has option-argument';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Empty @ARGV' => sub {
  plan tests => 3;

  local @ARGV = ();
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Default for option with option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -b );
  # Simulate default for option with option-argument
  unshift @ARGV, ( -a => 'foo' );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Grouping: Flag followed by single option with option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Disallowed grouping: Single option with option-argument in the middle' => sub {
  plan tests => 4;

  local @ARGV = qw( -cab foo );
  my %got_opts;
  warning_like { ok !getopts( 'a:bc', %got_opts ), 'Failed' } qr/option with argument isn't last one in group -- a/,
    'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ qw( -cab foo ) ], '@ARGV restored'
};

subtest 'End of options delimiter' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo -c -- -d bar );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1, c => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( -d bar ) ], 'Options removed from @ARGV'
};

subtest 'End of options delimiter is an option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo -d -- -c );
  ok getopts( 'a:bcd:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1, c => 1, d => '--' }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Unknown option' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -d bar );
  my %got_opts;
  warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/illegal option -- d/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ qw( -b -d bar ) ], '@ARGV restored'
};

subtest 'Unknown option; default properly restored' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -d bar );
  # Simulate default for option with option-argument
  unshift @ARGV, ( -a => 'foo' );
  my %got_opts;
  warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/illegal option -- d/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ qw( -a foo -b -d bar ) ], '@ARGV restored'
};

subtest 'Missing option-argument' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -a foo -c );
  my %got_opts;
  # https://github.com/Perl/perl5/issues/23906
  # Getopt::Std questionable undefined value bahaviour
  warning_like { ok !getopts( 'a:bc:', %got_opts ), 'Failed' } qr/option requires an argument -- c/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ qw( -b -a foo -c ) ], '@ARGV restored'
};

subtest 'Undefined option-argument' => sub {
  plan tests => 4;

  local @ARGV = ( '-b', '-a', undef, '-c' );
  my %got_opts;
  warning_like { ok !getopts( 'a:bc', %got_opts ), 'Failed' } qr/option requires an argument -- a/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ ( '-b', '-a', undef, '-c' ) ], '@ARGV restored'
};

subtest 'Non-option-argument stops option parsing' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -a foo bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( bar -c ) ], 'Options removed from @ARGV'
};

subtest 'The option delimiter is a non-option-argument that stops option parsing' => sub {
  plan tests => 3;

  local @ARGV = qw( -b - a foo bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { b => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( - a foo bar -c ) ], 'Options removed from @ARGV'
};

subtest 'Overwrite option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo -b -a bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'bar', b => 1, c => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Slurp option' => sub {
  plan tests => 3;

  local @ARGV = qw( -a -b -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => '-b', c => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
}
