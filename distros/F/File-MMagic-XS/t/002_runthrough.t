# perl-test
use strict;
use Test::More;
my %map;
BEGIN
{
    my $file = __FILE__;
    %map = (
        $file             => 'text/plain',
        't/data/test.xml' => 'text/xml',
        't/data/test.rtf' => 'application/rtf'
    );
    plan(tests => (scalar( keys %map ) * 5 + 2) * 2 + 1);
}

BEGIN
{
    use_ok("File::MMagic::XS");
}


foreach my $eol (undef, "\0") {
    local $/ = $eol;
    my $fm = File::MMagic::XS->new;

    foreach my $file (keys %map) {
        my $mime = $map{$file};

        my $got = $fm->get_mime($file);
        is($got, $mime, "$file: expected $mime") or die;
        ok(open(F, $file), "ok to open $file");
        is($fm->fhmagic(\*F), $mime, "$file: expected $mime from fhmagic") or die;

        seek(F, 0, 0);
        my $buf = do { local $/ = undef; <F> };
        my $ref = \$buf;
        is($fm->bufmagic($ref), $mime, "$file: expected $mime from bufmagic");

        if ( $mime eq 'text/plain' ) {
            is( $fm->ascmagic( $buf ), $mime, "$file: expected $mime from ascmagic" );
        } else {
            ok( 1, "$file may be binary, skipping test" );
        }
    }

    $fm->add_magic( "0\tstring\t#\\ perl-test\tapplication/x-perl-test" );
    is( $fm->get_mime( __FILE__ ), 'application/x-perl-test' );

    # check file_ext (rt #35269)
    $fm->add_file_ext('t', 'application/x-perl-test');
    is( $fm->get_mime( __FILE__ ), 'application/x-perl-test' );
}

