# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Mangle.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
use File::Slurp;
BEGIN { use_ok('File::Mangle') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

write_file('t/sample.txt', 'This is the filecontent');
like( read_file('t/sample.txt'), qr/This is the filecontent/, 'file wrote okay' );
ok( not defined File::Mangle::fetch_block('t/sample.txt', 'marker') );

# Put a block in
File::Mangle::replace_block('t/sample.txt', 'marker', 'insertedblock');
like( File::Mangle::fetch_block('t/sample.txt', 'marker'), qr/insertedblock/, 'fetch_block() content exists' );
like( read_file('t/sample.txt'), qr/insertedblock/, 'replace_block() inserted text okay' );
like( read_file('t/sample.txt'), qr/^# ###:START:marker:###\r?\n?$/m, 'replace_block() start marker exists' );
like( read_file('t/sample.txt'), qr/^# ###:START:marker:###\r?\n?$/m, 'replace_block() end marker exists' );

# Remove the block
File::Mangle::replace_block('t/sample.txt', 'marker', undef);
unlike( File::Mangle::fetch_block('t/sample.txt', 'marker'), qr/insertedblock/, 'fetch_block() content exists' );
unlike( read_file('t/sample.txt'), qr/insertedblock/, 'replace_block() removed text okay' );
like( read_file('t/sample.txt'), qr/^# ###:START:marker:###\r?\n?$/m, 'replace_block() start marker exists' );
like( read_file('t/sample.txt'), qr/^# ###:START:marker:###\r?\n?$/m, 'replace_block() end marker exists' );

write_file('t/sample.txt', "Line 1\nLine 2\nLine 3\n");
File::Mangle::insert_block_before('t/sample.txt', 'marker', qr/Line\s+2/);
like( read_file('t/sample.txt'), qr/Line 1.*START.*END.*Line 2.*Line 3/s );

write_file('t/sample.txt', "Line 1\nLine 2\nLine 3\n");
File::Mangle::insert_block_after('t/sample.txt', 'marker', qr/Line\s+2/);
like( read_file('t/sample.txt'), qr/Line 1.*Line 2.*START.*END.*Line 3/s );

unlink 't/sample.txt';
