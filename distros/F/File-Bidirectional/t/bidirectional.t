#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Fcntl qw/:seek/;
use File::Bidirectional;
use Carp;


# Configuration
my $name    = "bidirectional";
my $file    = "$name.data";
my $verbose = 1;

my @data = init_data("\n") ;
my @test = qw/fwd-once bwd-once fwd-loop bwd-loop fwd-zigzag bwd-zigzag/;
plan( tests => @test  * @data * 5 + 1) ;

# Tests
for my $test (@test) {
    test_data($test, \@data) ;
}
test_close() ;

END {
    unlink $file ;
}

exit ;

sub init_data {
    my ($sep) = @_ ;

    return
    map { s/RS/$sep/g; $_ } map {$_ } 
        '',
        'RS',
        'RSRS',
        'RSRSRS',
        "\015",
        "\015RSRS",
        'abcd',
        "abcdefghijRS",
        "abcdefghijRS" x 512,
        'a' x (8 * 1024),
        'a' x (8 * 1024) . '0',
        '0' x (8 * 1024) . '0',
        'a' x (32 * 1024),
        join( 'RS', '00' .. '99', '' ),
        join( 'RS', '00' .. '99' ),
        join( 'RS', '0000' .. '9999', '' ),
        join( 'RS', '0000' .. '9999' ),
    ;
}

sub test_data {
    my ($test, $data_ref) = @_;
    croak "expected array ref"
        unless defined $data_ref && ref($data_ref) eq 'ARRAY';

    print "$test\n";
    for my $data (@$data_ref) {
        write_file($file, $data) ;
        test_read($test);
        test_tell($test);
    }
}

sub get_config {
    my $test = shift;
    return
        ($test eq 'fwd-once')   ? ('forward', undef)    :
        ($test eq 'bwd-once')   ? ('backward', undef)   :
        ($test eq 'fwd-loop')   ? ('bi',  1)            :
        ($test eq 'bwd-loop')   ? ('bi',  -1)           :
        ($test eq 'fwd-zigzag') ? ('bi', 1)             :
        ($test eq 'bwd-zigzag') ? ('bi', -1)            :
        undef;
}

sub test_read_line {
    my ($bi, $data) = @_;
    while(my $line = $bi->readline()) {
        push(@$data, $line);
    }
}

sub test_loop {
    my ($bi, $data) = @_;
    while(my $line = $bi->readline()) {
        push(@$data, $line);
    }
    $bi->switch();
    while(my $line = $bi->readline()) {
        push(@$data, $line);
    }
    $bi->switch();
    while(my $line = $bi->readline()) {
        push(@$data, $line);
    }
}

sub get_loop {
    return (@_, reverse(@_), @_);
}

sub test_zigzag {
    my ($bi, $data) = @_;
    my $inc = 3;

    while (1) {
        for my $i (1 .. $inc) {
            my $line = $bi->readline();
            return if !defined $line;
            push @$data, $line;
        }
        $bi->switch();

        for my $i (1 .. $inc / 2) {
            push @$data, $bi->readline();
        }
        $bi->switch();
        $inc++;
    }
}

sub get_zigzag {
    my $cur = 0;
    my $inc = 3;
    my @ret;

    while (1) {
        for my $i (1 .. $inc) {
            return @ret if $cur > $#_;
            push @ret, $_[$cur];
            $cur++;
        }
        # simulate staying on the same line when we switch directions
        $cur--;

        for my $i (1 .. $inc / 2) {
            push @ret, $_[$cur];
            $cur--;
        }
        # simulate staying on the same line when we switch directions
        $cur++;

        $inc++;
    }
}

sub test_read {
    my ($test) = @_;
    croak "expected test [fwd-once|bwd-once|fwd-loop|bwd-loop|fwd-zigzag|bwd-zigzag]"
        unless defined $test && $test =~ /^(fwd-once|bwd-once|fwd-loop|bwd-loop|fwd-zigzag|bwd-zigzag)$/;

    # reference data
    my @line    = read_file($file);
    @line       = reverse @line if $test =~ /^bwd-/;
    my @reference   = 
        ($test =~ /-once$/)     ? @line :
        ($test =~ /-loop$/)     ? get_loop(@line) :
        ($test =~ /-zigzag$/)   ? get_zigzag(@line) :
        undef;

    # use File::Bidirectional to read in the lines
    my ($mode, $origin) = get_config($test);
    my $bi = File::Bidirectional->new($file, {
            'mode'      => $mode,
            'origin'    => $origin,
        }) or die "can't open $file: $!" ;

    my (@out);

    if      ($test =~ /-once$/) {
        test_read_line($bi, \@out);
    } elsif ($test eq 'fwd-loop') {
        test_loop($bi, \@out);
    } elsif ($test eq 'bwd-loop') {
        test_loop($bi, \@out);
    } elsif ($test eq 'fwd-zigzag') {
        test_zigzag($bi, \@out);
    } elsif ($test eq 'bwd-zigzag') {
        test_zigzag($bi, \@out);
    }

    # compare the reference lines with the test lines
    if (eq_array(\@reference, \@out)) {
        ok(1, 'read') ;
    } else {
        # test failed so dump the different lines if verbose
        ok(0, 'read') ;

        if ($verbose) {
            require YAML;
            print $bi->_dump();
            print "reference:\n";
            print length(join '', @reference) . " bytes\n";
            print YAML::Dump(\@reference);
            print "output:\n";
            print length(join '', @out) . " bytes\n";
            print YAML::Dump(\@out);
        }
    }

    # test if we close cleanly
    ok($bi->close(), 'close') ;

}

sub test_tell {
    my ($test) = @_;
    croak "expected test [fwd-once|bwd-once|fwd-loop|bwd-loop|fwd-zigzag|bwd-zigzag]"
        unless defined $test && $test =~ /^(fwd-once|bwd-once|fwd-loop|bwd-loop|fwd-zigzag|bwd-zigzag)$/;
    
    # use File::Bidirectional to read in the lines
    my ($mode, $origin) = get_config($test);
    my $bi = File::Bidirectional->new($file, {
            'mode'      => $mode,
            'origin'    => $origin,
        }) or die "can't open $file: $!" ;

    # read a line and obtain a position after
    my $bi_line = $bi->readline() ;
    my $pos = $bi->tell();

    if ($bi->eof()) {
        ok( 1, "skip tell() - at eof" ) ;
        ok( 1, "skip fh() - at eof" ) ;
    } else {
        # open the same file separately, seek to that position and read a line
        open my $fh, $file
            or die "unable to open \"$file\" - $!" ;
        seek $fh, $pos, SEEK_SET
            or die "unable to seek - $!" ;
        my $reference = <$fh>;

        # test if tell() is the same as the real position on the handle
        my $bi_fh = $bi->fh();
        my $separate = <$bi_fh>;
        is ($separate, $reference, "fh() matches tell()"); 

        # File::Bidirectional should still work after you muck with its filehandle!

        # if the origin is at the start of the file, we would have to read the
        # line after tell() to obtain the same results as the reference
        $bi_line = $bi->readline()
            if ($test =~ /^fwd-/);

        is($bi_line, $reference, "tell() check");
    }
    ok($bi->close(), 'close2') ;
}


sub test_close {
    write_file($file, <<EOT) ;
line1
line2
EOT

    my $bi = File::Bidirectional->new($file)
        or die "can't open $file: $!" ;
    $bi->readline() ;
    $bi->close() ;

    # should no longer be able to read
    ok(!defined $bi->readline(), 'close') ;
}

sub read_file {
    my ($file) = @_;

    open my $fh, $file
        or die "unable to open \"$file\" - $!";
    binmode($fh);
    <$fh>
}

sub write_file {
    my ($file, @str) = @_;

    open my $fh, '>', $file
        or die "unable to create \"$file\" - $!";
    binmode($fh);
    print $fh @str;
}
