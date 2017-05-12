use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}

BEGIN {
    $INFILE  = $0;
    $L     = 42;
    $G       = 2;

    @ARGV = (
        "-i", $INFILE,
        "-lgth", $L,
        "-girth", $G,
    );

    chmod 0644, $0;
}

if (eval { require Getopt::Euclid and Getopt::Euclid->import(); 1 }) {
    ok 0 => 'Unexpectedly succeeded';
}
else {
    like $@, qr/Getopt::Euclid: Invalid .excludes value for variable <g>: <g> cannot exclude itself/ => 'Failed as expected';
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

=back

=head1 OPTIONS

=over

=item  -l[[en][gth]] <l>

Display length [default: 24 ]

=for Euclid:
    l.type:     int > 0
    l.default:  24

=item  -girth <g>

Display girth [default: 42 ]

=for Euclid:
    g.default:  42
    g.excludes: g

=back
