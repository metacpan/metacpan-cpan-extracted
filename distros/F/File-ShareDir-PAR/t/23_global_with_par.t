#!/usr/bin/perl
use Cwd qw(cwd realpath);
use strict;
BEGIN {
  $|  = 1;
  $^W = 1;

  require Test::More;
  my $got_par = eval { require PAR; };
  if ($got_par) {
    my $v = PAR->VERSION;
    if (eval "$v+0" >= 0.983) {
      Test::More->import(tests => 29);
    }
    else {
      Test::More->import(skip_all => "Need PAR 0.983 for these tests. This is only $v.");
    }
  }
  else {
    Test::More->import(skip_all => 'Need PAR 0.983 for these tests');
  }

}

use vars ('$PARFILE');
BEGIN {
  # generate the .par file:
  require PAR::Dist;
  if (!-d 't') {
    chdir(File::Spec::updir());
  }
  $PARFILE = PAR::Dist::blib_to_par(name => "T", version => "1.00", quiet => 1);
  ok(-f $PARFILE, 'PAR was generated');
  require PAR;
  PAR->import($PARFILE);
  # remove blib/lib from @INC, but:
  # - make sure we only remove those in our cwd! (or else CPAN testers fail)
  # - do not remove the cwd itself or "use t::lib::..." doesn't work any more.
  my $cwd = quotemeta(realpath(cwd()));
  @INC = grep {
    if (!ref($_)) {
      my $path = eval{realpath($_)};
      $path = $_ if $@ or not defined $path;
      not /^(?:\.\\|\.\/)?blib\b/
        and
      not $path =~ /^$cwd(?:\\|\/).+/
    } else { 1 }
  } @INC;
}

END {
  unlink($PARFILE) if defined $PARFILE;
}

use File::ShareDir::PAR 'global';
my $partmp = $ENV{PAR_TEMP};
ok($INC{'File/ShareDir/PAR.pm'} =~ /^\Q$partmp\E/i, 'F::SD::PAR most likely loaded from .par as expected.');

sub dies {
	my $code    = shift;
	my $message = shift || 'Code dies as expected';
	my $rv      = eval { &$code() };
	ok( $@, $message );
}

# Print the contents of @INC
#diag("\@INC = qw{");
#foreach ( @INC ) {
#	diag("    $_");
#}
#diag("    }");




#####################################################################
# Loading and Importing

# Don't import by default
ok( ! defined &dist_dir,    'dist_dir not imported by default'    );
ok( ! defined &module_dir,  'module_dir not imported by default'  );
ok( ! defined &dist_file,   'dist_file not imported by default'   );
ok( ! defined &module_file, 'module_file not imported by default' );
ok( ! defined &class_file,  'class_file not imported by default'  );
use_ok( 'File::ShareDir', ':ALL' );

# Import as needed
ok( defined &dist_dir,    'dist_dir imported'    );
ok( defined &module_dir,  'module_dir imported'  );
ok( defined &dist_file,   'dist_file imported'   );
ok( defined &module_file, 'module_file imported' );
ok( defined &class_file,  'class_file imported'  );


#####################################################################
# Module Tests

my $module_dir = module_dir('File::ShareDir::PAR');
ok( $module_dir, 'Can find our own module dir' );
ok( -d $module_dir, '... and is a dir' );
ok( -r $module_dir, '... and have read permissions' );

dies( sub { module_dir() }, 'No params to module_dir dies' );
dies( sub { module_dir('') }, 'Null param to module_dir dies' );
dies( sub { module_dir('File::ShareDir::Bad') }, 'Getting module dir for known non-existanct module dies' );

my $module_file = module_file('File::ShareDir::PAR', 'test_file.txt');
ok( -f $module_file, 'module_file ok' );





#####################################################################
# Distribution Tests

my $dist_dir = dist_dir('File-ShareDir-PAR');
ok( $dist_dir, 'Can find our own dist dir' );
ok( -d $dist_dir, '... and is a dir' );
ok( -r $dist_dir, '... and have read permissions' );

my $dist_file = dist_file('File-ShareDir-PAR', 'sample.txt');
ok( $dist_file, 'Can find our sample module file' );
ok( -f $dist_file, '... and is a file' );
ok( -r $dist_file, '... and have read permissions' );

# Make sure the directory in dist_dir, matches the one from dist_file
# Bug found in Module::Install 0.54, fixed in 0.55
is( File::Spec->catfile($dist_dir, 'sample.txt'), $dist_file,
	'dist_dir and dist_file find the same directory' );





#####################################################################
# Class Tests

use t::lib::ShareDir;
my $class_file = class_file('t::lib::ShareDir', 'test_file.txt');
ok( -f $class_file, 'class_file ok' );
is( $class_file, $module_file, 'class_file matches module_file for subclass' );

