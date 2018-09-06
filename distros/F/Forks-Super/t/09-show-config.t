use Forks::Super ':test_config';
use Test::More tests => 1;
use strict;
use warnings;

# show some items and modules that could be configured on this system.
# This test is included mostly so that I can get more detail about
# the CPAN testers' configuration.

if ($] >= 5.007) {
    binmode *STDERR, ':encoding(UTF-8)';
}

print STDERR "\n";
Forks::Super::Config::CONFIG_module("Time::HiRes");
Forks::Super::Config::CONFIG_module("Win32");
Forks::Super::Config::CONFIG_module("Win32::API");
Forks::Super::Config::CONFIG_module("Win32::Process");
Forks::Super::Config::CONFIG_module("Sys::CpuAffinity");
Forks::Super::Config::CONFIG_module("Sys::CpuLoadX");
Forks::Super::Config::CONFIG_module("DateTime::Format::Natural");
Forks::Super::Config::CONFIG_module("Proc::ProcessTable");
Forks::Super::Config::CONFIG_module("Test::SSH");
Forks::Super::Config::CONFIG_module("Net::OpenSSH");
Forks::Super::Config::CONFIG_external_program("/uptime");

print STDERR "\%SysInfo::CONFIG includes:";
foreach my $key (sort keys %Forks::Super::SysInfo::CONFIG) {
    if ($Forks::Super::SysInfo::CONFIG{$key}) {
	print STDERR " $key";
    }
}
print STDERR "\n";

my $locale = $ENV{LOCALE} || "";
my $lang = $ENV{LANG} || "";
my $lc_all = $ENV{LC_ALL} || "";
diag "\$ENV{LANG} = $lang, \$ENV{LOCALE} = $locale, \$ENV{LC_ALL} = $lc_all";

print STDERR "Forks::Super::Job is overloaded: ",
        $Forks::Super::Job::OVERLOAD_ENABLED, "\n";
print STDERR "Using tied IPC filehandles: ",
        " $Forks::Super::Job::Ipc::USE_TIE_FH",
        " $Forks::Super::Job::Ipc::USE_TIE_SH",
        " $Forks::Super::Job::Ipc::USE_TIE_PH\n";

diag "Max open fh: $Forks::Super::SysInfo::MAX_OPEN_FH";

diag "Max fork: $Forks::Super::SysInfo::MAX_FORK";

diag "Time_HiRes_TOL: $Forks::Super::SysInfo::TIME_HIRES_TOL";
if ($Forks::Super::SysInfo::TIME_HIRES_TOL >= 0.5) {
    print STDERR "     are you serious?\n";
}
diag "Number of cpus: $Forks::Super::SysInfo::NUM_PROCESSORS";
diag "\$ENV{TEST_LENIENT} = ",($ENV{TEST_LENIENT}||"undef");

diag "remote command: $Forks::Super::SysInfo::TEST_SSH_TEMPLATE";

local $! = $Forks::Super::SysInfo::FILE_NOT_FOUND_ERRNO || 2;
diag "FNF Error message: $!";

print STDERR "\n";

if ($^O =~ /bsd/i) {
    diag "Alt alarm on BSD: ", $Forks::Super::SysInfo::PREFER_ALTERNATE_ALARM;
}

if (grep /provided by ActiveState/, qx($^X -v)) {
    print STDERR
        "Dumping entire environment for ActiveState build environment:\n";
    print STDERR "    $_ => $ENV{$_}\n"  for sort keys %ENV;
}

my $sys = $Forks::Super::SysInfo::SYSTEM;
my $vers = $Forks::Super::SysInfo::PERL_VERSION;

# this test is too strong. Important things are
#       %Forks::Super::SysInfo::CONFIG settings match actual behavior
#       $Forks::Super::SysInfo::MAX_FORK is not too high for current sys

ok($^O eq $Forks::Super::SysInfo::SYSTEM
   && $] eq $Forks::Super::SysInfo::PERL_VERSION,
   "test perl is same as build perl")
or diag( qq{    The version of Perl used to test this module ($^O/$])
    is different from the version used to build this module ($sys/$vers).
    This could cause problems after installation, so you should
    "make clean" and rebuild the module with this version of Perl.} );
