#! /usr/bin/env perl
# The shebang line above is part of the test

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
        '-v',
        '--timeout', $TIMEOUT,
    );

    chmod 0644, $0;
}

use t::lib::HierDemo2;
use Test::More 'no_plan';

sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

is keys %ARGV, 14 => 'Right number of args returned';

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

# Manual should contain POD from .pl and .pm files
my $man = <<EOS;
=head1 NAME

hier_2.t - Convert a file to Melkor\'s .orc format

\=head1 VERSION

This document refers to hier_2.t version 1.9.4 

\=head1 USAGE

    hier_2.t -i <file> -o= <file> [options]

\=head1 OPTIONS

\=over

\=item size <h>x<w>

Specify height and width

\=item -l[[en][gth]] <l>

Display length [default: 24 ]

\=item -v[erbose]

Print all warnings

\=item --timeout [<min>] [<max>]

\=item --version

\=item --usage

\=item --help

\=item --man

Print the usual program information

\=back



\=head1 AUTHOR

Damian Conway (damian\@conway.org)

\=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in this code.
Bug reports and other feedback are most welcome.

\=head1 COPYRIGHT

Copyright (c) 2002, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)


\=head1 REQUIRED ARGUMENTS

\=over

\=item -i[nfile]  [=]<file>

Specify input file

\=item -o[ut][file]= <file>

Specify output file

\=back




EOS


my $man_test = Getopt::Euclid->man();
is $man_test, $man, 'Man page is as expected';

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

