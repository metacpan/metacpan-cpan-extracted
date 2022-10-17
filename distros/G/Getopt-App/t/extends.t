package My::Script::Base;
sub getopt_post_process_argv { die join ' / ', __PACKAGE__, ref $_[0] }
$INC{'My/Script/Base.pm'} = 1;

package main;
use Test2::V0;

subtest invalid => sub {
  eval q(package main; use Getopt::App 'My::Class';1);
  like $@, qr{package definition required}, 'main';
};

subtest valid => sub {
  use Getopt::App -capture;
  my $app = eval q(package My::Script::Foo; use Getopt::App 'My::Script::Base'; run(sub { }))
    or die $@;
  eval { $app->([]) };
  like $@, qr{My::Script::Base / My::Script::Foo}, 'isa';
};

done_testing;
