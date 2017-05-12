# Test the constructor, specifically manual specification of
# index_file and temp => 1.
# Basic use case (no manual index_file) tested by 02extract.t

use strict;
use warnings;
use Test::More tests => 32;

our $no_test_exception;
BEGIN {
    eval "use Test::Exception";
    $no_test_exception = 1 if $@;
}

use Carp;
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use FindBin;
use Gzip::RandomAccess;

my $file = catfile($FindBin::Bin, 'fixtures', 'seq.gz');
my $index = catfile($FindBin::Bin, 'fixtures', 'seq.gz.idx');
my $backup_index = catfile($FindBin::Bin, 'fixtures', 'seq.gz.idx.backup');
my $mtime;

# Make an index now, for testing
delete_index_if_exists($backup_index);
Gzip::RandomAccess->new(file => $file, index_file => $backup_index);
ok( index_exists($backup_index), 'backup index OK' )
    or BAIL_OUT('Need backup index to perform remaining tests');

sub test;  # abstract the setup/teardown stuff

# First use
test {
    main => sub {
        my $gzip = shift;
        ok( !$gzip->cleanup );
        ok( index_exists($index), 'user index created' );
    }
};

# Index already exists
test {
    with => ['existing_index'],
    before => sub {
        $mtime = index_mtime($index);
    },
    main => sub {
        my $gzip = shift;
        ok( !$gzip->cleanup );
        my $new_mtime = index_mtime($index);
        is( $mtime, $new_mtime, 'index not re-created' );
        ok( index_exists($index), 'user index still present' );
    },
    after => sub {
        ok( index_exists($index), 'user index still present (out of scope)' );
    }
};

# Temp index
test {
    with => ['cleanup'],
    main => sub {
        ok( shift->cleanup );
    },
    after => sub {
        ok( !index_exists($index), 'user index deleted when $gzip left scope' );
    }
};

# Temp index, but already exists
test {
    with => ['cleanup', 'existing_index'],
    before => sub {
        $mtime = index_mtime($index);
    },
    main => sub {
        ok( shift->cleanup );
        my $new_mtime = index_mtime($index);
        is( $mtime, $new_mtime, 'index not re-created' );
    },
    after => sub {
        ok( !index_exists($index), "index deleted (even if existing)" );
    },
};

my $gzip = Gzip::RandomAccess->new({
    file => $file,
    index_file => $index,
});
ok( $gzip, 'hashref argument style' );

SKIP: {
    skip "Test::Exception needed for exception tests" => 3 if $no_test_exception;
    for my $sub (qw(file index_file cleanup)) {
        throws_ok { $gzip->$sub(1) } qr/^Usage:/, "$sub usage";
    }
}

delete_index_if_exists($index);
delete_index_if_exists($backup_index);

sub test {
    my $test = shift;
    my %with = map { $_ => 1 } @{$test->{with} || []};
    my %args = (
        file => $file,
        index_file => $index,
    );
    $args{cleanup} = 1 if $with{cleanup};

    delete_index_if_exists($index);    
    if ($with{existing_index}) {
        copy($backup_index, $index) or die "Copy failed: $!";
    }

    $test->{before}->() if $test->{before};
    {
        my $gzip = Gzip::RandomAccess->new(%args);
        ok( defined $gzip, 'object created' );
        ok( $gzip->index_available, 'index available' );
        is( $gzip->file, $file, 'file' );
        is( $gzip->index_file, $index, 'index_file' );
        $test->{main}->($gzip) if $test->{main};
    }

    $test->{after}->() if $test->{after};

    delete_index_if_exists($index);
}

sub index_exists {
    my $index = shift;
    return -f $index;
}

sub index_mtime {
    my $index = shift;
    return (stat($index))[9];
}

sub delete_index_if_exists {
    my $index = shift;
    unlink($index) or do {
        croak $! unless $! =~ /No such file or directory/;
    }
}
