#!perl -w

use Test qw( plan );
use IPC::Run3;
use strict;

my ( $in, $out, $err ) = @_;

my %e = (
    map( { chr $_ => sprintf( "\\0x%02d", $_ ) } (0..255) ),
    "\n" => "\\n",
    "\r" => "\\r",
);

sub ok {
    @_ = map { ( my $s = $_ ) =~ s/([\000-\037])/$e{$1}/ge; $s } @_;
    goto &Test::ok;
}

my @tests = (
sub {
    eval { run3 };
    ok $@;
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print "OUT"' ], \undef, \$out, \$err;
    ok $out, "OUT";
},

sub {
    ok $err, "";
},

sub {
    ( $in, $out, $err ) = ();
    $out = "STUFF";
    run3 [$^X, '-e', 'print "OUT"' ], \undef, \$out, \$err, { append_stdout => 1 };
    ok $out, "STUFFOUT";
},

sub {
    ( $in, $out, $err ) = ();
    $err = "STUFF";
    run3 [$^X, '-e', 'print STDERR "OUT"' ], \undef, \$out, \$err, { append_stderr => 1 };
    ok $out, "";
},

sub {
    ok $err, "STUFFOUT";
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print map uc, <>' ], \"in", \$out, \$err;
    ok $out, "IN";
},

sub {
    ok $err, "";
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print STDERR map uc, <>' ], \"in", \$out, \$err;
    ok $out, "";
},

sub {
    ok $err, "IN";
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print map uc, <>' ], [qw( in1 in2 )], \$out;
    ok $out, "IN1IN2";
},

sub {
    ( $in, $out, $err ) = ();
    my @ary;
    run3 [$^X, '-e', 'print map uc, <>' ], [qw( in1 in2 )], \$out;
    ok $out, "IN1IN2";
},

sub {
    ( $in, $out, $err ) = ();
    my @out;
    run3 [$^X, '-e', 'print "OUT1\nOUT2"' ], \undef, \@out, \$err;
    ok scalar(@out), 2;
    $out = join('', @out);
},
sub {
    ok $out, "OUT1\nOUT2";
},

sub {
    ( $in, $out, $err ) = ();
    my @out = ("STUFF\n");
    run3 [$^X, '-e', 'print "OUT1\nOUT2"' ], \undef, \@out, \$err, { append_stdout => 1 };
    ok scalar(@out), 3;
    $out = join('', @out);
},
sub {
    ok $out, "STUFF\nOUT1\nOUT2";
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print map { length($_)."[$_]" } <>' ], \"in1\nin2", \$out;
    ok $out, "4[in1\n]3[in2]";
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'binmode STDIN; binmode STDOUT; print map { length($_)."[$_]" } <>' ],
        \"in1\nin2", \$out,
        { binmode_stdin => 1 };
    ok $out, "4[in1\n]3[in2]";
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'binmode STDIN; binmode STDOUT; print map { length($_)."[$_]" } <>' ],
        \"in1\r\nin2", \$out,
        { binmode_stdin => 1, binmode_stdout => 1 };
    ok $out, "5[in1\r\n]3[in2]";
},

sub {
    ( $in, $out, $err ) = ();
    my @in = qw( in1 in2 );
    run3 [$^X, '-e', 'print map uc, <>' ], sub { shift @in }, \$out;
    ok $out, "IN1IN2";
},

sub {
    ( $in, $out, $err ) = ();
    my @out;
    run3 [$^X, '-e', 'print map uc, <>' ], \"in1\nin2", sub { push @out, shift };
    ok scalar(@out), 2;
    $out = join('', @out);
},
sub {
    ok $out, "IN1\nIN2";
},

sub {
    ( $in, $out, $err ) = ();
    run3 [$^X, '-e',
        '$|=1; select STDERR; $| = 1; for (<>){print STDOUT uc;print STDERR lc}'
    ], \"in1\nin2\n", \$out,\$out;
    ok $out, "IN1\nin1\nIN2\nin2\n";
},

sub {
    my $fn = "t/test.txt";
    unlink $fn or warn "$! unlinking $fn" if -e $fn;

    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print "OUT"' ], \undef, $fn;
    ok -s $fn, 3;
},

sub {
    my $fn = "t/test.txt";
    unlink $fn or warn "$! unlinking $fn" if -e $fn;
    open FH, ">", $fn  or warn "$! opening $fn";
    print FH "STUFF";
    close FH;

    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print "OUT"' ], \undef, $fn, { append_stdout => 1 };
    ok -s $fn, 8;
},

sub {
    my $fn = "t/test.txt";
    open FH, ">", $fn or warn "$! opening $fn";

    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print "OUT"' ], \undef, \*FH;

    close FH;
    ok -s $fn, 3;
},

sub {
    my $fn = "t/test.txt";
    unlink $fn or warn "$! unlinking $fn" if -e $fn;
    open FH, ">", $fn or warn "$! opening $fn";
    print FH "IN1\nIN2\n";
    close FH;

    open FH, "<", $fn or warn "$! opening $fn";

    ( $in, $out, $err ) = ();
    run3 [$^X, '-e', 'print <>' ], \*FH, \$out;

    close FH;
    ok $out, "IN1\nIN2\n";
},

# check that run3 doesn't die on platforms where system()
# returns -1 when SIGCHLD is ignored (RT #14272)
sub {
  use Config;

  if ( $^O eq 'openbsd' and $Config{'useithreads'} ) {
    ok(1); # Bug in OpenBSD threaded perls causes a hang
  }
  else {

      my $system_child_error = eval
      {
	      local $SIG{CHLD} = "IGNORE";
	      system $^X, '-e', 0;
	      $?;
      };
      my $run3_child_error = eval
      {
	      local $SIG{CHLD} = "IGNORE";
	      run3 [ $^X, '-e', 0 ], \undef, \undef, \undef, { return_if_system_error => 1 };
	      $?;
      };
      ok $run3_child_error, $system_child_error;

  }
},
);

plan tests => 0+@tests;

$_->() for @tests;
