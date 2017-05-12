BEGIN {
    $INFILE  = $0;
    $OUTFILE = $0;
    $LEN     = 42;
    $H       = 2;
    $W       = -10;
    $TIMEOUT = 7;

    @ARGV = (
        '-i', $INFILE,
        "-out=$OUTFILE",
        '-lgth', $LEN,
        'size', "${H}x${W}",
        '-no-fudge',
        '-v',
        '--timeout', $TIMEOUT,
        '-w', 's p a c e s',
    );

    chmod 0644, $0;
}

use Getopt::Euclid qw( :defer );
use Test::More 'no_plan';


our $STEP1 = 4;
our $STEP2 = 3;
our $STEPS = { 'extra' => 0.1 };


sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

sub got_arg_exp {
    my ($key, $val) = @_;
    my $var_name = "opt_$key";
    no strict 'refs';
    is ${$var_name}, $val, "Got expected value for $var_name";
}

sub not_arg_exp {
    my ($key, $val) = @_;
    my $var_name = "opt_$key";
    no strict 'refs';
    is ${$var_name}, undef, "$var_name should be undefined";
}


my @args  = @ARGV;
my @args2 = @ARGV;


# Process arguments, no options

is scalar @ARGV, 13 => 'Argument processing was deferred';
is keys %ARGV, 0 => 'Argument processing was deferred';

Getopt::Euclid->process_args(\@ARGV);

is scalar @ARGV, 0 => 'Arguments were processed';
is keys %ARGV, 19 => 'Arguments were processed';

got_arg -i           => $INFILE;
got_arg -infile      => $INFILE;

got_arg -l           => $LEN;
got_arg -len         => $LEN;
got_arg -length      => $LEN;
got_arg -lgth        => $LEN;

got_arg -girth       => 42;

got_arg -o           => $OUTFILE;
got_arg -ofile       => $OUTFILE;
got_arg -out         => $OUTFILE;
got_arg -outfile     => $OUTFILE;

got_arg '--no-fudge' => 1;

got_arg -v           => 1,
got_arg -verbose     => 1,

got_arg -w           => 's p a c e s';

got_arg  '<step>'    => 7.3;

is ref $ARGV{'--timeout'}, 'HASH'     => 'Hash reference returned for timeout';
is $ARGV{'--timeout'}{min}, $TIMEOUT  => 'Got expected value for timeout <min>';
is $ARGV{'--timeout'}{max}, -1        => 'Got default value for timeout <max>';

is ref $ARGV{size}, 'HASH'      => 'Hash reference returned for size';
is $ARGV{size}{h}, $H           => 'Got expected value for size <h>';
is $ARGV{size}{w}, $W           => 'Got expected value for size <w>';

%ARGV = ();


# Process arguments with minimal keys

is scalar @args, 13 => 'Argument processing was deferred';
is keys %ARGV, 0 => 'Argument processing was deferred';

Getopt::Euclid->process_args(\@args, {-minimal_keys => 1});

is scalar @args, 0 => 'Arguments were processed';
is keys %ARGV, 19 => 'Arguments were processed';

got_arg i        => $INFILE;
got_arg infile   => $INFILE;

got_arg l        => $LEN;
got_arg len      => $LEN;
got_arg length   => $LEN;
got_arg lgth     => $LEN;

got_arg girth    => 42;

got_arg o        => $OUTFILE;
got_arg ofile    => $OUTFILE;
got_arg out      => $OUTFILE;
got_arg outfile  => $OUTFILE;

got_arg no_fudge => 1;

got_arg v        => 1,
got_arg verbose  => 1,

got_arg w        => 's p a c e s';

got_arg step     => 7.3;

is ref $ARGV{'timeout'}, 'HASH'     => 'Hash reference returned for timeout';
is $ARGV{'timeout'}{min}, $TIMEOUT  => 'Got expected value for timeout <min>';
is $ARGV{'timeout'}{max}, -1        => 'Got default value for timeout <max>';

is ref $ARGV{size}, 'HASH'      => 'Hash reference returned for size';
is $ARGV{size}{h}, $H           => 'Got expected value for size <h>';
is $ARGV{size}{w}, $W           => 'Got expected value for size <w>';

%ARGV = ();


# Process arguments with variable export

is scalar @args2, 13 => 'Argument processing was deferred';

Getopt::Euclid->process_args(\@args2, {-vars => 'opt_'});

is scalar @args2, 0 => 'Arguments were processed';

not_arg_exp i       => $INFILE;
got_arg_exp infile  => $INFILE;

not_arg_exp l       => $LEN;
not_arg_exp len     => $LEN;
got_arg_exp length  => $LEN;
not_arg_exp lgth    => $LEN;

got_arg_exp girth   => 42;

not_arg_exp o       => $OUTFILE;
not_arg_exp ofile   => $OUTFILE;
not_arg_exp out     => $OUTFILE;
got_arg_exp outfile => $OUTFILE;

not_arg_exp v       => 1,
got_arg_exp verbose => 1,

got_arg_exp w       => 's p a c e s';

got_arg_exp step    => 7.3;

is $opt_timeout{min}, $TIMEOUT  => 'Got expected value for timeout <min>';
is $opt_timeout{max}, -1        => 'Got default value for timeout <max>';

is $opt_size{h}, $H           => 'Got expected value for size <h>';
is $opt_size{w}, $W           => 'Got expected value for size <w>';


__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 USAGE

    orchestrate  -in source.txt  --out dest.orc  -verbose  -len=24

=head1 REQUIRED ARGUMENTS

=over

=item  -i[nfile]  [=]<file>    

Specify input file

=for Euclid:
    file.type:    readable
    file.default: '-'

=item  -o[ut][file]= <out_file>    

Specify output file

=for Euclid:
    out_file.type:    writable
    out_file.default: '-'

=back

=head1 OPTIONS

=over

=item  size <h>x<w>

Specify height and width

=item  -l[[en][gth]] <l>

Display length [default: 24 ]

=for Euclid:
    l.type:    int > 0
    l.default: 24

=item  -girth <g>

Display girth [default: 42 ]

=for Euclid:
    g.default: 42

=item -v[erbose]

Print all warnings

=item [-]-timeout [<min>] [<max>]

=for Euclid:
    min.type: int
    max.type: int
    max.default: -1

=item -w <space>

Test something spaced

=item [-]-no[-fudge]

Automaticaly fudge the factors.

=for Euclid:
    false: [-]-no[-fudge]

=item <step>

Step size.

=for Euclid:
   step.default: $STEP1 + $STEPS->{extra} + $$STEPS{extra} + ${$STEPS}{extra} + $main'STEP2

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=begin remainder of documentation here...

=end

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in this code.
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

Copyright (c) 2002, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
