use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec();

if ( ( $^O eq 'MSWin32' ) || ( $^O eq 'cygwin' ) ) {
}
elsif ( $> == 0 ) {    # see RT#131304
    my $current = $ENV{HOME};
    my $correct = ( getpwuid($>) )[7];
    if ( $current eq $correct ) {
    }
    else {
        $ENV{HOME} = $correct;
        print
"Running as root.  Resetting HOME environment variable from $current to $ENV{HOME}\n";
    }
}

sub last_desperate_search {
    if ( ( $^O eq 'MSWin32' ) ) {
        print "Checking in Path:" . `"firefox.exe" -version` . "\n";
    }
    elsif ( ( $^O eq 'darwin' ) or ( $^O eq 'cygwin' ) ) {
        print "Checking in PATH:" . `firefox -version` . "\n";
    }
    my $glob_path = '/usr/share/applications/firefox*.desktop';
    foreach my $path ( glob $glob_path ) {
        print `perl -nle 'print "\$ARGV:\$_" if (/(Exec|^\\[)/);' $path`;
    }
}

my @win32_firefox_directories =
  ( 'Mozilla Firefox', 'Firefox Developer Edition', 'Firefox Nightly' );
my $binary = 'firefox';
if ( $^O eq 'MSWin32' ) {
  SEARCH: foreach my $env_key ( 'ProgramFiles', 'ProgramFiles(x86)' ) {
        foreach my $firefox_directory (@win32_firefox_directories) {
            if (
                ( $ENV{$env_key} )
                && (
                    -e File::Spec->catfile(
                        $ENV{$env_key}, $firefox_directory, 'firefox.exe'
                    )
                )
              )
            {
                $binary =
                  File::Spec->catfile( $ENV{$env_key}, $firefox_directory,
                    'firefox.exe' );
                last;
            }
        }
    }
}
elsif ( $^O eq 'darwin' ) {
    $binary = '/Applications/Firefox.app/Contents/MacOS/firefox';
}
elsif ( $^O eq 'cygwin' ) {
  SEARCH:
    foreach
      my $base_directory ( "$ENV{PROGRAMFILES} (x86)", "$ENV{PROGRAMFILES}" )
    {
        foreach my $firefox_directory (@win32_firefox_directories) {
            if (   ( -e "$base_directory" )
                && ( -e "$base_directory/$firefox_directory/firefox.exe" ) )
            {
                $binary = "$base_directory/$firefox_directory/firefox.exe";
            }
        }
    }
}
my $version_string = `"$binary" -version`;
print $version_string;
my $major;
if ($version_string) {
    if ( $version_string =~ /^Mozilla[ ]Firefox[ ](\d+)[.]\d+([.]\d+)?\s*/smx )
    {
        ($major) = ($1);
        if ( $major < 31 ) {
            last_desperate_search();
            warn
"Please install a more recent version of Mozilla Firefox.  Current version is $major\n";
        }
    }
    else {
        last_desperate_search();
        die "Unable to parse $version_string\n";
    }
}
else {
    last_desperate_search();
    die "Mozilla Firefox cannot be discovered in $ENV{PATH}\n";
}
if ( $^O eq 'linux' ) {
    print "grep -r Mem /proc/meminfo\n";
    print `grep -r Mem /proc/meminfo`;
    print "ulimit -a | grep -i mem\n";
    print `ulimit -a | grep -i mem`;
}
elsif ( $^O =~ /bsd/i ) {
    print "sysctl hw | egrep 'hw.(phys|user|real)'\n";
    print `sysctl hw | egrep 'hw.(phys|user|real)'`;
    print "ulimit -a | grep -i mem\n";
    print `ulimit -a | grep -i mem`;
}
if ( ( $^O eq 'linux' ) || ( $^O eq 'freebsd' ) ) {
    my $virtual_memory = `ulimit -v 2>/dev/null`;
    if ( $? == 0 ) {
        chomp $virtual_memory;
        if ( $virtual_memory eq 'unlimited' ) {
        }
        elsif ( ( $^O eq 'freebsd' ) && ( $virtual_memory < 1_800_000 ) ) {
            die
"$virtual_memory bytes of virtual memory is less than the required 1.8Gb to run test suite in $^O";
        }
        elsif ( $virtual_memory < 2_400_000 ) {
            die
"$virtual_memory bytes of virtual memory is less than the required 2.4Gb to run test suite in $^O";
        }
    }
}
if ( ( $^O eq 'MSWin32' ) || ( $^O eq 'darwin' ) || ( $^O eq 'cygwin' ) ) {
}
elsif ( $ENV{DISPLAY} ) {
}
elsif ( $major > 55 ) {    # -headless is supported
}
else {
    `Xvfb -help 2>/dev/null >/dev/null`;
    if ( $? != 0 ) {
        die
"Unable to run tests when not in an X11 environment and Xvfb is not available.  Please install Xvfb";
    }
}

WriteMakefile(
    NAME          => 'Firefox::Marionette',
    AUTHOR        => 'David Dick <ddick@cpan.org>',
    VERSION_FROM  => 'lib/Firefox/Marionette.pm',
    ABSTRACT_FROM => 'lib/Firefox/Marionette.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'MIN_PERL_VERSION' => '5.006' )
        : ()
    ),
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Cwd'             => 0,
        'Test::More'      => 0,
        'Digest::SHA'     => 0,
        'HTTP::Daemon'    => 0,
        'HTTP::Status'    => 0,
        'HTTP::Response'  => 0,
        'File::HomeDir'   => 0,
        'IO::Socket::SSL' => 0,
        $] ge '5.010' ? ( 'PDF::API2' => 2.036 ) : (),
    },
    PREREQ_PM => {
        'Archive::Zip'        => 0,
        'Config::INI::Reader' => 0,
        'JSON'                => 0,
        'Config'              => 0,
        'FileHandle'          => 0,
        'DirHandle'           => 0,
        'File::Find'          => 0,
        'File::Temp'          => 0,
        'File::Spec'          => 0,
        'Socket'              => 0,
        'English'             => 0,
        'POSIX'               => 0,
        'URI'                 => 0,
        'Fcntl'               => 0,
        'IPC::Open3'          => 1.03,
        'MIME::Base64'        => 0,
        'Time::HiRes'         => 0,
        'Exporter'            => 0,
        'overload'            => 0,
        'base'                => 0,
        (
            $^O eq 'MSWin32'
            ? (
                'Win32'          => 0,
                'Win32::Process' => 0,
              )
            : ()
        ),
        (
              ( $^O ne 'MSWin32' and $^O ne 'darwin' and $^O ne 'cygwin' )
            ? ( 'Crypt::URandom' => 0, )
            : ()
        ),
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Firefox-Marionette-*' },
);
