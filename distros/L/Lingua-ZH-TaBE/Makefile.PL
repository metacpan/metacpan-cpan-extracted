use 5.005;
use Cwd;
use inc::Module::Install;

my @libs = grep defined, qw(
    /usr/local/lib
    /usr/lib
    /usr/X11R6/lib
    /usr/local/lib/tabe
    /usr/local/tabe/lib
    /usr/local/db/BerkeleyDB/lib
    /opt/local/lib
    /sw/local/lib
), Cwd::cwd(), $ENV{TABE_LIB};

die << '.' unless grep {<$_/tabe.*> or <$_/libtabe.*>} @libs;
This modules needs libtabe version 0.2.5 or above installed; please
install it from ftp://xcin.linux.org.tw/pub/xcin/libtabe/devel/ before
running Makefile.PL.

If you have installed LibTaBE but it is not under the current path,
try setting the TABE_LIB environment variable. 

.

my $db = 'db3';
if ($ARGV[0] =~ /^DB=(.+)/) {
    $db = $1;
    shift @ARGV;
}
else {
    print << '.';
Type "perl Makefile.PL DB=db2" if you want use DB2 (or DB=db4 for DB4),
Otherwise, TaBE.pm will be linked with DB3.

.
}

my @incs = @libs;
s!([/\\])lib\b!$1include!g for @incs;

name 'Lingua-ZH-TaBE';
all_from;

inc_paths @incs;
lib_paths @libs;
lib_links 'tabe', $db;

sign; WriteAll;
