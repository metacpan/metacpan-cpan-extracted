use 5.010001;
use inc::Module::Install;
use lib 'inc';
use Devel::CheckLib;

say 'Checking if libpifacedigital and libmcp23s17 are installed...';
check_lib (
    lib => ['pifacedigital', 'mcp23s17'],
    header => ['pifacedigital.h', 'mcp23s17.h']
) or print (<<MSG), exit 0;
ERROR: missing either libpifacedigital or libmcp23s17.
  Error message: $@
Here's where you can find and install them:
  https://github.com/piface/libmcp23s17
  https://github.com/piface/libpifacedigital
MSG

print <<'MSG';
Do you want to test Device::PiFace using a real PiFace?
** NOTE ** This requires a REAL and CONNECTED PiFace!
           You can specify the hardware address of your PiFace using the
           environment variabile PIFACE_HARDWARE_ADDRESS. Defaults to 0.
** NOTE ** This will manipulate the input and output pins.
           Ensure that nothing is connected to your PiFace before proceeding.
MSG

my $want_hw_tests = ($ENV{PIFACE_ENABLE_HW_TESTS} // prompt ('', 'n')) =~ m|^y|i;
say sprintf 'Hardware tests %sbled.', $want_hw_tests ? 'ena' : 'disa';
tests $want_hw_tests ? 't/*.t t/*/*.t' : 't/*.t';

name 'Device-PiFace';
author 'Roberto Frenna <robertof@cpan.org>';
license 'perl';
perl_version '5.010001';
all_from 'lib/Device/PiFace.pm';
test_requires 'Test::More' => '0.42';
libs '-lpifacedigital -lmcp23s17';

# Create the target "README.md", used to generate the markdown version of the POD documentation.
# It uses the script gen_doc, which requires Pod::Markdown.
postamble "README.md: \$(VERSION_FROM)\n\t\$(PERL) gen_doc \$(VERSION_FROM)";

WriteAll;

# Thanks to the author of Device::BCM2835.
if (eval { require ExtUtils::Constant; 1 })
{
    # If you edit these definitions to change the constants used by this module,
    # you will need to use the generated const-c.inc and const-xs.inc
    # files to replace their "fallback" counterparts before distributing your
    # changes. Also, you will have to edit the EXPORT_TAGS hash in PiFace.pm.
    # -> ( { name => "CNAME", macro => "1" }, ... )
    my $names = [ map { +{ name => $_, macro => '1' } } qw(
        INPUT OUTPUT WRITE_CMD READ_CMD IODIRA IODIRB IPOLA IPOLB GPINTENA
        GPINTENB DEFVALA DEFVALB INTCONA INTCONB IOCON GPPUA GPPUB INTFA
        INTFB INTCAPA INTCAPB GPIOA GPIOB OLATA OLATB BANK_OFF BANK_ON
        INT_MIRROR_ON INT_MIRROR_OFF SEQOP_OFF SEQOP_ON DISSLW_ON DISSLW_OFF
        HAEN_ON HAEN_OFF ODR_ON ODR_OFF INTPOL_HIGH INTPOL_LOW
        GPIO_INTERRUPT_PIN
    ) ];
    ExtUtils::Constant::WriteConstants (
        NAME         => 'Device::PiFace',
        NAMES        => $names,
        DEFAULT_TYPE => 'IV',
        C_FILE       => 'const-c.inc',
        XS_FILE      => 'const-xs.inc'
    );
}
else
{
    require File::Copy;
    require File::Spec;
    foreach my $file ('const-c.inc', 'const-xs.inc')
    {
        my $fallback = File::Spec->catfile ('fallback', $file);
        File::Copy::copy ($fallback, $file) or die "Can't copy $fallback to $file: $!\n";
    }
}
