use strict;
use warnings;
use lib 'inc';
use Devel::AssertOS qw(Unix OS390 BeOS Cygwin);
use Config;
use ExtUtils::MakeMaker;

my $binpath = 'mm-config';
if (system "which $binpath>/dev/null") {

    # mm-config is not in PATH, but maybe it's installed outside PATH
    print "$binpath not in PATH: trying to find it...\n";
    my $found;
    DIR: for ('/usr', glob("~")) {
        my $result = `find $_ -maxdepth 6 -name "$binpath" 2>/dev/null`;
        while ($result =~ m"^(\S*?/$binpath)$"mg) {
            if ($found = -X $1) {$binpath = $1; last DIR}
    }   }
    if (!$found) {
        print "IPC::MMA requires the mm library, including its $binpath utility\n";
        $binpath = prompt("Please enter path to $binpath (or just return to quit):");
        chomp $binpath;
        $binpath =~ s"(.)(/(mm-config)?)?$"$1/mm-config";

        if (!$binpath || !-e $binpath || !-X $binpath) {
            if ($binpath) {warn "'${binpath}' not found or not executable\n"}
            warn "The mm library is available at http://www.ossp.org/pkg/lib/mm/\n";
            exit 0;
}   }   }
# mm-config provides parameters to link with the mm library
my $cflags = `$binpath --cflags`;
my $libs   = `$binpath --ldflags --libs`;
chomp ($cflags, $libs);

# check further
if ($cflags !~ /-I(.+)/) {
    warn "Your system includes a file named 'mm-config', but it doesn't\n",
         " act like the utility that's installed with the mm library.\n",
         "Please install the mm library from http://www.ossp.org/pkg/lib/mm/\n";
    exit 0;
}
if (!-e "$1/mm.h") {
    warn "The file 'mm.h' is not in directory '${1}', as it should be from ",
         " the installation of the mm library.\n",
         "Please (re-)install the mm library from http://www.ossp.org/pkg/lib/mm/\n";
    exit 0;
}
my @optional = ();
my $errwarn = qr/(^|\b)(warning|error)(\b|$)/im;

# test cc optimize by size (OK in gcc, possibly others)
#   make this ('-g') for debugging 
for my $opt ('-Os', '-O2', $Config{'optimize'}) {
    if (!$opt) {last}
    $_ = `$Config{'cc'} -c $opt test.c 2>&1`;
    if (!/$errwarn/) {
        @optional = ('OPTIMIZE' => $opt);
        last;
}   }

# see if cc can handle 'inline' keyword
$_ = `$Config{'cc'} -c test_inline.c 2>&1`;
if (/$errwarn/) {
    # no: turn 'inline's into comments
    push (@optional, "DEFINE" => "-Dinline='/* Inline */'");
}
unlink('test.o', 'test_inline.o');

# see perldoc ExtUtils::MakeMaker for details of WriteMakefile options

WriteMakefile(
    'NAME'              => 'IPC::MMA',
    'ABSTRACT_FROM'     => 'MMA.pod',
    'AUTHOR'            => 'Craig MacKenna <craig@animalhead.com>',
    'CONFIGURE_REQUIRES'=> {'Config'             =>0,
                            'Devel::AssertOS'    =>0,
                            'ExtUtils::MakeMaker'=>'6.52'},
    'INC'               => $cflags,       # e.g., '-I/usr/include/other'
    'LIBS'              => [$libs],       # e.g., '-lm'
    'LICENSE'           => 'perl',
    'OBJECT'            => 'mma_alloc.o MMA.o',
    'PREREQ_PM'         => {'Carp'             =>0,
                            'ExtUtils::ParseXS'=>'2.200401',
                            'Test::More'       =>0,
                            'Test::Warn'       =>'0.11',
                            'Time::HiRes'      =>0},
    'VERSION_FROM'      => 'MMA.pm',      # finds $VERSION
    @optional);
