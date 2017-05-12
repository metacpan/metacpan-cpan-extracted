#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Test::More;
use Logging::Simple;

my $mod = 'Logging::Simple';

{ # open/close
    my $log = $mod->new;

    my $fn = _fname();

    $log->file($fn);

    is ($log->{file}, $fn, "file() stores the file name ok");
    is (ref $log->{fh}, 'GLOB', "file() creates a handle ok");

    $log->file(0);

    is ($log->{file}, undef, "file() deletes the filename correctly");
    is (ref $log->{fh}, '', "file() closes the handle ok with param of 0");

}
{ # write/append
    my $fn = _fname();

    { # write
        my $log = $mod->new;
        $log->file($fn, 'w');
        print { $log->{fh} } "abc";
        $log->file(0);
        my $ret = _fetch($fn);
        is ($ret, 'abc', "write to file ok");
    }
    { # overwrite check
        my $log = $mod->new;
        $log->file($fn, 'w');
        print { $log->{fh} } "def";
        $log->file(0);
        my $ret = _fetch($fn);
        is ($ret, 'def', "write mode overwrites ok");
    }
    { # append
        my $log = $mod->new;
        $log->file($fn, 'a');
        print { $log->{fh} } "ghi";
        $log->file(0);
        my $ret = _fetch($fn);
        is ($ret, 'defghi', "append mode works and acts properly");
    }
}
{ # empty file param
    my $log = $mod->new;
    my $fn = $log->file;

    is ($log->{file}, undef, "file() with no params doesn't set fname");
    is (defined $log->{fh}, '', "file() with no params doesn't set a handle");
    is ($fn, undef, "file() w/ no params returns undef if a file isn't set");

    my $temp = _fname();
    $fn = $log->file($temp);

    is ($fn, $temp, "file() returns file name if one is active");
}

sub _fname {
    my $fh = File::Temp->new(UNLINK => 1);
    my $fn = $fh->filename;
    close $fh;
    return $fn;
}
sub _fetch {
    my $fn = shift;
    open my $fh, '<', $fn or die $!;
    my $ret = <$fh>;
    close $fh;
    return $ret;
}
{ # append mode (write_mode) param in new()
    my $fn = _fname();

    { # write
        my $log = $mod->new(file => $fn, write_mode => 'a');
        print { $log->{fh} } "abc";
        $log->file(0);
        my $ret = _fetch($fn);
        is ($ret, 'abc', "write to file ok");
    }
    { # append
        my $log = $mod->new(file => $fn, write_mode => 'a');
        print { $log->{fh} } "def";
        $log->file(0);
        my $ret = _fetch($fn);
        is ($ret, 'abcdef', "write_mode append in new() works");
    }
}

done_testing();

