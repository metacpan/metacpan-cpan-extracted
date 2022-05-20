use strict;
use warnings;
use Test::More;

my $methods_app  = methods_app();
my $synopsis_app = synopsis_app();

subtest import => sub {
  is strict_app(), undef, 'strict_app';
  like $@, qr{Global symbol}, 'error message';

  ok My::Script->can('new'), 'new()';
  ok My::Script->can('run'), 'run()';
};

subtest constructor => sub {
  ok +My::Script->new->isa('My::Script'), 'isa';
  is_deeply +My::Script->new,             {}, 'empty';
  is_deeply +My::Script->new(foo => 1),   {foo => 1}, 'list';
  is_deeply +My::Script->new({foo => 1}), {foo => 1}, 'ref';
};

subtest run => sub {
  local $main::exit_value = 42;
  is $synopsis_app->([]),               42, 'empty';
  is $synopsis_app->([qw(--name foo)]), 0,  'name';
  is $synopsis_app->([qw(-vv)]),        2,  'verbose';

  local $! = 0;
  eval { $synopsis_app->([qw(-v --invalid)]) };
  is int($!), 1, 'invalid args';
  like $@, qr{Invalid argument or argument order: --invalid}, 'error message';
};

subtest post_process_argv => sub {
  use Getopt::App -capture;
  my $post_process_argv_app = post_process_argv_app();
  is $post_process_argv_app->([]), 3, 'empty exit';
  is_deeply [@main::POST_PROGRESS], [[], {valid => 1}], 'empty args';

  is_deeply capture($post_process_argv_app, [qw(-x)]), ["", "Option x requires an argument\n", 1],
    'invalid exit';
  is_deeply [@main::POST_PROGRESS], [[], {valid => 0}], 'invalid args';
};

subtest methods => sub {
  local $main::exit_value = 42;
  is $methods_app->([qw(-x 40)]),      42, 'default exit value';
  is $methods_app->([qw(four -x 40)]), 4,  'four exit value';
};

subtest exit_value => sub {
  local $main::exit_value = undef;
  is $methods_app->([qw(-x 40)]), 0, 'exit value undef';

  local $main::exit_value = 0;
  is $methods_app->([qw(-x 40)]), 0, 'exit value 0';

  local $main::exit_value = 1;
  is $methods_app->([qw(-x 40)]), 1, 'exit value 1';

  local $main::exit_value = 255;
  is $methods_app->([qw(-x 40)]), 255, 'exit value 255';

  local $main::exit_value = 256;
  is $methods_app->([qw(-x 40)]), 255, 'exit value 256';

  local $main::exit_value = 'foo';
  is $methods_app->([qw(-x 40)]), 0, 'exit value foo';
};

done_testing;

sub methods_app {
  eval <<'HERE' or die $@;
    package My::Hooks;
    use Getopt::App;

    sub command_four { 4 }

    sub getopt_pre_process_argv {
      my ($app, $argv) = @_;
      $app->{subcommand} = shift @$argv if @$argv and $argv->[0] =~ m!^[a-z]!;
    }

    sub getopt_post_process_exit_value { $_[1] || $main::exit_value }

    run('x=i', sub {
      my ($app, @extra) = @_;
      my $method = sprintf 'command_%s', $app->{subcommand} // 'unknown';
      return $app->can($method) && $app->$method;
    });
HERE
}

sub post_process_argv_app {
  eval <<'HERE' or die $@;
    package My::PostProcess;
    use Getopt::App;
    sub getopt_configure { qw(no_ignore_case) }
    sub getopt_post_process_argv { shift; @main::POST_PROGRESS = @_ }
    run('x=i', sub { 3 });
HERE
}

sub strict_app {
  eval 'package Test::Strict; use Getopt::App; $x = 1';
}

sub synopsis_app {
  eval <<'HERE' or die $@;
    package My::Script;
    use Getopt::App;

    run('h|help', 'v+', 'name=s', sub {
      my ($app, @extra) = @_;
      return defined $app->{v} ? $app->{v} : $app->{name} ? 0 : 42;
    });
HERE
}
