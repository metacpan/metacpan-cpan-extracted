use strict;
use warnings;
use Test::More;
use Test::Applify;
use File::Temp qw{tempdir};
use Path::Class qw{dir};
use JSON::MaybeXS qw(decode_json);

my $tmp =
  tempdir('devel-iperl-plugin-perlbrew-XXXXX', TMPDIR => 1, CLEANUP => 1 );
my ($t, $app);
my ($r, $out, $err, $e);
## installer script
$t = new_ok('Test::Applify', ['./scripts/perlbrewise-spec']);
$t->help_ok->is_option('omit-home')->is_option('jupyter')->is_option('iperl');
$t->can_ok(qw{_all_variables_set});

$app = $t->app_instance('--jupyter', join ' ', $^X, './t/jupyter', $tmp);
is $app->jupyter, join(' ', $^X, './t/jupyter', $tmp), 'jupyter set';

($r, $out, $err, $e) = $t->run_instance_ok($app);
is $r, 1, 'file does not exist';

is $out, '', 'no messages on stdout';

SKIP: {
  skip "CI has no jupyter.", 4 if $ENV{CI};
  like $err, qr{Devel::IPerl}, 'messages ok';
  like $err, qr{Devel/IPerl}, 'messages ok';
  like $err, qr{does not exist}, 'messages ok';
  like $err, qr{requires an existing kernel\.json}, 'messages ok';
}

## test _all_variables_set as it is core to workings
if (my $all_vars = $app->can('_all_variables_set')) {
  local %ENV = %ENV;
  @ENV{qw{PERLBREW_HOME PERLBREW_PATH PERLBREW_PERL PERLBREW_ROOT PERLBREW_VERSION}} =
    qw{/home/user /sw/perlbrew/bin perl-5.26.0 /sw/perlbrew 0.78};
  my $spec = {
    env => {
      # purposely missing PERLBREW_PERL
      map { $_ => $ENV{$_} } qw{PERLBREW_HOME PERLBREW_PATH
                                PERLBREW_ROOT PERLBREW_VERSION}
    }
  };
  is $all_vars->({}), '', 'nothing set';
  is $all_vars->($spec), '', 'not all set';

  $spec->{env}{PERLBREW_PERL} = $ENV{PERLBREW_PERL};
  is $all_vars->($spec), 1, 'all set';

  $ENV{PERLBREW_VERSION} = "0.82";
  is $all_vars->($spec), '', 'version mismatch';

  $spec->{env}{PERLBREW_VERSION} = $ENV{PERLBREW_VERSION};
  is $all_vars->($spec), 1, 'version matches';

  delete $spec->{env}{PERLBREW_VERSION};
  is $all_vars->($spec), '', 'version mismatch';
}

my $target = $app->get_kernels_target_dir;
$target->mkpath;
my $kernel_file = dir($target)->file('kernel.json');
diag $kernel_file if $ENV{TEST_VERBOSE};

$kernel_file->spew(<<'EOF');
{
  "argv": [ "test" ]
}
EOF

($r, $out, $err, $e) = $t->run_instance_ok($app);
is $r, 0, 'now that file does exist';

SKIP: {
  skip "CI has no jupyter.", 2 if $ENV{CI};
  like $err, qr{Devel::IPerl}, 'messages ok';
  like $err, qr{Devel/IPerl},  'messages ok';
};

is_deeply decode_json($kernel_file->slurp()), {
  argv => ["test"],
  env  => {
    map { $_ => $ENV{$_} }
      qw{PERLBREW_PATH PERLBREW_PERL PERLBREW_ROOT PERLBREW_VERSION PERLBREW_HOME}
  }
}, 'json all good';

$kernel_file->remove;

done_testing;
