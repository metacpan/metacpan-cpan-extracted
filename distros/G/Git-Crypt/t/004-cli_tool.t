#ABSTRACT: tests the bin cli tool
use Test::More;
use IO::All;

my $gitcrypt_config_file = "./.gitcrypt-tests";
unlink $gitcrypt_config_file;
$ENV{GITCRYPT_CONFIG_FILE} = $gitcrypt_config_file;

{
    #init
    my $cmd = `$^X ./bin/gitcrypt init`;
    my $expected = [
        'Initializing',
        'gitcrypt set cipher Blowfish',
        'gitcrypt set key    some key',
        'gitcrypt set salt   some salt',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'init tests' );
}

{
    #set cipher
    my $cmd = `$^X ./bin/gitcrypt set cipher Blowfish`;
    my $expected = [
        'Set cipher to: Blowfish',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'cipher tests' );
}

{
    #set key
    my $cmd = `$^X ./bin/gitcrypt set key    some key`;
    my $expected = [
        'Set key to: some key',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'key tests' );
}

{
    #set salt
    my $cmd = `$^X ./bin/gitcrypt set salt   some key`;
    my $expected = [
        'Set salt to: some key',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'salt tests' );
}

{
    #list
    my $cmd = `$^X ./bin/gitcrypt list`;
    my $expected = [
        'No files added',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'list tests' );
}

{
    #write file1-tests
    io("file1-tests")->print(<<LINES
a couple of lines to test
some other line
bla bla bla
LINES
    );
    #write file2-tests
    io("file2-tests")->print(<<LINES
some lines
another line
third line
LINES
    );

    #add
    my $cmd = `$^X ./bin/gitcrypt add file1-tests file2-tests`;
    my $expected = [
        'Adding files:',
        'file1-tests',
        'file2-tests',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'add file tests' );
}

encrypt_tests();

{
    #encrypt 3rd file

    io("file3-tests")->print(<<LINES);
a couple of lines to test
some other line
bla bla bla
LINES

    encrypt();
    my $cmd = `$^X ./bin/gitcrypt add file3-tests`;
    my $expected = [
        'Adding files:',
        'file3-tests',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'add file tests 3rd file' );
    encrypt();
}



encrypt_tests();

{
    #check 3rd file encrypted contents
    ok( io('file3-tests')->slurp eq <<CONTENT, 'encrypt tests 3');
U2FsdGVkX1/IbgTiAAAAAFSmbJjcNIQPNXdGv5fgIUXj/s3Lu7A6iGqjMyBwc54X
U2FsdGVkX1/IbgTiAAAAAPXwTlqvbGrKGNqd5eVtThV3icUZwLwgRA==
U2FsdGVkX1/IbgTiAAAAAF42mY3K384WCD9i9S74GuU=
CONTENT
}

{
    #decrypt
    my $cmd = `$^X ./bin/gitcrypt decrypt`;
    my $expected = [
        'Decrypted',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'decrypt tests 1' );
    #check decrypted file contents:
    validate_expected_strings( 'ok', io('file1-tests')->slurp, [
        'a couple of lines to test',
        'some other line',
        'bla bla bla',
    ], 'decrypt tests 2');

    validate_expected_strings( 'ok', io('file2-tests')->slurp, [
        'some lines',
        'another line',
        'third line',
    ], 'decrypt tests 3');
}


{
    #del
    my $cmd = `$^X ./bin/gitcrypt del file1-tests file2-tests`;
    my $expected = [
        'Deleting files:',
        'file1-tests',
        'file2-tests',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'del file tests' );
}


{
    #cleanup
    unlink "file1-tests";
    unlink "file2-tests";
    unlink $gitcrypt_config_file;
}

sub validate_expected_strings {
    my $test_action = shift;
    my $cmd      = shift;
    my $expected = shift;
    my $test_name=shift;
    for ( @$expected ) {
        $test_action->( $cmd =~ m#$_#g, $test_name );
    }
}

sub encrypt_tests {
    {
        #encrypt
        encrypt();

        #check encrypted file contents:
#warn io('file1-tests')->slurp;
        ok( io('file1-tests')->slurp eq <<CONTENT, 'encrypt tests 1');
U2FsdGVkX1/IbgTiAAAAAFSmbJjcNIQPNXdGv5fgIUXj/s3Lu7A6iGqjMyBwc54X
U2FsdGVkX1/IbgTiAAAAAPXwTlqvbGrKGNqd5eVtThV3icUZwLwgRA==
U2FsdGVkX1/IbgTiAAAAAF42mY3K384WCD9i9S74GuU=
CONTENT
#warn io('file2-tests')->slurp;
        ok( io('file2-tests')->slurp eq <<CONTENT, 'encrypt tests 2');
U2FsdGVkX1/IbgTiAAAAAIm66zCcFmSZzdi6DAFNJLc=
U2FsdGVkX1/IbgTiAAAAAEEtpmhdKZlGUv5X/l9WByQ=
U2FsdGVkX1/IbgTiAAAAABYKsXVjq0YHRQL8Yq/Wj5I=
CONTENT
        #now there are 2 files encrypted, let me add a 3rd file which is not encrypted

    }
}

sub encrypt {
    my $cmd = `$^X ./bin/gitcrypt encrypt`;
    my $expected = [
        'Encrypted',
    ];
    validate_expected_strings( 'ok', $cmd, $expected );
};

done_testing;
