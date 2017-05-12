BEGIN {
    $LEN     = 42;
    $H       = 2;
    $W       = -10;
    $TIMEOUT = 7;

    @ARGV = (
        '-lgth', $LEN,
        'size', "${H}x${W}",
        '-v',
        '--timeout', $TIMEOUT,
    );

    @args = @ARGV;

    chmod 0644, $0;
}

use Test::More 'no_plan';
use Getopt::Euclid;

sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

# Let's parse an array of arguments instead of @ARGV and repeat the same tests
Getopt::Euclid->process_args(\@args);

is keys %ARGV, 8 => 'Right number of args returned';

got_arg -i       => $INFILE;
got_arg -infile  => $INFILE;

got_arg -l       => $LEN;
got_arg -len     => $LEN;
got_arg -length  => $LEN;
got_arg -lgth    => $LEN;

got_arg -o       => $OUTFILE;
got_arg -ofile   => $OUTFILE;
got_arg -out     => $OUTFILE;
got_arg -outfile => $OUTFILE;

got_arg -v       => 1,
got_arg -verbose => 1,

is ref $ARGV{'--timeout'}, 'HASH'     => 'Hash reference returned for timeout';
is $ARGV{'--timeout'}{min}, $TIMEOUT  => 'Got expected value for timeout <min>';
ok !defined $ARGV{'--timeout'}{max}   => 'Got expected value for timeout <max>';

is ref $ARGV{size}, 'HASH'      => 'Hash reference returned for size';
is $ARGV{size}{h}, $H           => 'Got expected value for size <h>';
is $ARGV{size}{w}, $W           => 'Got expected value for size <w>';

__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 USAGE

    orchestrate  -in source.txt  --out dest.orc  -verbose  -len=24

=head1 OPTIONS

=over

=item  size <h>x<w>

Specify height and width

=item  -l[[en][gth]] <l>

Display length [default: 24 ]

=for Euclid:
    l.type:    int > 0
    l.default: 24

=item -v[erbose]

Print all warnings

=item --timeout [<min>] [<max>]

=for Euclid:
    min.type: int
    max.type: int

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
