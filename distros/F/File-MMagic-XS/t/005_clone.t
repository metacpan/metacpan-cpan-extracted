#!perl
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
    plan(tests => (scalar( keys %map ) * 4) * 4 + 1);
}

BEGIN
{
    use_ok("File::MMagic::XS");
}


my $fm = File::MMagic::XS->new;
my $clone = $fm->clone();

{
    runthrough($fm);
    undef $fm;
}

{
    runthrough($clone);
    undef $clone;
}

sub runthrough {
    my $fm = shift;

    foreach my $endl ("\n", "\0") {
        local $/ = $endl;
        while (my($file, $mime) = each %map) {
            my $got = $fm->get_mime($file);
            is($got, $mime, "$file: expected $mime");
    
            ok(open(F, $file), "ok to open $file");
            is($fm->fhmagic(\*F), $mime, "$file: expected $mime from fhmagic");
    
            seek(F, 0, 0);
            my $buf = do { local $/ = undef; <F> };
            my $ref = \$buf;
            is($fm->bufmagic($ref), $mime, "$file: expected $mime from bufmagic");
        }
    }
}