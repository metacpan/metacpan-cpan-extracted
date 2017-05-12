#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Path qw/rmtree/;
use File::LogReader;

BEGIN {
    if ($^O =~/Win32/) {
        plan skip_all => 'Not supported on windows, patches accepted';
    }
    else {
        plan tests => 19;
    }
}

my $state_dir = "t/state.$$";
END { rmtree $state_dir if $state_dir }

Read_a_static_file: {
    my $test_file = write_file("one\ntwo\n");

    Initial_read_without_state: {
        my $lr = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        is $lr->read_line, "one\n";
        is $lr->read_line, "two\n";
        is $lr->read_line, undef;
        $lr->commit;
    }

    Subsequent_read: {
        my $lr = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        is $lr->read_line, undef, 'nothing new to read';
    }

    New_data_on_file: {
        write_file("three\n", $test_file);
        my $lr = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        is $lr->read_line, "three\n", 'read a third line';
        is $lr->read_line, undef, 'nothing new to read';
        $lr->commit;
    }

    Position_not_saved_on_commit: {
        write_file("four\n", $test_file);
        my $lr = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        is $lr->read_line, "four\n", 'read a fourth line';
        is $lr->read_line, undef, 'nothing new to read';

        $lr = undef;

        $lr = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        is $lr->read_line, "four\n", 'read a fourth line again';
        is $lr->read_line, undef, 'nothing new to read';
        $lr->commit;
    }

    File_truncated: {
        write_file("one\ntwo\n", $test_file, 'overwrite it');
        my $lr = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        is $lr->read_line, "one\n";
        is $lr->read_line, "two\n";
        is $lr->read_line, undef;
        $lr->commit;
    }

    File_totally_different: {
        write_file("three\nfour\n", $test_file, 'overwrite it');
        my $lr = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        is $lr->read_line, "three\n";
        is $lr->read_line, "four\n";
        is $lr->read_line, undef;
        $lr->commit;
    }
}

Locking: {
    my $test_file = write_file("monkey\n");

    No_multiple_access: {
        my $first = File::LogReader->new( 
            filename => $test_file,
            state_dir => $state_dir,
        );
        ok $first, 'locker got the file';
        my $second = File::LogReader->new(
            filename => $test_file,
            state_dir => $state_dir,
        );
        ok !$second, 'second logreader is undef';

        $first->read_line;
        $first->commit; # should release the lock

        my $third = File::LogReader->new(
            filename => $test_file,
            state_dir => $state_dir,
        );
        ok $third, 'third logreader gets the lock';
    }
}

exit;

{
    my @to_delete;

    sub write_file {
        my $content  = shift;
        my $filename = shift || "t/tmp.$$";
        my $new      = shift;

        unlink $filename if $new;

        open(my $fh, ">>$filename") or die "Can't open $filename: $!";
        print $fh $content;
        close $fh or die "Can't write $filename: $!";
        push @to_delete, $filename;
        return $filename;
    }

    END { unlink $_ for @to_delete }
}
