use strict;
use warnings;
use Capture::Tiny qw( capture capture_merged );
use File::ShareDir::Dist::Install qw( install_config_set );
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use FFI::Platypus;

my($out, $err, $exit) = capture {
  system 'go' ,'version';
};

unless($exit == 0)
{
  print "This dist requires Google Go to be installed";
  exit;
}

unless(caller)
{
  *File::ShareDir::Dist::Install::install_dir = sub {
    'share';
  };
}

my $dist = 'FFI-Platypus-Lang-Go';

{
  my($out, $err, $exit) = capture {
    system 'go' ,'version';
  };

  unless($exit == 0)
  {
    print "This dist requires Google Go to be installed";
    exit 2;
  }

  my($version, $arch) = $out =~ /go version (\S+) (\S+)/;

  print "Found go @{[ $version || '???' ]}\n";
  print "For arch @{[ $arch || '???' ]}\n";

  install_config_set $dist, go_version => $version;
  install_config_set $dist, go_arch    => $arch;
}

# TODO: gostring, goslice, gointerface

my %types = qw(
  goint8        sint8
  goint16       sint16
  goint32       sint32
  goint64       sint64
  gouint8       sint8
  gouint16      sint16
  gouint32      sint32
  gouint64      sint64
  gobyte        uint8
  gorune        sint32
  gofloat32     float
  gofloat64     double
  gomap         opaque
  gochan        opaque
);

{
  local $CWD = tempdir( CLEANUP => 1, DIR => '.' );
  path('simple.go')->spew(<<'EOF');
package main
import "C"
import "unsafe"

var mybool bool
//export SizeOfBool
func SizeOfBool() uintptr { return unsafe.Sizeof(mybool) }

var myint int
//export SizeOfInt
func SizeOfInt() uintptr { return unsafe.Sizeof(myint) }

var myuint uint
//export SizeOfUint
func SizeOfUint() uintptr { return unsafe.Sizeof(myuint) }

func main() {}
EOF

  my($out, $exit) = capture_merged {
    my @cmd = qw( go build -o simple.so -buildmode=c-shared simple.go );
    print "+ @cmd\n";
    system @cmd;
  };

  if($exit)
  {
    print "error building simple c-shared file\n";
    print $out;
    exit 2;
  }

  unless(-f 'simple.so')
  {
    print "Command returned success, but did not create a c-shared file\n";
    print $out;
    exit 2;
  }

  my $ffi = FFI::Platypus->new;
  $ffi->lib('./simple.so');

  $types{gobool}    = 'uint' . ($ffi->function( SizeOfBool => [] => 'size_t' )->call * 8);
  $types{goint}     = 'sint' . ($ffi->function( SizeOfInt => [] => 'size_t' )->call * 8);
  $types{gouint}    = 'uint' . ($ffi->function( SizeOfUint => [] => 'size_t' )->call * 8);
  $types{gouintptr} = 'uint' . ($ffi->sizeof('size_t')*8);

  if(eval { $ffi->sizeof('complex_float'); 1 })
  {
    $types{gocomplex64} = 'complex_float';
  }

  if(eval { $ffi->sizeof('complex_double'); 1 })
  {
    $types{gocomplex128} = 'complex_double';
  }
}

install_config_set $dist, go_types => \%types;
