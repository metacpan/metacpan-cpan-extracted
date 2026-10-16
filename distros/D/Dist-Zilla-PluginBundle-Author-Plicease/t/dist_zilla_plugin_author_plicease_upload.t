use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use Path::Tiny qw( path tempdir );
use CPAN::Uploader;
use Capture::Tiny qw( capture_stderr );

local $ENV{DZIL_RELEASING};

# keep ~/www/dist.wdlabs.com/docs and ~/dev/site-dist/docs pointed somewhere we control
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = "$home";

my @uploaded;

# make sure we never actually talk to PAUSE
my $mock = mock 'CPAN::Uploader' => (
  override => [
    upload_file => sub {
      my($self, $file) = @_;
      push @uploaded, { file => $file, user => $self->{user}, password => $self->{password} };
      return;
    },
  ],
);

my @keep;

sub tzil
{
  my(%config) = @_;

  my $pause = tempdir( CLEANUP => 1 );
  push @keep, $pause;
  $pause->child('.pause')->spew_utf8(
    $config{no_credentials} ? "" : "user FOOBAR\npassword secret\n"
  );
  delete $config{no_credentials};

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          [ 'Author::Plicease::Upload' => {
            pause_cfg_dir  => "$pause",
            pause_cfg_file => '.pause',
            %config,
          } ],
        )
      }
    }
  );

  return $tzil;
}

sub log_messages ($)
{
  my($tzil) = @_;
  [ map { $_->{message} } $tzil->chrome->logger->events->@* ];
}

subtest 'defaults' => sub {

  my $tzil = tzil();
  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Author::Plicease::Upload') } $tzil->plugins->@*;

  isa_ok $plugin, 'Dist::Zilla::Plugin::UploadToCPAN';
  is $plugin->cpan, 1, 'cpan defaults to on';
  is $plugin->url, 'http://dist.wdlabs.com/', 'default url';

};

subtest 'upload to cpan' => sub {

  @uploaded = ();

  my $tzil = tzil();
  $tzil->chrome->set_response_for('upload to CPAN?' => 'y');

  $tzil->release;

  is
    \@uploaded,
    [ hash {
      field file     => match qr/DZT-Sample-0\.001\.tar\.gz$/;
      field user     => 'FOOBAR';
      field password => 'secret';
      end;
    } ],
    'uploaded to CPAN with credentials';

  note $_ for log_messages($tzil)->@*;

};

subtest 'upload to cpan without credentials' => sub {

  @uploaded = ();

  my $tzil = tzil( no_credentials => 1 );
  $tzil->chrome->set_response_for('upload to CPAN?' => 'y');
  $tzil->chrome->set_response_for('PAUSE username: ' => '');

  # before_release is a no-op, so missing credentials are not
  # fatal, they are just logged during release.
  ok lives { $tzil->release }, 'release does not die' or note $@;

  is \@uploaded, [], 'nothing uploaded';

  my $log = log_messages($tzil);
  note $_ for @$log;
  ok( (grep /error uploading to cpan: no username/, @$log), 'logged missing username' );
  ok( (grep /you will have to manually upload the dist/, @$log), 'logged manual upload' );

};

subtest 'declined cpan, falls back to ~/dev/site-dist/docs' => sub {

  @uploaded = ();

  my $docs = $home->child('dev/site-dist/docs');
  $docs->mkpath;

  my $tzil = tzil();
  $tzil->chrome->set_response_for('upload to CPAN?' => 'n');

  $tzil->release;

  is \@uploaded, [], 'nothing uploaded to CPAN';
  ok -f $docs->child('DZT-Sample-0.001.tar.gz'), 'copied archive to local release dir';

  my $log = log_messages($tzil);
  note $_ for @$log;
  ok( (grep /% cp .*DZT-Sample-0\.001\.tar\.gz \Q$docs\E$/, @$log), 'logged copy command' );
  ok( (grep /download URL: http:\/\/dist\.wdlabs\.com\/.*DZT-Sample-0\.001\.tar\.gz/, @$log), 'logged download URL' );

  $docs->remove_tree;

};

subtest 'cpan = 0, prefers ~/www/dist.wdlabs.com/docs' => sub {

  @uploaded = ();

  my $www = $home->child('www/dist.wdlabs.com/docs');
  my $dev = $home->child('dev/site-dist/docs');
  $_->mkpath for $www, $dev;

  my $tzil = tzil( cpan => 0 );

  $tzil->release;

  is \@uploaded, [], 'nothing uploaded to CPAN';
  ok -f $www->child('DZT-Sample-0.001.tar.gz'), 'copied archive to ~/www/dist.wdlabs.com/docs';
  ok !-e $dev->child('DZT-Sample-0.001.tar.gz'), 'not copied to ~/dev/site-dist/docs';

  my $log = log_messages($tzil);
  note $_ for @$log;
  ok( (grep /% cp .*DZT-Sample-0\.001\.tar\.gz \Q$www\E$/, @$log), 'logged copy command' );
  ok( (grep /don't forget to commit and push \Q$www\E$/, @$log), 'logged commit reminder' );

  $home->child('www')->remove_tree;
  $home->child('dev')->remove_tree;

};

subtest 'cpan = 0, copy fails' => sub {

  skip_all 'test requires non-root unix' if $^O eq 'MSWin32' || $> == 0;

  my $www = $home->child('www/dist.wdlabs.com/docs');
  $www->mkpath;
  chmod 0555, $www;

  my $tzil = tzil( cpan => 0 );

  # cp is expected to fail here, keep its error message out of the test output
  my $error;
  my($stderr, $ok) = capture_stderr {
    my $ok = lives { $tzil->release };
    $error = $@;
    $ok;
  };
  note $stderr;

  ok $ok, 'release does not die' or note $error;

  ok !-e $www->child('DZT-Sample-0.001.tar.gz'), 'archive not copied';

  my $log = log_messages($tzil);
  note $_ for @$log;
  ok( (grep /NOTE COPY FAILED: exited with status [1-9]/, @$log), 'logged copy failure' );
  ok( (grep /manual upload will be required/, @$log), 'logged manual upload' );
  ok( !(grep /don't forget|download URL/, @$log), 'did not log success' );

  chmod 0755, $www;
  $home->child('www')->remove_tree;

};

subtest 'cpan = 0, no local release directory' => sub {

  @uploaded = ();

  my $tzil = tzil( cpan => 0, url => 'http://example.test/' );

  # should not even ask
  $tzil->chrome->set_response_for('upload to CPAN?' => 'y');

  ok no_warnings { $tzil->release }, 'no warnings';

  is \@uploaded, [], 'nothing uploaded to CPAN';

  my $log = log_messages($tzil);
  note $_ for @$log;
  ok( (grep /no release process available, upload tarball manually/, @$log), 'logged no release process' );
  ok( !(grep /^%|don't forget|download URL/, @$log), 'no copy attempted' );

};

done_testing;
