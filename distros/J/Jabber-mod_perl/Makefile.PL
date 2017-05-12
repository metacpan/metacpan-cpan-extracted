$|++;
use ExtUtils::MakeMaker;
use ExtUtils::Embed;

use Cwd qw(abs_path); 
use File::Copy;
use File::Path;
use Carp;
use Config;


my $jdefault = "../jabberd2/";
print "\nPlease enter the directory of your jabberd2 source code: [$jdefault] ";
my $jabberdir = <>;
chomp $jabberdir;
$jabberdir ||= $jdefault;
$jabberdir = abs_path($jabberdir) || die "directory $jabberdir does not exist - $!\n";
warn "\njabberd2 directory is: $jabberdir ...\n";

#my $confdefaults = "--with-jabberd-parts=\"c2s resolver router sm jadperl\" --enable-debug --prefix=/home/jabber/jabberd";
my $confdefaults = "--with-jabberd-parts=\"s2s c2s resolver router sm\" --enable-debug --prefix=/home/jabber/jabberd --enable-db --disable-idn --disable-mysql";
print "\nPlease enter the parameters to be passed to configure: [$confdefaults] ";
my $conf = <>;
chomp $conf;
$conf ||= $confdefaults;


# clean down the source code directory
#my $clean = -f $jabberdir."/Makefile.am" ? " make distclean " : "make clean";
my $clean = " make distclean\; make clean";
my $cmd = "cd $jabberdir; $clean ";
warn "\n\nExecuting $cmd\n  To clean jabberd.\n";
system("$cmd");


# copy in mod_perl and then patch sm to include it
my $patchesdir = abs_path("./patches") || die "cant determine the patches directory (./patches) - $!\n";

die "no mod_perl.c \n" unless -f $patchesdir.'/mod_perl.c';
die "no mod_perl.h \n" unless -f $patchesdir.'/mod_perl.h';
warn "Patch directory is: $patchesdir ...\n";
warn "removing old mod_perl.c ...\n" if unlink("$jabberdir/sm/mod_perl.c");
warn "removing old mod_perl.h ...\n" if unlink("$jabberdir/sm/mod_perl.h");
my $jadperldir = $jabberdir."/jadperl";
if (-d $jadperldir){
  warn "removing old jadperl directory $jadperl ...\n";
  rmtree($jabberdir."/jadperl") || die "could not remove existing jadperl directory - $jadperldir - $! \n";
}
copy("$patchesdir/mod_perl.c","$jabberdir/sm/mod_perl.c") 
       || die "can't copy mod_perl.c to sm directory - $!\n";
copy("$patchesdir/mod_perl.h","$jabberdir/sm/mod_perl.h") 
       || die "can't copy mod_perl.h to sm directory - $!\n";
#mkpath($jabberdir."/jadperl") || die "cant make path $jabberdir/jadperl \n";
#
#warn "Copying files from $patchesdir/jadperl to $jadperldir ... \n";
#my @files = glob("$patchesdir/jadperl/*");
#map { copy($_, $jadperldir."/") || die "cant copy $_ to $jadperldir - $!\n"; } grep {-f } @files;
#
#die "$jadperldir not created correctly \n" 
#  unless -f $jadperldir."/jadperl.c";

my $Mfile =  "$jabberdir/sm/Makefile.am";
warn "patching $Mfile ...\n";
die "$Mfile does not exist\n" unless -f $Mfile;
open (PAT, "<$Mfile") || die "Cannot read $Mfile - $! \n";
my $mf = join("",grep(!/(perlxsi|mod_perl|Jabber_pkt|Jabber_NADs)/,(<PAT>)));
close PAT;
$mf =~ s/(\s+mod_echo.c\s+\\)/$1\n             perlxsi.c \\\n             mod_perl.c \\\n             Jabber_pkt.c \\\n             Jabber_NADs.c \\/s;
open (PAT, ">$Mfile") || die "Cannot write to $Mfile - $! \n";
print PAT $mf;
close PAT;


my $mmfile =  "$jabberdir/sm/mm.c";
warn "patching $mmfile ...\n";
die "$mmfile does not exist\n" unless -f $mmfile;
open (PAT, "<$mmfile") || die "Cannot read $mmfile - $! \n";
my $mm = join("",grep(!/mod_perl/,(<PAT>)));
close PAT;
# put in the function definition for mod_perl_init()
$mm =~ s/(extern int .*?\n\n)/extern int mod_perl_init\(mod_instance_t\)\;\n$1/s;
# add mod_perl to the module names list
$mm =~ s/(char\s+\*module_names\[\]\s+.*?\{)/$1\n    \"mod_perl\"\,/s;
# specify the mod_perl_init() function
$mm =~ s/(module_init_fn\s+module_inits\[\]\s+.*?\{)/$1\n    mod_perl_init\,/s;
open (PAT, ">$mmfile") || die "Cannot write to $mmfile - $! \n";
print PAT $mm;
close PAT;


# patch the configure.in file
my $cfile =  "$jabberdir/configure.in";
warn "patching $cfile ...\n";
die "$cfile does not exist\n" unless -f $cfile;
open (PAT, "<$cfile") || die "Cannot read $cfile - $! \n";
my $conffile = join("",grep(!/mod_perl/,(<PAT>)));
close PAT;
# put in the function definition for mod_perl_init()
#$conffile =~ s/(JABBERD_SUBDIRS=\")(.*?)("\n)/$1c2s resolver router sm jadperl$3/s;
$conffile =~ s/(JABBERD_SUBDIRS=\")(.*?)("\n)/$1c2s resolver router sm$3/s;
#$conffile =~ s/(parts to build default: \")(.*?\")/$1c2s resolver router sm jadperl\"/s;
$conffile =~ s/(parts to build default: \")(.*?\")/$1c2s resolver router sm\"/s;
#$conffile =~ s/(AC_OUTPUT\(Makefile .*?sm\/Makefile)(.*?\))/$1 \\\n          jadperl\/Makefile\)/s;
open (PAT, ">$cfile") || die "Cannot write to $cfile - $! \n";
print PAT $conffile;
close PAT;


# create Jabber_pkt.c from XS file
# /usr/bin/perl -I/usr/lib/perl5/5.6.1/i386-linux -I/usr/lib/perl5/5.6.1 /usr/lib/perl5/5.6.1/ExtUtils/xsubpp  -typemap /usr/lib/perl5/5.6.1/ExtUtils/typemap pkt.xs > pkt.xsc && mv pkt.xsc pkt.c

my $perl = $Config{'perlpath'};
my $xsubdir = $Config{'privlibexp'}.'/ExtUtils';
my $xsubpp = $xsubdir.'/xsubpp';
my $typemap = $xsubdir.'/typemap';
my $targetpkt = $jabberdir.'/sm/Jabber_pkt.c';
my $targetnad = $jabberdir.'/sm/Jabber_NADs.c';
my $targetxsi = $jabberdir.'/sm/perlxsi.c';

# remove the old file
warn "removing old $targetpkt ...\n" if unlink($targetpkt);
warn "removing old $targetnad ...\n" if unlink($targetnad);
warn "removing old $targetxsi ...\n" if unlink($targetxsi);

# create Jabber_pkt.c from XS file
my $xsubppcmd = $perl.' -I'.$Config{'archlib'}.' -I'.$Config{'privlibexp'}.' '.$xsubpp.' -typemap '.$typemap.' patches/pkt.xs > pkt.xsc && mv pkt.xsc '.$targetpkt;
warn "\n\nExecuting $xsubppcmd\n  To create Jabber_pkt.c from pkt.xs.\n";
system("$xsubppcmd");
die "Failed to create Jabber_pkt.c !\n" unless -f $targetpkt;

# create Jabber_NADs.c from XS file
my $xsubppcmd = $perl.' -I'.$Config{'archlib'}.' -I'.$Config{'privlibexp'}.' '.$xsubpp.' -typemap '.$typemap.' patches/NADs.xs > NADs.xsc && mv NADs.xsc '.$targetnad;
warn "\n\nExecuting $xsubppcmd\n  To create Jabber_NADs.c from NADs.xs.\n";
system("$xsubppcmd");
die "Failed to create Jabber_NADs.c !\n" unless -f $targetnad;


# create perlxsi.c as per /usr/bin/perl -MExtUtils::Embed -e xsinit -- -std -o
my $perlxsicmd = $perl.' -MExtUtils::Embed -e xsinit -- -std -o STDOUT > perlxsi.c && mv perlxsi.c '.$targetxsi;
warn "\n\nExecuting $perlxsicmd\n  To create perlxsi.c.\n";
system("$perlxsicmd");
die "Failed to create perlxsi.c !\n" unless -f $targetxsi;


## do it all again for jadperl
#my $targetpkt = $jabberdir.'/jadperl/Jabber_pkt.c';
#my $targetnad = $jabberdir.'/jadperl/Jabber_NADs.c';
#my $targetxsi = $jabberdir.'/jadperl/perlxsi.c';
#
## remove the old file
#warn "removing old $targetpkt ...\n" if unlink($targetpkt);
#warn "removing old $targetnad ...\n" if unlink($targetnad);
#warn "removing old $targetxsi ...\n" if unlink($targetxsi);
#
## create Jabber_pkt.c from XS file
#my $xsubppcmd = $perl.' -I'.$Config{'archlib'}.' -I'.$Config{'privlibexp'}.' '.$xsubpp.' -typemap '.$typemap.' patches/jadperl_pkt.xs > pkt.xsc && mv pkt.xsc '.$targetpkt;
#warn "\n\nExecuting $xsubppcmd\n  To create Jabber_pkt.c from jadperl_pkt.xs.\n";
#system("$xsubppcmd");
#die "Failed to create Jabber_pkt.c !\n" unless -f $targetpkt;
#
## create Jabber_NADs.c from XS file
#my $xsubppcmd = $perl.' -I'.$Config{'archlib'}.' -I'.$Config{'privlibexp'}.' '.$xsubpp.' -typemap '.$typemap.' patches/NADs.xs > NADs.xsc && mv NADs.xsc '.$targetnad;
#warn "\n\nExecuting $xsubppcmd\n  To create Jabber_NADs.c from jadperl_NADs.xs.\n";
#system("$xsubppcmd");
#die "Failed to create Jabber_NADs.c !\n" unless -f $targetnad;
#
#
## create perlxsi.c as per /usr/bin/perl -MExtUtils::Embed -e xsinit -- -std -o
#my $perlxsicmd = $perl.' -MExtUtils::Embed -e xsinit -- -std -o STDOUT > perlxsi.c && mv perlxsi.c '.$targetxsi;
#warn "\n\nExecuting $perlxsicmd\n  To create perlxsi.c.\n";
#system("$perlxsicmd");
#die "Failed to create perlxsi.c !\n" unless -f $targetxsi;



my $CFLAGS = ccopts();
my $LDFLAGS = ldopts();
chomp($CFLAGS,$LDFLAGS);

my $cmd = "cd $jabberdir; ./bootstrap;  libtoolize --force && aclocal $ENV{ACLOCAL_FLAGS} && autoheader && automake --include-deps --add-missing && autoconf; CFLAGS=\'$CFLAGS $ENV{CFLAGS}\' LDFLAGS=\'$LDFLAGS $ENV{LDFLAGS}\' ./configure $conf && make";
#my $cmd = "cd $jabberdir; CFLAGS=\'$CFLAGS $ENV{CFLAGS}\' LDFLAGS=\'$LDFLAGS $ENV{LDFLAGS}\' ./configure $conf && make";

# now for the big kick off
warn "\n\nExecuting $cmd\n  To build jabberd.\n";
system("$cmd");
die "jabberd2 build failed!\n" unless -x $jabberdir."/sm/sm";


my ($LIBS, $INCS, $DEFINE);

$LIBS = "-L".$jabberdir."/util -lutil";
$INCS = "-I".$jabberdir."/util";

$ENV{'JABBERDIR'} = $jabberdir;

WriteMakefile(
    clean => { 'FILES'  => '*~ *.inl core test*.txt *.tar.gz _Inline ' },
    dist => { 'TARFLAGS'        => 'cvf',
              'COMPRESS'        => 'gzip -9f',
                'SUFFIX'        => '.tgz'},
    'NAME'      => 'Jabber::mod_perl',
    'VERSION_FROM' => 'mod_perl.pm',
    'DEFINE'	=> $DEFINE,   
    'LIBS'	=> $LIBS,   
    'INC'	=> $INCS,
);

