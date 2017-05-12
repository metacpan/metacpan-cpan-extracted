use sanity;
use Test::Most tests => 45;

use Test::DZil;
use YAML;
use Data::Dumper;
use List::AllUtils v0.04 qw(pairs);

sub test_travis_yml {
   my $opts = shift;

   my $tzil = Builder->from_config(
      { dist_root => 'corpus/dist' },
      { add_files => {
         'source/dist.ini' => simple_ini(
            [ TravisYML => $opts ],
         ),
      } },
   );

   $tzil->chrome->logger->set_debug(1);
   lives_ok(sub { $tzil->build }, 'built distro') || explain $tzil->log_messages;

   my $yml = YAML::LoadFile($tzil->tempdir->file('source/.travis.yml'));

   foreach (pairs @_) {
      my ($key, $value) = @$_;

      # Serialize options for test name
      my $d = Data::Dumper->new([$opts]);
      my $test_name = $d->Indent(0)->Quotekeys(0)->Terse(1)->Pair('=>')->Dump;
      $test_name .= " --> $key";

      is_deeply($yml->{$key}, $value, $test_name) || always_explain $yml;
   }
}

# Basic checks
test_travis_yml(
   {},
   language => 'perl',
   script   => [ 'dzil smoke --release --author' ],
);

# Email notification
test_travis_yml(
   { notify_email => 0 },
   notifications => { email => 'false' },
);
test_travis_yml(
   { notify_email => 1 },
   notifications => undef,
);
test_travis_yml(
   { notify_email => 'foo@bar.com' },
   notifications => { email => ['foo@bar.com'] },
);

# IRC notification
# TODO: Test notify_irc=>1 with IRC/x_irc meta resource value
test_travis_yml(
   { notify_irc => 0 },
   notifications => undef,
);
test_travis_yml(
   { notify_irc => 'irc://irc.perl.org/#roomname' },
   notifications => { irc => {
      on_failure => 'always',
      on_success => 'change',
      use_notice => 'true',
      channels   => [ 'irc.perl.org#roomname' ],
      template   => [ '%{branch}#%{build_number} by %{author}: %{message} (%{build_url})' ],
   } },
);
test_travis_yml(
   { notify_irc => 'irc://irc.perl.org/#roomname', irc_template => 'foobar' },
   notifications => { irc => {
      on_failure => 'always',
      on_success => 'change',
      use_notice => 'true',
      channels   => [ 'irc.perl.org#roomname' ],
      template   => [ 'foobar' ],
   } },
);

# Perl version testing
test_travis_yml(
   {},
   perl   => [ qw(blead 5.20 5.18 5.16 5.14 5.12 5.10 5.8) ],
   matrix => {
      fast_finish    => 'true',
      allow_failures => [ { perl => 'blead' }, { perl => '5.8' } ],
   },
);
test_travis_yml(
   { perl_version => '-5.10    5.12' },
   perl   => [ qw(5.10 5.12) ],
   matrix => {
      fast_finish    => 'true',
      allow_failures => [ { perl => '5.10' } ],
   },
);
test_travis_yml(
   { perl_version => '5.10' },
   matrix => { fast_finish => 'true' },
);
test_travis_yml(
   { support_builddir => 1, perl_version_build => '5.8 -5.55' },
   env    => [ 'BUILD=0', 'BUILD=1' ],
   perl   => [ qw(blead 5.20 5.18 5.16 5.14 5.12 5.10 5.8 5.55) ],
   matrix => {
      fast_finish    => 'true',
      allow_failures => [
         { perl => 'blead', env => 'BUILD=0' },
         { perl => '5.8',   env => 'BUILD=0' },
         { perl => '5.55',  env => 'BUILD=1' },
      ],
   },
);

# Various custom commands
foreach my $f ('', '_dzil') {  # both should do the same thing
   my $method = 'script'.$f;
   test_travis_yml(
      { $method, 'newcmd' },
      script => [ 'newcmd' ],
   );
   test_travis_yml(
      { 'pre_'.$method, 'newcmd' },
      script => [ 'newcmd', 'dzil smoke --release --author' ],
   );
   test_travis_yml(
      { 'post_'.$method, 'newcmd' },
      script => [ 'dzil smoke --release --author', 'newcmd' ],
   );
}
foreach my $t ('', 'pre_', 'post_') {
   # because this only touches build files, this should do nothing
   my $method = $t.'script_build';
   test_travis_yml(
      { $method, 'newcmd' },
      script => [ 'dzil smoke --release --author' ],
   );
}
