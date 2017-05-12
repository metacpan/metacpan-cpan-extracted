use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}

BEGIN {
    $OUTFILE = $0;
    $INFILE  = 'nexistpas';
    $LEN     = 42;
    $H       = 2;
    $W       = -10;
    $TIMEOUT = 7;

    @ARGV = (
        '-v',
        "-out=", $OUTFILE,
        "size", "${H}x${W}",
        "-i", $INFILE,
        "-lgth", $LEN,
        "--timeout", $TIMEOUT,
    );
}


if (eval { require Getopt::Euclid and Getopt::Euclid->import(); 1 }) {
    ok 0 => 'Unexpectedly succeeded';
}
else {
    like $@, qr/Invalid constraint: min.type: int\n\(No <min> placeholder in argument: --foo <bar>/ => 'Failed as expected'; 
}

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

=item  -o[ut][file]= <file>    

Specify output file

=for Euclid:
    file.type:    writable
    file.default: '-'

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

=item -v[erbose]

Print all warnings

=item --timeout [<min>] [<max>]

=item --foo <bar>

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
