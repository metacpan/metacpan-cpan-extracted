use strict;
use warnings;
use Test::More;
use File::ShareDir::Dist::Install;
use File::Temp qw( tempdir );
use Cwd qw( getcwd );

my $orig = getcwd;

subtest 'install_dir' => sub {

  chdir tempdir( CLEANUP => 1 );

  eval { install_dir };
  like $@, qr/Not a valid dist_name: undef/;

  eval { install_dir 'Foo::Bar::Baz' };
  like $@, qr/Not a valid dist_name: Foo::Bar::Baz/;

  my $dir = install_dir 'Foo-Bar-Baz';
  ok $dir, 'returns a directory';
  note "dir = $dir";
  ok !-d $dir, 'directory not created';

};

subtest 'install_config_* (full config)' => sub {

  chdir tempdir( CLEANUP => 1 );

  my $dir = install_dir 'Foo-Bar-Baz';

  my $config = install_config_get 'Foo-Bar-Baz';
  ok !-d $dir, 'directory created';
  is_deeply($config, {});
  
  install_config_set 'Foo-Bar-Baz' => { key1 => 'val1', key2 => 'val2' };
  ok -d $dir, 'directory created';

  $config = install_config_get 'Foo-Bar-Baz';
  is_deeply $config, { key1 => 'val1', key2 => 'val2' };

  install_config_set 'Foo-Bar-Baz' => { key3 => 'val3', key4 => 'val4' };

  $config = install_config_get 'Foo-Bar-Baz';
  is_deeply $config, { key3 => 'val3', key4 => 'val4' };

};

subtest 'install_config_* (key/value)' => sub {

  chdir tempdir( CLEANUP => 1 );
  my $dir = install_dir 'Foo-Bar-Baz';

  install_config_set 'Foo-Bar-Baz', key5 => 'val5';
  ok -d $dir, 'directory created';

  my $config = install_config_get 'Foo-Bar-Baz';
  is_deeply $config, { 'key5' => 'val5' };

  install_config_set 'Foo-Bar-Baz', key6 => 'val6';

  $config = install_config_get 'Foo-Bar-Baz';
  is_deeply $config, { 'key5' => 'val5', 'key6' => 'val6' };

};

subtest 'install_config_* (key/value) @ARGV' => sub {

  chdir tempdir( CLEANUP => 1 );
  my $dir = install_dir 'Foo-Bar-Baz';

  {
    local @ARGV = ('Foo-Bar-Baz', key5 => 'val5');
    install_config_set;
  }
  ok -d $dir, 'directory created';

  my $config = install_config_get 'Foo-Bar-Baz';
  is_deeply $config, { 'key5' => 'val5' };

};

sub create_faux_share
{
  mkdir 'share';
  mkdir 'share/blarpho1';

  my $fn = 'share/blarpho1.txt';
  my $fh;
  open $fh, '>', $fn;
  print $fh "blarpho1\n";
  close $fh;

  $fn = 'share/blarpho1/blarpho2.txt';
  open $fh, '>', $fn;
  print $fh "blarpho2\n";
  close $fh;
}

subtest 'install' => sub {

  chdir tempdir( CLEANUP => 1 );

  eval { install };
  like $@, qr/No such directory: undef/;

  eval { install 'missing' };
  like $@, qr/No such directory: missing/;

  create_faux_share;

  eval { install 'share' };
  like $@, qr/Not a valid dist_name: undef/;

  eval { install 'share', 'Foo::Bar::Baz' };
  like $@, qr/Not a valid dist_name: Foo::Bar::Baz/;

  install 'share', 'Foo-Bar-Baz';

  ok -f 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1.txt';
  ok -f 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1/blarpho2.txt';

  my $blarpho1 = do {
    open my $fh, '<', 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1.txt';
    local $/;
    <$fh>;
  };

  my $blarpho2 = do {
    open my $fh, '<', 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1/blarpho2.txt';
    local $/;
    <$fh>;
  };

  is $blarpho1, "blarpho1\n";
  is $blarpho2, "blarpho2\n";

};

subtest 'install @ARGV' => sub {

  chdir tempdir( CLEANUP => 1 );

  create_faux_share;

  {
    local @ARGV = ('share', 'Foo-Bar-Baz');
    install;
  }

  ok -f 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1.txt';
  ok -f 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1/blarpho2.txt';

  my $blarpho1 = do {
    open my $fh, '<', 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1.txt';
    local $/;
    <$fh>;
  };

  my $blarpho2 = do {
    open my $fh, '<', 'blib/lib/auto/share/dist/Foo-Bar-Baz/blarpho1/blarpho2.txt';
    local $/;
    <$fh>;
  };

  is $blarpho1, "blarpho1\n";
  is $blarpho2, "blarpho2\n";
};

chdir $orig;

done_testing;
