# included from MakeMaker_header.pl

use Config;
use Env;

if ($Config{ivsize} < 8 || $Config{uvsize} < 8) {
    die "Lab::Zhinst needs a perl with 64-bit integer support.\n" .
        "Make sure that perl has use64bitint defined."
}

my $os = $Config{osname};
my $arch = $Config{ptrsize} >= 8 ? '64' : '32';

my $libs = '';
my $inc = '-I. ';

if ($os eq 'linux') {
    my @lib_dirs;
    my $library_path = $ENV{LIBRARY_PATH};
    if ($library_path) {
        @lib_dirs = (split ':', $library_path);
        @lib_dirs = map "-L$_", @lib_dirs;
        $libs  .= join ' ', @lib_dirs;
    }
    
    $libs .= " -lziAPI-linux${arch}";
}
elsif ($os eq 'MSWin32') {
    $libs = '"-lC:\\Program Files\\Zurich Instruments\\LabOne\\API\\C\\lib\\'
        . "ziAPI-win${arch}.lib" . '"';
    $inc .=
        '"-IC:\\Program Files\\Zurich Instruments\\LabOne\\API\\C\\include"';
}
else {
    die "Unknown os $os";
}

my $ccflags = '-Wall -Wno-deprecated-declarations';

# end of MakeMaker_header.pl
