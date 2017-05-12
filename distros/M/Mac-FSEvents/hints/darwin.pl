#!/usr/bin/perl

use Config;
use MacVersion;

if ( $Config{myarchname} =~ /i386/ ) {
    my ( $major, $minor, $release ) = osx_version();
    my $os_version = join('.', $major, $minor);

    if($minor >= 5) { # Leopard and up
        my @directories = (
            "/Developer/SDKs/MacOSX$os_version.sdk",
            "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$os_version.sdk",
        );

        my $sysroot;

        foreach my $directory (@directories) {
            if(-e $directory) {
                $sysroot = $directory;
                last;
            }
        }

        unless(defined $sysroot) {
            die "No SDK found for your version of OS X.  Please install Xcode.\n";
        }

        $arch = "-arch x86_64 -arch i386 -isysroot $sysroot -mmacosx-version-min=$os_version";
    } else {
        $arch = "-arch i386 -arch ppc";
    }

    print "Adding $arch\n";
    
    my $ccflags   = $Config{ccflags};
    my $ldflags   = $Config{ldflags};
    my $lddlflags = $Config{lddlflags};
    
    # Remove extra -arch flags from these
    $ccflags  =~ s/-arch\s+\w+//g;
    $ldflags  =~ s/-arch\s+\w+//g;
    $lddlflags =~ s/-arch\s+\w+//g;

    $self->{CCFLAGS} = "$arch $ccflags";
    $self->{LDFLAGS} = "$arch -L/usr/lib $ldflags";
    $self->{LDDLFLAGS} = "$arch $lddlflags -framework CoreServices -framework CoreFoundation";
}
