#!perl -w

use strict;

use Test::More tests => 1;

my $minor = 0;
my $sdk = 0;

if ( -f '/usr/bin/sw_vers' && -x _ ) {
    ($minor) = (qx</usr/bin/sw_vers -productVersion> =~ /\A\d+\.(\d+)\.\d+/);
}

#check for sdk version passed to xs build
require Config;
if($Config::Config{ccflags} =~ m/-mmacosx-version-min=10\.(\d)/) {
    $sdk = $1;
}

my $featureversion = $sdk || $minor;
    
diag(qq(limiting available functions to Mac OS X 10.$featureversion)) if $featureversion && defined(&Test::More::diag);

my @import = (
    # Functions
    qw( FindDirectory
        HomeDirectory
        TemporaryDirectory
    ),
    # NSSearchPathDomainMask
    qw( NSUserDomainMask
        NSLocalDomainMask
        NSNetworkDomainMask
        NSSystemDomainMask
        NSAllDomainsMask
    ),
    # NSSearchPathDirectory
    qw( NSApplicationDirectory
        NSDemoApplicationDirectory
        NSDeveloperApplicationDirectory
        NSAdminApplicationDirectory
        NSLibraryDirectory
        NSDeveloperDirectory
        NSUserDirectory
        NSDocumentationDirectory
        NSAllApplicationsDirectory
        NSAllLibrariesDirectory
    ),
    ($minor >= 2) ?
    qw( NSDocumentDirectory
    ) : (),
    ($minor >= 3) ?
    qw( NSCoreServiceDirectory
    ) : (),
    ($minor >= 4) ?
    qw( NSDesktopDirectory
        NSCachesDirectory
        NSApplicationSupportDirectory
    ) : (),
    ( $featureversion >= 5 ) ?
    qw( NSDownloadsDirectory
    ) : (),
    ( $featureversion >= 6 ) ?
    qw( NSInputMethodsDirectory
        NSMoviesDirectory
        NSMusicDirectory
        NSPicturesDirectory
        NSPrinterDescriptionDirectory
        NSSharedPublicDirectory
        NSPreferencePanesDirectory
        NSItemReplacementDirectory
    ) : ()
);

use_ok('Mac::SystemDirectory', @import);
