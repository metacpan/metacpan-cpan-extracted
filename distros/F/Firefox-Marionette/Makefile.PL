use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec();

my $binary = 'firefox';
if ( $^O eq 'MSWin32' ) {
    my $program_files_key;
    foreach my $possible ( 'ProgramFiles(x86)', 'ProgramFiles' ) {
        if ( $ENV{$possible} ) {
            $program_files_key = $possible;
            last;
        }
    }
    $binary = File::Spec->catfile(
        $ENV{$program_files_key},
        'Mozilla Firefox',
        'firefox.exe'
    );
}
elsif ( $^O eq 'darwin' ) {
    $binary = '/Applications/Firefox.app/Contents/MacOS/firefox';
}
my $version_string = `"$binary" -version`;
print $version_string;
if ($version_string) {
    if ( $version_string =~ /^Mozilla[ ]Firefox[ ](\d+)[.]\d+[.]\d+\s*/smx ) {
        my ($major) = ($1);
        if ( $major < 57 ) {
            die
"Please install a more recent version of Mozilla Firefox.  Current version is $major\n";
        }
    }
    else {
        die "Unable to parse $version_string\n";
    }
}
else {
    die "Mozilla Firefox cannot be discovered in $ENV{PATH}\n";
}

WriteMakefile(
    NAME           => 'Firefox::Marionette',
    AUTHOR         => 'David Dick <ddick@cpan.org>',
    VERSION_FROM   => 'lib/Firefox/Marionette.pm',
    ABSTRACT_FROM  => 'lib/Firefox/Marionette.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'   => 0,
        'Digest::SHA'  => 0,
        'MIME::Base64' => 0,
        (
              $^O eq 'MSWin32' ? ()
            : $^O eq 'darwin'  ? ()
            :                    ( 'Test::NeedsDisplay' => 0, )
        ),
    },
    PREREQ_PM => {
        'JSON'         => 0,
        'FileHandle'   => 0,
        'File::Temp'   => 0,
        'File::Spec'   => 0,
        'Socket'       => 0,
        'English'      => 0,
        'POSIX'        => 0,
        'URI'          => 0,
        'MIME::Base64' => 0,
        'overload'     => 0,
        (
            $^O eq 'MSWin32'
            ? (
                'Win32'                => 0,
                'Win32::Process'       => 0,
                'Win32::Process::Info' => 0
              )
            : ()
        ),
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Firefox-Marionette-*' },
);
