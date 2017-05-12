#ABSTRACT: tests the bin cli tool
use Test::More;
use IO::All;
use utf8;

my $gitcrypt_config_file = "./.gitcrypt-tests";
unlink $gitcrypt_config_file;
$ENV{GITCRYPT_CONFIG_FILE} = $gitcrypt_config_file;
my $key = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
my $newkey = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
my $salt = 'SSSSSSSSSSSSSSSSSSSSSSAAAAAAAAAALLLLLLLLLLLLLLTTTTTTTTTTTTTTTTTT';
my $newsalt = 'OKODEOFJOEEEEEEEEEEEEEEEEEEEEEFFFFFFBBBBBBBCCCCCDDDDDEEEEEEERRRRRRRTTTTTTTTTGHH';

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
    my $cmd = `$^X ./bin/gitcrypt set key    "$key"`;
    my $expected = [
        'Set key to: '.$key,
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'key tests' );
}

{
    #set salt
    my $cmd = `$^X ./bin/gitcrypt set salt   "$salt"`;
    my $expected = [
        'Set salt to: '.$salt,
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
U2FsdGVkX1/MzMzMzMzMzHbtkDqJBoAgi/gKtBH82UX2cwLS68g3OoPr4dbFtg7d
U2FsdGVkX1/MzMzMzMzMzDu7hv4e4lKQoWVvI4MHVwGJfsFazhx6RA==
U2FsdGVkX1/MzMzMzMzMzAhf7ZFN4frza20XZ0+T8EA=
CONTENT
}

{
    #change key
#   my $cmd = `$^X ./bin/gitcrypt status`;
    #change the password
    my $cmd = `$^X ./bin/gitcrypt change key $newkey`;
    my $expected = [
        'Files decrypted. Will change key.',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'encryption key changed' );
#   $cmd = `$^X ./bin/gitcrypt status`;
}

encrypt_tests_new_key();

test_original_file_contents();

{
    #change salt
#   my $cmd = `$^X ./bin/gitcrypt status`;
    #change the password
    my $cmd = `$^X ./bin/gitcrypt change salt $newsalt`;
    my $expected = [
        'Files decrypted. Will change salt.',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'encryption salt changed' );
#   my $cmd = `$^X ./bin/gitcrypt status`;
}

encrypt_tests_new_salt();

test_original_file_contents();

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
        $test_action->( $cmd =~ m#\Q$_\E#g, $test_name );
    }
}

sub encrypt_tests {
    encrypt();
    ok( io('file1-tests')->slurp eq <<CONTENT, 'encrypt tests 1');
U2FsdGVkX1/MzMzMzMzMzHbtkDqJBoAgi/gKtBH82UX2cwLS68g3OoPr4dbFtg7d
U2FsdGVkX1/MzMzMzMzMzDu7hv4e4lKQoWVvI4MHVwGJfsFazhx6RA==
U2FsdGVkX1/MzMzMzMzMzAhf7ZFN4frza20XZ0+T8EA=
CONTENT
    ok( io('file2-tests')->slurp eq <<CONTENT, 'encrypt tests 2');
U2FsdGVkX1/MzMzMzMzMzIKDANK4vTdyYSeyvJlNyrw=
U2FsdGVkX1/MzMzMzMzMzKaZ7mTU+DHh4XmFZtUGNP0=
U2FsdGVkX1/MzMzMzMzMzGJjsLazSwno446oboIBeyc=
CONTENT
    #now there are 2 files encrypted, let me add a 3rd file which is not encrypted
}

sub encrypt_tests_new_key {
    #encrypt
    encrypt();
    #check encrypted file contents:
    ok( io('file1-tests')->slurp eq <<CONTENT, 'encrypt tests new key 111' );
U2FsdGVkX1/MzMzMzMzMzHqi29NDV5EMknDHUoKP6X558mdDzc6HwcMYX/Iilqgh
U2FsdGVkX1/MzMzMzMzMzGSxwXe+wjsDHFMvaDitxzBRQuC6RZEE1w==
U2FsdGVkX1/MzMzMzMzMzOASBM2Pm0up8HYJdbUviqs=
CONTENT

    ok( io('file2-tests')->slurp eq <<CONTENT, 'encrypt tests new key 2' );
U2FsdGVkX1/MzMzMzMzMzCd3HEYwoJlVYCiOnPeOGHI=
U2FsdGVkX1/MzMzMzMzMzFu9Bgea6Z8ZU/fyp1n8NmE=
U2FsdGVkX1/MzMzMzMzMzFX8FwbJUbJF9YkiGsEbguo=
CONTENT
    #now there are 2 files encrypted, let me add a 3rd file which is not encrypted
}

sub test_original_file_contents {
    #decrypt
    my $cmd = `$^X ./bin/gitcrypt decrypt`;
    my $expected = [
        'Decrypted',
    ];
    validate_expected_strings( 'ok', $cmd, $expected, 'decrypt tests 1' );

    #check decrypted file contents:
    ok( io('file1-tests')->slurp eq <<LINES, 'decrypt tests 2');
a couple of lines to test
some other line
bla bla bla
LINES

    ok( io('file2-tests')->slurp eq <<LINES, 'decrypt tests 3');
some lines
another line
third line
LINES

}

sub encrypt_tests_new_salt {
    #encrypt
    encrypt();
    #check encrypted file contents:
    ok( io('file1-tests')->slurp eq <<CONTENT, 'encrypt tests new key 111' );
U2FsdGVkX1+Ejejzju7u7kDWuh43jGaYYHVq3kWbZIgYUBzmNXRbq2mnbsP3A5kr
U2FsdGVkX1+Ejejzju7u7hD1+4yIiVrGkTpDEaN372gmHM28yOKKYg==
U2FsdGVkX1+Ejejzju7u7ngCtioUFjNdrSwCHUhGFqA=
CONTENT

    ok( io('file2-tests')->slurp eq <<CONTENT, 'encrypt tests new key 2' );
U2FsdGVkX1+Ejejzju7u7o34b02+WtDfRHEk3rDHlhU=
U2FsdGVkX1+Ejejzju7u7oItsF0JFaXvBzBpLOfrI/4=
U2FsdGVkX1+Ejejzju7u7izWw/Wc0VuZlVbYf0rX2Q4=
CONTENT
    #now there are 2 files encrypted, let me add a 3rd file which is not encrypted
}

sub encrypt {
    my $cmd = `$^X ./bin/gitcrypt encrypt`;
    my $expected = [
        'Encrypted',
    ];
    validate_expected_strings( 'ok', $cmd, $expected );
};

done_testing;
