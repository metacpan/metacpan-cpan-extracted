use Modern::Perl;

use Test::More tests => 5;
use Test::NoWarnings;
use File::Temp qw(tempfile);
use Koha::QA::FilePermissions;

my $expected_messages = {};

sub check_permissions {
    my ( $file, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::FilePermissions->new( { file => $file, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest 'File .t has exec flag' => sub {
    plan tests => 1;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.t' );
    print $fh 'use Test::More;';
    close $fh;
    chmod 0755, $filename or die "chmod failed: $!";

    my @errors = check_permissions($filename);
    is( scalar @errors, 0, '.t file with exec flag passes' );
};

subtest 'File .t does not have exec flag' => sub {
    plan tests => 1;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.t' );
    print $fh 'use Test::More;';
    close $fh;
    chmod 0644, $filename or die "chmod failed: $!";

    my @errors = check_permissions($filename);
    is_deeply(
        \@errors,
        [
            {
                error   => 'missing_x_flag',
                message => 'File must have the exec flag',
            }
        ],
        '.t file without exec flag fails'
    );
};

subtest 'File .pm has exec flag' => sub {
    plan tests => 1;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.pm' );
    print $fh "use Modern::Perl;\n1;";
    close $fh;
    chmod 0755, $filename or die "chmod failed: $!";

    my @errors = check_permissions($filename);
    is_deeply(
        \@errors,
        [
            {
                error   => 'extra_x_flag',
                message => 'File must not have the exec flag',
            }
        ],
        '.pm file with exec flag fails'
    );
};

subtest 'File .pm does not have exec flag' => sub {
    plan tests => 1;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.pm' );
    print $fh "use Modern::Perl;\n1;";
    close $fh;
    chmod 0644, $filename or die "chmod failed: $!";

    my @errors = check_permissions($filename);
    is( scalar @errors, 0, '.pm file without exec flag passes' );
};
