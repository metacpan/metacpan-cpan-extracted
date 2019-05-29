use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok("File::Record") or BAIL_OUT();
}

ok( defined &File::Record::new, 'File::Record::new is defined' );
ok( defined &File::Record::mode, 'File::Record::mode is defined' );
ok( defined &File::Record::pattern, 'File::Record::pattern is defined' );
ok( defined &File::Record::next_record, 'File::Record::next_record is defined' );
{
    my $reader = File::Record->new();
    is( ref $reader, 'File::Record', 'Class is right');
    is( $reader->mode, 'end', 'Default mode is end' );
    is( $reader->pattern, qr/\n$/, 'Default pattern is qr/\n$/' );
}

done_testing();
