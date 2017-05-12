#!perl

use strict;
use warnings;

use Test::More;

use Git::ObjectStore;
use File::Temp;
use Data::Dumper;

my $tmpdir = File::Temp->newdir();
my $tmpdirname = $tmpdir->dirname();
ok(defined($tmpdirname), 'created temporary dir: ' . $tmpdirname);

my $writer = new Git::ObjectStore('repodir' => $tmpdirname,
                                  'branchname' => 'test1',
                                  'writer' => 1);

ok( ref($writer), 'created a writer Git::ObjectStore');

my $doc = $writer->read_file('docs/001c');
ok(! defined($doc), 'read nonexistent file');

ok(! $writer->file_exists('docs/001c'), 'file_exists returns false');

my $changed = $writer->write_and_check('docs/001c', 'data1');
ok($changed, 'write_file returns true');

$changed = $writer->write_and_check('docs/001c', 'data1');
ok(! $changed, 'write_file returns false');

$doc = $writer->read_file('docs/001c');
ok($doc eq 'data1', 'read_file returned our document');

my %more_data1 =
    (
     'xx1' => 'blahblah',
     'xx2/xy2' => 'foobar',
     'aaa' => 'AAAAA',
     'bbb/bb/bbb/bb' => 'BBBBBBB'
    );

while(my ($file, $data) = each %more_data1 ) {
    $writer->write_file($file, $data);
}

ok(1, 'wrote more data');

$changed = $writer->create_commit_and_packfile();
ok($changed, 'create_commit_and_packfile returns true');

$changed = $writer->create_commit_and_packfile();
ok(! $changed, 'create_commit_and_packfile returns false');

my $old_commit_id = $writer->current_commit_id();
ok(defined($old_commit_id) && length($old_commit_id) == 40,
   'current_commit_id returned a 40-character string');


my $reader = new Git::ObjectStore('repodir' => $tmpdirname,
                                  'branchname' => 'test1');
ok(ref($reader), 'created a reader Git::ObjectStore');

ok($reader->current_commit_id() eq $old_commit_id,
   'Reader current_commit_id returns the same as writer');

while(my ($file, $data) = each %more_data1 ) {
    my $rdata = $reader->read_file($file);
    is($rdata, $data, 'read_file returned the same content for ' . $file);
}

my %read1;
my $cb_read1 = sub {
    my ($path, $data) = @_;
    $read1{$path} = $data;
};

$reader->recursive_read('', $cb_read1);
cmp_ok(scalar(keys %read1), '==', 5, 'recursive_read returned 5 entries');
while(my ($file, $data) = each %more_data1 ) {
    is($read1{$file}, $data,
       'recursive_read returned the same content for ' . $file);
}

is($read1{'docs/001c'}, 'data1',
   'recursive_read returned content for docs/001c');


my %more_data2 =
    (
     'xx1' => 'blahblahXXXX',
     'bbb/bb/bbb/bb' => 'bbbbbxxxx',
     'zzz/zzz1' => 'ZZZZZZ',
    );
while(my ($file, $data) = each %more_data2 ) {
    $writer->write_file($file, $data);
}
ok(1, 'wrote more data');

$writer->delete_file('xx2/xy2');
$writer->delete_file('aaa');
ok(1, 'deleted 2 files');


$changed = $writer->create_commit_and_packfile();
ok($changed, 'create_commit_and_packfile returns true');

ok($writer->current_commit_id() ne $old_commit_id,
   'Writer current_commit_id returns a new commit');

$reader = new Git::ObjectStore('repodir' => $tmpdirname,
                               'branchname' => 'test1');
ok(ref($reader), 'created a reader Git::ObjectStore');

ok($reader->current_commit_id() ne $old_commit_id,
   'Reader current_commit_id returns a new commit');

ok($writer->file_exists('docs/001c'), 'file_exists returns true');

my %read2;
my $cb_read2 = sub {
    my ($path, $data) = @_;
    $read2{$path} = $data;
};

$reader->recursive_read('bbb/bb', $cb_read2);
cmp_ok(scalar(keys %read2), '==', 1, 'recursive_read returned 1 entry');

cmp_ok($read2{'bbb/bb/bbb/bb'}, 'eq', 'bbbbbxxxx',
       'recursive_read returned a new value');


my %file_updated;
my %file_deleted;
my $cb_updated = sub {
    my ($path, $data) = @_;
    $file_updated{$path} = $data;
};
my $cb_deleted = sub {
    my ($path) = @_;
    $file_deleted{$path} = 1;
};
$reader->read_updates($old_commit_id, $cb_updated, $cb_deleted);

cmp_ok(scalar(keys %file_updated), '==', 3, 'read_updates: 3 files updated');
cmp_ok(scalar(keys %file_deleted), '==', 2, 'read_updates: 2 files deleted');

while(my ($file, $data) = each %more_data2 ) {
    cmp_ok($file_updated{$file}, 'eq', $data,
           'read_updates returns content for ' . $file);
}

foreach my $file ('xx2/xy2', 'aaa') {
    ok($file_deleted{$file}, 'read_updates reports deleted file: ' . $file);
}

# no_content reading
my %read3;
my $cb_read3 = sub {
    my ($path) = @_;
    $read3{$path} = 1;
};
$reader->recursive_read('', $cb_read3);
cmp_ok(scalar(keys %read3), '==', 4, 'recursive_read returned 4 entries');
while(my ($file, $data) = each %more_data2 ) {
    cmp_ok($read3{$file}, '==', 1,
           'recursive_read found ' . $file);
}

%read3 = ();
$reader->recursive_read('bbb', $cb_read3);
cmp_ok(scalar(keys %read3), '==', 1, 'recursive_read returned 1 entry');
cmp_ok($read3{'bbb/bb/bbb/bb'}, '==', 1,
       'recursive_read returned a correct entry');


# no_content updates

%file_updated = ();
%file_deleted = ();
my $cb_updated2 = sub {
    my ($path) = @_;
    $file_updated{$path} = 1;
};
my $cb_deleted2 = sub {
    my ($path) = @_;
    $file_deleted{$path} = 1;
};
$reader->read_updates($old_commit_id, $cb_updated2, $cb_deleted2, 1);

cmp_ok(scalar(keys %file_updated), '==', 3, 'read_updates: 3 files updated');
cmp_ok(scalar(keys %file_deleted), '==', 2, 'read_updates: 2 files deleted');

while(my ($file, $data) = each %more_data2 ) {
    cmp_ok($file_updated{$file}, '==', 1,
           'read_updates returns an entry for ' . $file);
}

foreach my $file ('xx2/xy2', 'aaa') {
    ok($file_deleted{$file}, 'read_updates reports deleted file: ' . $file);
}


done_testing;


# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
