use strict; use warnings;
use Cwd qw(chdir getcwd realpath);
use File::Basename qw(basename dirname);
use File::Copy;
use File::Path;    # Exports 'mkpath' and 'rmtree'
use Test::More tests => 17;
BEGIN
{
    use_ok('EBook::Tools',qw(:all));
};

# Set this to 1 or 2 to stress the debugging code, but expect lots of
# output.
$EBook::Tools::debug = 0;

my $result;
my $longline = 'We think ourselves possessed, or, at least, we boast that we are so, of liberty of conscience on all subjects, and of the right of free inquiry and private judgment in all cases, and yet how far are we from these exalted privileges in fact! -- John Adams';
my $hexable = "\x{0}\x{d0}\x{be}\x{d0}\x{be}\x{da}";
my $scriptname = basename($0);

my %selfhash = (
    '1'   => 'One',
    '2'   => 'Two',
    'One' => '1',
    'one' => 'Zero',
    'ONE' => 'Two',
   );
my %testhash;

########## TESTS BEGIN ##########

ok( (basename(getcwd()) eq 't') || chdir('t/'), "Working in 't/" ) or die;
rmtree('META-INF');

ok(find_in_path('perl'),'find_in_path("perl") finds perl');
is(find_in_path($scriptname,dirname(realpath($scriptname))),
   realpath($scriptname),
   'find_in_path(script,path) finds test script');
is(excerpt_line($longline),
   'We think ourselves possessed,  [...] vileges in fact! -- John Adams',
   'excerpt_line() excerpts correctly');

# Generate fresh input samples, test finding them
copy('testopf-emptyuid.xml','emptyuid.opf') or die("Could not copy: $!");
is(find_opffile(),'emptyuid.opf',
   'find_opffile() finds a single OPF');
copy('testopf-missingfwid.xml','missingfwid.opf') or die("Could not copy: $!");
is(find_opffile(),undef,
   'find_opffile() returns undef with multiple OPF files');

%testhash = %selfhash;
hashvalue_key_self(\%testhash);
is($testhash{'One'},'1','hashvalue_key_self/undef did not modify existing key');
is($testhash{'Two'},'Two','hashvalue_key_self/undef created self reference');

%testhash = %selfhash;
hashvalue_key_self(\%testhash,'lc');
is($testhash{'one'},'Zero','hashvalue_key_self/lc did not modify existing key');
is($testhash{'two'},'Two','hashvalue_key_self/lc created self reference');

%testhash = %selfhash;
hashvalue_key_self(\%testhash,'uc');
is($testhash{'ONE'},'Two','hashvalue_key_self/uc did not modify existing key');
is($testhash{'ZERO'},'Zero','hashvalue_key_self/uc created self reference');

is(hexstring($hexable),'00d0bed0beda',
   'hexstring() returns correct string');

# Tidy may not be available to test
SKIP:
{
    skip('Tidy not available',2) unless(-x '/usr/bin/tidy');
    is(system_tidy_xml('emptyuid.opf','emptyuid-tidy.opf'),0,
       'system_tidy_xml: emptyuid.opf');
    is(system_tidy_xml('missingfwid.opf','missingfwid-tidy.opf'),0,
       'system_tidy_xml: missingfwid.opf');
}

SKIP:
{
    skip('No /proc/PID/statm',1) unless(-f "/proc/$$/statm");
    ok(print_memory('15-misc_procedures.t'),'print_memory returns sucessfully');
}

########## CLEANUP ##########

unlink('emptyuid.opf');
unlink('missingfwid.opf');
