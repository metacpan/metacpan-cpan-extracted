package File::DigestStore::Test::Storage;
use Moose;
BEGIN { extends qw/ Test::Class / }
with 'File::DigestStore::Test';

use Test::More;
use Test::Exception;

use File::DigestStore;

sub setup : Test(setup) {
    my($self) = @_;

    $self->storer(File::DigestStore->new(
        root => $self->tmp
    ));
}

sub teardown : Test(teardown) {
    my($self) = @_;
    $self->cleanup_storage;
}

sub test_stable_file_hash : Test(no_plan) {
    my($self) = @_;

    my $id = $self->storer->store_path($0);
    my $id2 = $self->storer->store_path($0);
    is($id, $id2, 'Hash is stable and returns same ID');
}

sub test_stable_string_hash : Test(no_plan) {
    my($self) = @_;

    foreach my $string ('', 'Hello, world', "test\0string", "test\nstring", "test\rstring") {
        # also test scalar store_string
        my $id = $self->storer->store_string($string);
        # also test array store_string
        my($id2, $length) = $self->storer->store_string($string);
        is($id, $id2, 'Hash is stable and returns same ID');
        my $string2 = $self->storer->fetch_string($id);
        is($string2, $string, 'return correct string');
        is($length, length $string, 'return correct length');
    }
}

sub test_exists_ok : Test(no_plan) {
    my($self) = @_;

    my $id = $self->storer->store_string('exists_ok');
    ok($self->storer->exists($id), 'exists() returns true for valid ID');
    $id++;
    ok(!$self->storer->exists($id), 'exists() returns false for invalid ID');
}

sub test_deletes_ok : Test(no_plan) {
    my($self) = @_;

    my $id = $self->storer->store_string('deletes_ok');
    ok($self->storer->delete($id), 'delete() returns true for valid ID');
    $id++;
    ok(!$self->storer->delete($id), 'delete() returns false for invalid ID');
}

sub test_store_missing_file : Test(no_plan) {
    my($self) = @_;

    throws_ok( sub {
                   $self->storer->store_path($self->tmp."/this/is/an/invalid/filename")
               },
               qr/No such file or directory/,
               "fails on unreadable file" );
}

sub test_valid_param : Test(no_plan) {
    my($self) = @_;

    throws_ok( sub { $self->storer->store_path },
               qr/Can't store an undefined filename/,
               "store_path throws on undef" );

    throws_ok( sub { $self->storer->store_string },
               qr/Can't store an undefined string/,
               "store_string throws on undef" );

    throws_ok( sub { $self->storer->store_string({}) },
               qr/Can't store a reference/,
               "store_string throws on reference" );

    throws_ok( sub { $self->storer->fetch_path },
               qr/Can't fetch an undefined ID/,
               "fetch_path throws on undef" );

    throws_ok( sub { $self->storer->fetch_string },
               qr/Can't fetch an undefined ID/,
               "fetch_string throws on undef" );

    throws_ok( sub { $self->storer->exists },
               qr/^Can't check an undefined ID/,
               "exists throws on undef" );

    throws_ok( sub { $self->storer->delete },
               qr/^Can't delete an undefined ID/,
               "delete throws on undef" );
}

sub test_fetch_nonexist : Test(no_plan) {
    my($self) = @_;

    is($self->storer->fetch_path('this ID does not exist'), undef, 'fetch nonexistent');
}

sub deprecated {
    my($self, $name, $cb, $expect) = @_;

    my $warn_count = 0;
    local $SIG{__WARN__} = sub {
        my($warning) = @_;
        if ($warning =~ $expect) {
            $warn_count++;
        } else {
            die "unexpected warning $warning";
        }
    };
    $cb->();
    is($warn_count, 1, "$name warned on first use");
    $cb->();
    is($warn_count, 1, "$name did not re-warn");
    # ugly hack: we reset the flag that suppresses multiple deprecation warnings
    undef $File::DigestStore::deprecated;
}

sub test_deprecated : Test(no_plan) {
    my($self) = @_;

    my $id = $self->storer->store_string('test_deprecated');
    $self->deprecated(
        fetch_file => sub { $self->storer->fetch_file($id) }, qr/^Deprecated fetch_file\(\) called/
    );
    $self->deprecated(
        store_file => sub { $self->storer->store_file($0) }, qr/^Deprecated store_file\(\) called/
    );
}

# FIXME: check permissions

1;
