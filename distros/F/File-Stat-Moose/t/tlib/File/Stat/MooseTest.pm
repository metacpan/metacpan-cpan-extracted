package File::Stat::MooseTest;

use strict;
use warnings;

use Test::Unit::Lite;
use parent 'Test::Unit::TestCase';

use Test::Assert ':all';

use File::Stat::Moose;

use constant::boolean;
use Exception::Base;

use File::Spec;
use File::Temp;

our ($file, $symlink, $notexistant);

sub set_up {
    $file = __FILE__;
    $symlink = File::Temp::tmpnam();
    $notexistant = '/MooseTestNotExistant';

    eval {
        symlink File::Spec->rel2abs($file), $symlink;
    };
    $symlink = undef if $@;
};

sub tear_down {
    unlink $symlink if $symlink;
};

sub test_new_file {
    my $obj = File::Stat::Moose->new( file => $file );
    assert_isa('File::Stat::Moose', $obj);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^-?\d+$/, $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    assert_not_equals(0, $obj->size);
};

sub test_new_file_strict_accessors {
    my $obj = File::Stat::Moose->new( file => $file, strict_accessors => 1 );
    assert_isa('File::Stat::Moose', $obj);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^-?\d+$/, $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    assert_not_equals(0, $obj->size);
};

sub test_new_file_sloppy {
    my $obj = File::Stat::Moose->new( file => $file, sloppy => TRUE );
    assert_isa('File::Stat::Moose', $obj);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^-?\d+$/, $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    assert_not_equals(0, $obj->size);
};

sub test_new_symlink {
    return unless $symlink;

    my $obj1 = File::Stat::Moose->new( file => $symlink );
    assert_isa('File::Stat::Moose', $obj1);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^-?\d+$/, $obj1->$attr, $attr) if defined $obj1->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj1->$attr, $attr) if defined $obj1->$attr;
        };
    };
    assert_not_equals(0, $obj1->size);

    my $obj2 = File::Stat::Moose->new( file => $symlink, follow => 1 );
    assert_isa('File::Stat::Moose', $obj2);
    assert_not_equals(0, $obj2->size);

    assert_not_equals($obj1->ino, $obj2->ino);
};

sub test_new_symlink_strict_accessors {
    return unless $symlink;

    my $obj1 = File::Stat::Moose->new( file => $symlink, strict_accessors => 1 );
    assert_isa('File::Stat::Moose', $obj1);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^-?\d+$/, $obj1->$attr, $attr) if defined $obj1->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj1->$attr, $attr) if defined $obj1->$attr;
        };
    };
    assert_not_equals(0, $obj1->size);

    my $obj2 = File::Stat::Moose->new( file => $symlink, follow => 1, strict_accessors => 1 );
    assert_isa('File::Stat::Moose', $obj2);
    assert_not_equals(0, $obj2->size);

    assert_not_equals($obj1->ino, $obj2->ino);
};

sub test_new_error_args {
    assert_raises( qr/is required/, sub {
        my $obj = File::Stat::Moose->new;
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => undef );
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => \1 );
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => (bless {} => 'My::Class') );
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => $file, follow => \1 );
    } );
};

sub test_new_error_io {
    assert_raises( ['Exception::IO'], sub {
        my $obj = File::Stat::Moose->new( file => $notexistant );
    } );
};

sub test__deref_array {
    my $obj = File::Stat::Moose->new( file => $file );
    assert_isa('File::Stat::Moose', $obj);
    assert_equals(13, scalar @$obj);
    {
        foreach my $i (0..12) {
            assert_matches(qr/^\d+$/, $obj->[$i], $i) if defined $obj->[$i];
        };
    };
    assert_not_equals(0, $obj->[7]);
};

sub test__deref_array_strict_accessors {
    my $obj = File::Stat::Moose->new( file => $file, strict_accessors => 1 );
    assert_isa('File::Stat::Moose', $obj);
    assert_equals(13, scalar @$obj);
    {
        foreach my $i (0..12) {
            assert_matches(qr/^\d+$/, $obj->[$i], $i) if defined $obj->[$i];
        };
    };
    assert_not_equals(0, $obj->[7]);
};

sub test_stat {
    my $file = File::Temp->new;
    assert_isa('File::Temp', $file);
    $file->autoflush(1);
    $file->print(1);

    my $obj = File::Stat::Moose->new( file => $file );
    assert_equals(1, $obj->size);

    $file->print(2);

    $obj->stat;
    assert_equals(2, $obj->size);
};

sub test_stat_error_args {
    my $obj = File::Stat::Moose->new( file => $file );

    assert_raises( ['Exception::Argument'], sub {
        File::Stat::Moose->stat;
    } );

    assert_raises( ['Exception::Argument'], sub {
        $obj->stat(1);
    } );
};

1;
