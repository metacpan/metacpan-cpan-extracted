#!/usr/bin/env perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict; use warnings;
use Test::More;
use Test::DZil;
use File::Temp qw(tempdir);
use App::cpanminus ();
use Dist::Zilla::Path;
use Capture::Tiny qw(capture);

BEGIN {
  my ($stdout, undef, $exit) = capture { system(qw(hello --version)) };
  if( $exit != 0 && $stdout !~ /GNU Hello/ ) {
    plan skip_all => 'GNU Hello not installed on system';
  }
}

sub builder_factory {
  my (%args) = @_;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ '@Alien' => {
            repo => 'https://ftp.gnu.org/gnu/hello/',
            name => 'hello',
            version_check => q{hello --version | %x -ne 'print $1 if /\Qhello (GNU Hello) \E([0-9.]+)$/'},
            @{ $args{alien} || [] }
          } ],
        ),
        %{ $args{files} || {} },
      },
    }
  );
}

sub compare_bin_dir {
  my ($install_path, $bins) = @_;
  my $bin_path = path($install_path)->child('bin');
  if( @$bins == 0 ) {
    ok( ! -d $bin_path || $bin_path->children == 0, 'no wrappers') or diag(
      $bin_path->children
    );
  } else {
    is_deeply
      [ sort map { $_->relative($bin_path) }
        $bin_path->children ],
      [ sort @$bins ],
      'has expected wrappers';
  }
}

sub is_module_build_class {
  my ($tzil, $mb_class) = @_;
  my ($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is $plugin->mb_class, $mb_class, "Module::Build subclass is $mb_class";
}

sub install {
  my ($tzil) = @_;

  $tzil->build;
  my $build_dir = path($tzil->tempdir)->child('build');

  my $locallib = tempdir( CLEANUP => 1 );
  my ($stdout, $stderr, $exit) = capture {
    delete local $ENV{AUTHOR_TESTING};
    system( $^X, qw(-S cpanm),
      qw(-nq),
      qw(--installdeps),
      qw(-l), $locallib,
      $build_dir );
    system( $^X, qw(-S cpanm),
      qw(--verbose),
      qw(-l), $locallib,
      $build_dir );
  };

  ok $exit == 0, 'installed' or diag( $stdout, $stderr );

  return $locallib;
}

use constant {
  MB_AB => 'Alien::Base::ModuleBuild',
  MB_CUSTOM => 'MyModuleBuild',
};

subtest 'setting bins and mb_class fails' => sub {
  my $tzil = builder_factory( alien => [
    bins => 'hello',
    mb_class => 'HelloBuilder',
  ] );
  eval { $tzil->build; 1 };
  my $err = $@;
  like $err, qr/Unable to set custom subclass/, 'error thrown';
};

subtest 'system install with bins (2)' => sub {
  local $ENV{ALIEN_INSTALL_TYPE} = 'system';
  my $tzil = builder_factory( alien => [ bins => 'hello hola' ] );
  is_module_build_class( $tzil, MB_CUSTOM );
  my $install_path = install( $tzil );
  compare_bin_dir( $install_path, [] );
};

subtest 'share install with bins (1)' => sub {
  local $ENV{ALIEN_INSTALL_TYPE} = 'share';
  my $tzil = builder_factory( alien => [ bins => 'hello' ] );
  is_module_build_class( $tzil, MB_CUSTOM );
  my $install_path = install( $tzil );
  compare_bin_dir( $install_path, [ 'hello' ] );
};

subtest 'share install with bins (2)' => sub {
  local $ENV{ALIEN_INSTALL_TYPE} = 'share';
  my $tzil = builder_factory( alien => [ bins => 'hello hola' ] );
  is_module_build_class( $tzil, MB_CUSTOM );
  my $install_path = install( $tzil );
  compare_bin_dir( $install_path, [ qw(hello hola) ] );
};

subtest 'share install without bins (0)' => sub {
  local $ENV{ALIEN_INSTALL_TYPE} = 'share';
  my $tzil = builder_factory();
  is_module_build_class( $tzil, MB_AB );
  my $install_path = install( $tzil );
  compare_bin_dir( $install_path, [] );
};

subtest 'system install with bins (1) but also non-wrapper bin' => sub {
  local $ENV{ALIEN_INSTALL_TYPE} = 'system';
  my $tzil = builder_factory( alien => [ bins => 'hello' ], files => { path('source/bin/goodbye') => '' }  );
  is_module_build_class( $tzil, MB_CUSTOM );
  my $install_path = install( $tzil );
  compare_bin_dir( $install_path, [ 'goodbye' ] );
};

subtest 'share install with bins (1) but also non-wrapper bin' => sub {
  local $ENV{ALIEN_INSTALL_TYPE} = 'share';
  my $tzil = builder_factory( alien => [ bins => 'hello' ], files => { path('source/bin/goodbye') => '' }  );
  is_module_build_class( $tzil, MB_CUSTOM );
  my $install_path = install( $tzil );
  compare_bin_dir( $install_path, [ qw(hello goodbye) ] );
};

done_testing;
