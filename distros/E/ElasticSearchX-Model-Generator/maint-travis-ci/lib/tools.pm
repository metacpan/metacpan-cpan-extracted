use strict;
use warnings;

package tools;

use Cwd qw(cwd);
use Config;

sub diag {
  my $handle = \*STDERR;
  for (@_) {
    print {$handle} $_;
  }
  print {$handle} "\n";
}

sub env_exists {
  return exists $ENV{ $_[0] };
}

sub env_true {
  return ( env_exists( $_[0] ) and $ENV{ $_[0] } );
}
sub env_is { return ( env_exists( $_[0] ) and $ENV{ $_[0] } eq $_[1] ) }

sub safe_exec_nonfatal {
  my ( $command, @params ) = @_;
  diag("running $command @params");
  my $exit = system( $command, @params );
  if ( $exit != 0 ) {
    my $low  = $exit & 0b11111111;
    my $high = $exit >> 8;
    warn "$command failed: $? $! and exit = $high , flags = $low";
    if ( $high != 0 ) {
      return $high;
    }
    else {
      return 1;
    }

  }
  return 0;
}

sub safe_exec {
  my ( $command, @params ) = @_;
  my $exit_code = safe_exec_nonfatal( $command, @params );
  if ( $exit_code != 0 ) {
    exit $exit_code;
  }
  return 1;
}

sub cpanm {
  my (@params) = @_;
  my $exit_code = safe_exec_nonfatal( 'cpanm', @params );
  if ( $exit_code != 0 ) {
    safe_exec( 'tail', '-n', '200', '/home/travis/.cpanm/build.log' );
    exit $exit_code;
  }
  return 1;
}

sub git {
  my (@params) = @_;
  safe_exec( 'git', @params );
}

my $got_fixes;

sub get_fixes {
  return if $got_fixes;
  my $cwd = cwd();
  chdir '/tmp';
  safe_exec( 'git', 'clone', 'https://github.com/kentfredric/cpan-fixes.git' );
  chdir $cwd;
  $got_fixes = 1;
}

my $got_sterile;

sub get_sterile {
  return if $got_sterile;
  my $cwd = cwd();
  chdir '/tmp';
  my $version = $];
  safe_exec(
    'git', 'clone', '--depth=1',
    '--branch=' . $version,
    'https://github.com/kentfredric/perl5-sterile.git',
    'perl5-sterile'
  );
  chdir $cwd;
  $got_sterile = 1;
}
my $fixed_up;

sub fixup_sterile {
  return if $fixed_up;
  get_sterile();
  my $cwd = cwd();
  chdir '/tmp/perl5-sterile';
  safe_exec( 'bash', 'patch_fixlist.sh', '/home/travis/perl5/perlbrew/perls/' . $ENV{TRAVIS_PERL_VERSION} );
  chdir $cwd;
  $fixed_up = 1;
}
my $sterile_deployed;

sub deploy_sterile {
  return if $sterile_deployed;
  fixup_sterile();
  for my $key ( keys %Config ) {
    next unless $key =~ /(lib|arch)exp$/;
    my $value = $Config{$key};
    next unless defined $value;
    next unless length $value;
    my $clean_path = '/tmp/perl5-sterile/' . $key;
    diag("\e[32m?$clean_path\e[0m");
    if ( -e $clean_path and -d $clean_path ) {
      diag("\e[31mRsyncing over $value\e[0m");
      $clean_path =~ s{/?$}{/};
      $value =~ s{/?$}{/};
      safe_exec( 'rsync', '-a', '--delete-delay', $clean_path, $value );
    }
  }
}

sub cpanm_fix {
  my (@params) = @_;
  get_fixes();
  my $cwd = cwd();
  chdir '/tmp/cpan-fixes';
  cpanm(@params);
  chdir $cwd;
}

sub parse_meta_json {
  $_[0] ||= 'META.json';
  require CPAN::Meta;
  return CPAN::Meta->load_file( $_[0] );
}

sub capture_stdout(&) {
  require Capture::Tiny;
  goto &Capture::Tiny::capture_stdout;
}

sub import {
  my ( $self, @args ) = @_;

  my $caller = [caller]->[0];

  my $caller_stash = do {
    no strict 'refs';
    *{ $caller . '::' };
  };

  $caller_stash->{diag}               = *diag;
  $caller_stash->{env_exists}         = *env_exists;
  $caller_stash->{env_true}           = *env_true;
  $caller_stash->{env_is}             = *env_is;
  $caller_stash->{safe_exec_nonfatal} = *safe_exec_nonfatal;
  $caller_stash->{safe_exec}          = *safe_exec;
  $caller_stash->{cpanm}              = *cpanm;
  $caller_stash->{git}                = *git;
  $caller_stash->{get_fixes}          = *get_fixes;
  $caller_stash->{cpanm_fix}          = *cpanm_fix;
  $caller_stash->{parse_meta_json}    = *parse_meta_json;
  $caller_stash->{capture_stdout}     = *capture_stdout;
  $caller_stash->{deploy_sterile}     = *deploy_sterile;
}

1;
