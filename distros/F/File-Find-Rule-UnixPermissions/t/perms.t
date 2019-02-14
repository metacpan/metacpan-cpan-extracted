use strict;

use Test::More qw(no_plan);
use Fcntl ':mode';

BEGIN {
   use_ok('File::Find::Rule::UnixPermissions');
}

# fetch all the files, which are user readable
my @returned=File::Find::Rule::UnixPermissions->file
												->UnixPermissions(include=>[S_IRUSR])
												->in('./test/');
my $joined=join(' ',sort(@returned));
ok( $joined eq 'test/a test/b test/c', 'S_IRUSR') or diag('"'.$joined.'" returned for "a b c"');

# fetch only b, which is the only group writable one that is also user readhable
my @returned=File::Find::Rule::UnixPermissions->file
												->UnixPermissions(include=>[S_IRUSR,S_IWGRP])
												->in('./test/');
my $joined=join(' ',sort(@returned));
ok( $joined eq 'test/b', 'S_IRUSR+S_IWGRP') or diag('"'.$joined.'" returned for "test/b"');

# fetch b and c, one of which is only group executable and the other is the only one that is group writable
my @returned=File::Find::Rule::UnixPermissions->file
												->UnixPermissions(include=>[S_IWGRP,S_IXGRP], any_include=>1)
												->in('./test/');
my $joined=join(' ',sort(@returned));
ok( $joined eq 'test/b test/c', 'S_IXGRP or S_IWGRP') or diag('"'.$joined.'" returned for "test/b test/c"');
