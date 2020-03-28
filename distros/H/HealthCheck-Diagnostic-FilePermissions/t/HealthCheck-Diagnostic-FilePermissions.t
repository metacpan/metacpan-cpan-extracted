use strict;
use warnings;

use File::Temp qw( tempdir tempfile );
use Test::More;
use Test::Differences;
use HealthCheck::Diagnostic::FilePermissions;

# Add a few fake files that will be used during the tests.
my $filename  = File::Temp->new( CLEANUP => 1 );
my $filename2 = File::Temp->new( CLEANUP => 1 );

# Check that we can use HealthCheck as a class.
my $result = HealthCheck::Diagnostic::FilePermissions->check(
    files  => [ $filename ],
    access => 'x',
);
is $result->{status}, 'CRITICAL',
    'Can use HealthCheck as a class.';
is $result->{info}, qq{App must have permission to execute '$filename'},
    'Info message is correct.';

# Check that we can use HealthCheck with initialized values too.
my $diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
    files  => [ $filename ],
    access => 'rwx',
);
$result = $diagnostic->check;
is $result->{status}, 'CRITICAL',
    'Can use HealthCheck with instance values too.';
is $result->{info}, qq{App must have permission to execute '$filename'},
    'Info message is correct.';

# Check that `check` parameters override the initialized parameters.
$diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
    files  => [ $filename ],
    access => '!rwx',
);
$result = $diagnostic->check;
is $result->{status}, 'CRITICAL',
    'Test that the original instance check is invalid.';
is $result->{info},
    qq{App must not have permission to read and write '$filename'},
    'Info message is correct.';
$result = $diagnostic->check(
    files  => [ $filename2 ],
    access => 'rw',
);
is $result->{status}, 'OK',
    'Test that we can override the instance values.';
is $result->{info},
    qq{App has correct access for '$filename2'},
    'Info message is correct.';

# Create a method that returns the info and status after running the
# check. If it failed, then this just returns the error.
my $run_check_or_error = sub {
    my $result;
    local $@;
    # We passed in a diagnostic, just run check.
    if ( ref $_[0] ) {
        $result = eval { $_[0]->check } if ref $_[0] ne 'HASH';
    }
    # We passed in some check parameters, send them in.
    else {
        $result = eval {
            HealthCheck::Diagnostic::FilePermissions->check( @_ );
        };
    }
    return [ $result->{status}, $result->{info} ] unless $@;
    return $@;
};

# Check that we require a list of files.
like $run_check_or_error->(), qr/No files extracted/,
    'Cannot run check without files.';
like $run_check_or_error->( files => [] ), qr/No files extracted/,
    'Cannot run check without files in ARRAY.';
like $run_check_or_error->( files => sub {} ), qr/No files extracted/,
    'Cannot run check without files from CODE.';

# Check for the file path existing on one file.
eq_or_diff( $run_check_or_error->( files => [ $filename ] ), [
    'OK', qq{'$filename' exists},
], 'Only check for file that exists when passed file list.' );
eq_or_diff( $run_check_or_error->( files => [ 'file/doesnt/exist' ] ), [
    'CRITICAL', qq{'file/doesnt/exist' does not exist},
], 'Show that a file doesn\'t exist when passed in file list.' );

# Check for the file path existing when we have multiple files.
eq_or_diff( $run_check_or_error->( files => [ 'nope', $filename ] ), [
    'CRITICAL', qq{'nope' does not exist},
], 'Do not pass when one of the files doesn\'t exist.' );
eq_or_diff( $run_check_or_error->( files => [ $filename, $filename2 ] ), [
    'OK', qq{Permissions are correct for '$filename' and '$filename2'},
], 'Pass when both files exist.' );

# Check that we can use a string for one file name.
eq_or_diff( $run_check_or_error->( files => $filename ), [
    'OK', qq{'$filename' exists},
], 'Pass when sending in a string for the file list.' );

# Check that we can use a sub to generate the file names.
eq_or_diff( $run_check_or_error->(
    files => sub { $filename, $filename2 },
), [
    'OK', qq{Permissions are correct for '$filename' and '$filename2'},
], 'Pass when sending in a sub for the file list.' );


# Check for permissions on the file.
chmod( 01755, $filename );
$diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
    files       => [ $filename ],
    permissions => '1005', # 01755 in decimal
);
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'OK', qq{Permissions are 1755 for '$filename'},
], 'Pass when given the right file permissions.' );
chmod( 01700, $filename );
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'CRITICAL',
    qq{Permissions should be 1755 but are 1700 for '$filename'},
], 'Do not pass when the permissions are incorrect for a file.' );

# Check for permissions when we have multiple files.
chmod( 0644, $filename );
chmod( 0644, $filename2 );
$diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
    files       => [ $filename, $filename2 ],
    permissions => 0644,
);
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'OK', qq{Permissions are correct for '$filename' and '$filename2'},
], 'Pass when the files have the same permission.' );
chmod( 01700, $filename2 );
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'CRITICAL',
    qq{Permissions should be 0644 but are 1700 for '$filename2'},
], 'Do not pass when one of the files has different permissions.' );

# Check for the right result when looking for permissions and one of the
# files doesn't exist.
$diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
    files       => [ $filename, 'doesnt_exist' ],
    permissions => 0644,
);
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'CRITICAL', qq{'doesnt_exist' does not exist},
], 'Do not pass when checking permissions and one file doesn\'t exist.' );

# Make sure the app can access a file correctly.
my %access = (
    full_name_hash  => { read => 1, write => 1, execute => 1 },
    short_name_hash => { r    => 1, w     => 1, x       => 1 },
    string          => 'rwx',
);
foreach ( keys %access ) {
    chmod( 0777, $filename );
    $diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
        files  => [ $filename ],
        access => $access{$_},
    );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'OK', qq{App has correct access for '$filename'},
    ], "$_: Pass when the app needs to rwx and can rwx." );
    chmod( 0000, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL',
        qq{App must have permission to execute, read, and write '$filename'},
    ], "$_: Fail when the app needs to rwx and cannot rwx." );
}
%access = (
    full_name_hash  => { read => 1, write => 1, execute => 0 },
    short_name_hash => { r    => 1, w     => 1, x       => 0 },
    string          => 'rw!x',
);
foreach ( keys %access ) {
    chmod( 0666, $filename );
    $diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
        files  => [ $filename ],
        access => $access{$_},
    );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'OK', qq{App has correct access for '$filename'},
    ], "$_: Pass when the app should only rw and can rw." );
    chmod( 0444, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL', qq{App must have permission to write '$filename'},
    ], "$_: Fail when the app should only rw but can only r." );
    chmod( 0000, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL',
        qq{App must have permission to read and write '$filename'},
    ], "$_: Fail when the app should only rw and cannot rw." );
}
%access = (
    full_name_hash   => { r    => 0, w     => 0, x       => 0 },
    short_name_hash  => { read => 0, write => 0, execute => 0 },
    string           => '!rwx',
);
foreach ( keys %access ) {
    chmod( 0000, $filename );
    $diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
        files  => [ $filename ],
        access => $access{$_},
    );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'OK', qq{App has correct access for '$filename'},
    ], "$_: Pass when the app should not rwx and cannot rwx." );
    chmod( 0444, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL', qq{App must not have permission to read '$filename'},
    ], "$_: Fail when the app should not rwx and can r." );
    chmod( 0666, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL',
        qq{App must not have permission to read and write '$filename'},
    ], "$_: Fail when the app should not rwx and can rw." );
    chmod( 0777, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL',
        "App must not have permission to execute, read, ".
        "and write '$filename'",
    ], 'Fail when the app should not rwx and can rwx.' );
}

# Make sure that the access permissions work for multiple files.
chmod( 0777, $filename );
chmod( 0777, $filename2 );
$diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
    files  => [ $filename, $filename2 ],
    access => 'rwx',
);
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'OK', qq{Permissions are correct for '$filename' and '$filename2'},
], 'Pass when the access permissions are correct for both files.' );
chmod( 0666, $filename2 );
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'CRITICAL', qq{App must have permission to execute '$filename2'},
], 'Fail when the access permissions are incorrect for one file.' );
chmod( 0444, $filename );
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'CRITICAL',
    "App must have permission to execute and write '$filename'; App ".
    "must have permission to execute '$filename2'",
], 'Fail when the access permissions are incorrect for both files.' );

# Try pairing the access permissions tests with other checks.
chmod( 0777, $filename );
$diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
    files       => [ $filename, 'doesnt_exist' ],
    permissions => 0777,
    access      => 'rwx',
);
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'CRITICAL', qq{'doesnt_exist' does not exist},
], 'Fail when permissions pass but another file does not exist.' );
chmod( 0666, $filename );
eq_or_diff( $run_check_or_error->( $diagnostic ), [
    'CRITICAL',
    "App must have permission to execute '$filename'; Permissions ".
    "should be 0777 but are 0666 for '$filename'; 'doesnt_exist' ".
    "does not exist",
], 'Fail when permissions fail and another file does not exist.' );

# Check that we can ignore the results of some access permissions.
%access = (
    full_name_hash  => { write => 1 },
    short_name_hash => { w     => 1 },
    string          => 'w',
);
foreach ( keys %access ) {
    chmod( 0600, $filename );
    $diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
        files  => $filename,
        access => $access{$_},
    );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'OK', qq{App has correct access for '$filename'},
    ], "$_: Pass when the app should w and can rw." );
    chmod( 0000, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL', qq{App must have permission to write '$filename'},
    ], "$_: Fail when the app should w and cannot rwx." );
}
%access = (
    full_name_hash  => { execute => 0 },
    short_name_hash => { x       => 0 },
    string          => '!x',
);
foreach ( keys %access ) {
    chmod( 0200, $filename );
    $diagnostic = HealthCheck::Diagnostic::FilePermissions->new(
        files  => [ $filename ],
        access => $access{$_},
    );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'OK', qq{App has correct access for '$filename'},
    ], "$_: Pass when the app should not x and can w." );
    chmod( 0700, $filename );
    eq_or_diff( $run_check_or_error->( $diagnostic ), [
        'CRITICAL', qq{App must not have permission to execute '$filename'},
    ], "$_: Fail when app should not x and can rwx." );
}

# Test that it dies when we pass invalid access parameters.
my %f = ( files => $filename );
like $run_check_or_error->( %f, access => { write => 1, faker => 1 } ),
    qr/Invalid access parameter: faker/,
    'Fail when an access parameter hash is invalid.';
like $run_check_or_error->( %f, access => 'wrx!e' ),
    qr/Invalid access parameter: e/,
    'Fail when an access parameter string is invalid.';

# Test that we check for the group and owner correctly.
my $owner = getpwuid( ( stat $filename )[4] );
my $group = getgrgid( ( stat $filename )[5] );
eq_or_diff( $run_check_or_error->( %f, owner => $owner ), [
    'OK', qq{Owner is $owner for '$filename'},
], 'Pass when the owner is correct.' );
eq_or_diff( $run_check_or_error->( %f, group => $group ), [
    'OK', qq{Group is $group for '$filename'},
], 'Pass when the group is correct.' );
eq_or_diff( $run_check_or_error->( %f, owner => $owner, group => $group ), [
    'OK', qq{Permissions are correct for '$filename'},
], 'Pass when the owner and group are correct.' );
eq_or_diff( $run_check_or_error->( %f, owner => 'fake-owner' ), [
    'CRITICAL',
    qq{Owner should be fake-owner but is $owner for '$filename'},
], 'Fail when the owner is incorrect.' );
eq_or_diff( $run_check_or_error->( %f, group => 'fake-group' ), [
    'CRITICAL',
    qq{Group should be fake-group but is $group for '$filename'},
], 'Fail when the group is incorrect.' );
eq_or_diff( $run_check_or_error->( %f, group => 'fg', owner => 'fo' ), [
    'CRITICAL',
    "Owner should be fo but is $owner for '$filename'; Group should ".
    "be fg but is $group for '$filename'",
], 'Fail when the owner and group are incorrect.' );

done_testing;
