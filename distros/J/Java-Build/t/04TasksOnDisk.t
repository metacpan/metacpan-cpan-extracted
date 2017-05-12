use strict;
use warnings;

# signjar is not tested, since a keystore is required.  I do not have one.

use Test::More tests => 9;

use Java::Build::Tasks;

eval {
    my $tmp = build_file_list(
        BASE_DIR         => 't/missing.src.dir',
        INCLUDE_PATTERNS => [ qr/\.java$/ ],
    );
};
like($@, qr/not a directory/, "build_file_list BASE_DIR does not exit");

my $javas = build_file_list(
    BASE_DIR         => 't/src',
    INCLUDE_PATTERNS => [ qr/\.java$/ ],
    EXCLUDE_PATTERNS => [ qr/Test/ ],
    STRIP_BASE_DIR   => 1,
);

SKIP: {
    `jar 2>&1`;

    skip "Couldn't find jar in your PATH", 5 if ($? != 256);

#--------------- Nothing to jar -------------------------

    eval q{
        jar( FILE_LIST => [], JAR_FILE => "sample.jar", BASE_DIR => 't/src' );
    };
    like($@, qr/Nothing/, "empty jar request");

#--------------- Basic, put one file in a jar -----------
    jar(
            FILE_LIST => $javas,
            JAR_FILE  => 'sample.jar',
            BASE_DIR  => 't/src',
    );

    open JAR, "jar tf t/src/sample.jar |" or die "couldn't use jar\n";
    my $jar_line;
    while ($jar_line = <JAR>) {
        chomp $jar_line;
        last if ($jar_line =~ /java/);
    }
    close JAR or die "couldn't use jar\n";
    is($jar_line, "Hello.java", "jar");

#-------------- Can we append to a jar? -------------

    jar(
        FILE_LIST => [ "Hello.class" ],
        JAR_FILE  => '../src/sample.jar',
        BASE_DIR  => 't/compiled',
        APPEND    => 1,
    );

    open JAR_AGAIN, "jar tf t/src/sample.jar |" or die "coudn't use jar\n";
    while ($jar_line = <JAR_AGAIN>) {
        chomp $jar_line;
        last if ($jar_line =~ /class/);
    }
    is($jar_line, "Hello.class", "jar append");
    close JAR_AGAIN or die "couldn't use jar\n";

    unlink 't/src/sample.jar';

#-------- Can we put files like Hello$1.class into a jar -----------

    my $dollar_list = build_file_list(
        BASE_DIR         => 't/compiled',
        INCLUDE_PATTERNS => [ qr/\$/ ],
        STRIP_BASE_DIR   => 1,
        QUOTE_DOLLARS    => 1,
    );

    jar(
        FILE_LIST => $dollar_list,  # This would work: [ 'Hello\$1.class' ],
        JAR_FILE  => 'dollar.jar',
        BASE_DIR  => 't/compiled',
    );

    open JAR, "jar tf t/compiled/dollar.jar|" or die "couldn't use jar\n";
    while ($jar_line = <JAR>) {
        chomp $jar_line;
        last if ($jar_line =~ /Hello/);
    }
    close JAR;
    is($jar_line, 'Hello$1.class', "jar can use dollars");
    unlink 't/compiled/dollar.jar';

#-------- Can we have a space in the jar MANIFEST? -----------

#    set_logger(Logger->new());

    mkdir "t/bad dir";
    mkdir "t/bad dir/manifest dir";
    open MAN, ">t/bad dir/manifest dir/MANIFEST.MF";

# Note that there must be a space after the Class-Path: in the following.
    print MAN <<EOT;
Manifest-Version: 1.0
Class-Path: 

EOT
    close MAN;
    `cp t/src/Hello.java 't/bad dir'`;

    jar(
        FILE_LIST => [ "Hello.java" ],
        JAR_FILE  => 'space.jar',
        BASE_DIR  => "t/bad dir",
        MANIFEST  => "manifest dir/MANIFEST.MF",
    );

    open JAR, "jar tf 't/bad dir/space.jar'|" or die "couldn't use jar\n";
    while ($jar_line = <JAR>) {
        chomp $jar_line;
        last if ($jar_line =~ /Hello/);
    }
    close JAR;
    is($jar_line, "Hello.java", "spaces in jar path");
    unlink 't/bad dir/space.jar';
}

#-------- Do we receive jar errors?

eval q{
    jar(
        FILE_LIST => [ "beagle.java" ],
        JAR_FILE  => 'wontmake.jar',
        BASE_DIR  => "t/src",
    );
};
like ($@, qr/no such file/i, "jar failure");

#-------- Tests of filter_file

filter_file(
    INPUT   => 't/file2filter',
    OUTPUT  => 't/file3filter',
    FILTERS => [ sub { $_[0] =~ s/Happy/Joyous/g; } ],
);
unless (open FILTERED, 't/file3filter') {
    fail("basic file filter");
}
else {
    chomp(my $data = <FILTERED>);
    is(
        $data,
       'This is a Joyous file ready for filtering.',
       'basic file filter'
    );
    close FILTERED;
}

filter_file(
    INPUT => 't/file3filter',
    FILTERS => [ sub { $_[0] =~ s/Joyous/happy/g; } ],
);

open FILTERED, 't/file3filter';
chomp(my $data = <FILTERED>);
close FILTERED;
is($data, 'This is a happy file ready for filtering.', 'overwriting filter');

unlink 't/file3filter';

package Logger;
sub new { return bless {}, shift }
sub log {
    print STDERR "@_\n";
}
