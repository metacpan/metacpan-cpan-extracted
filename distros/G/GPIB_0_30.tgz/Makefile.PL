use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$perl_version = 5.004;      # Minimum version

die "Your version of perl is too old ($]), must be at least $perl_version\n  "
    if $] < $perl_version;


#
# Drivers for specific devices.
#
#    HP33120A   15MHz Function generator (gpib or serial)
#    HP3585A    Old, but great 40MHz Spectrum analyser
#    HP59306A   GPIB box with 6 relays
#    HPE3631A   Triple output power supply (gpib or serial)
#
@drivers = ('hp33120a', 'hp3585a', 'hp59306a', 'hpe3631a');



# This is the low level interfaces to the devices.  You might want
# to comment out one or more of these interfaces depending on your
# local setup.
#
#    hpserial   Unix ttyios interface for HP serial devices like
#               HP33120A, HPE3631A, etc.  Only tested on Linux but
#               will probably work on other Unix-like OSes.
#
#    ni         Interface to National Instruments GPIB cards
#
#    llp        Interface to Linux Lab Project device driver
#
#    rmt        Network connection to server providing GPIB access service
#               Requires MD5 and Storable from CPAN
#
@interfaces = ();

# Add GPIB::ni interface for National Instruments GPIB cards using NI driver.
# This XS module builds on both Linux and NT (I'm so proud).
push(@interfaces, 'ni');

# Add GPIB::rmt interface for remote TCP/IP access to devices
push(@interfaces, 'rmt');

# Add hpserial interface on Linux machines.  This should work on other
# Unix machines, but your mileage may vary
push(@interfaces, 'hpserial') if $^O =~ /linux/;

# Add GPIB::llp interface on Linux machines.
# This seems to be obsolete.  Code for the llp drivers is still here
# but it's probably suffering from bit rot.
#
# push(@interfaces, 'llp') if $^O =~ /linux/;

# Check for missing modules
@missing = ();

# Look for MD5
eval "use MD5;";
if ($@) {
    push @missing, 'MD5';
    print <<'MSG';
        The MD5 module is not installed.  This module is used for
        authentication of remote GPIB connections.

MSG
}

# Look for Storable
eval "use Storable;";
if ($@) {
    push @missing, 'Storable';
    print <<'MSG';
        The Storable module is not installed.  This module is used for
        remote GPIB connections.

MSG
}

if (@missing) {
    print <<'MSG';
        Optional modules are available from any CPAN mirror, in particular
            http://www.perl.com/CPAN/modules/by-module
            http://www.perl.org/CPAN/modules/by-module
            ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module

MSG
    exit(1);
}


print "Using interfaces: @interfaces\n";
print "Using instrument drivers: @drivers\n\n"; 
WriteMakefile(
    'NAME'	    => 'GPIB',
    'DIR'           => [@interfaces, @drivers],
    'VERSION_FROM'  => 'GPIB.pm', # finds $VERSION
    ($] ge '5.005') ? (
        'AUTHOR' => 'Jeff Mock (jeff@mock.com)',
        'ABSTRACT' => 'GPIB device control',
    ) : (),
);

