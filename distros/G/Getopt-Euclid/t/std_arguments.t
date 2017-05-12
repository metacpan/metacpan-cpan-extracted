BEGIN {
    $INFILE  = $0;
    $OUTFILE = $0;

    @ARGV = (
        '-i', $INFILE,
        "-out=$OUTFILE",
    );

    chmod 0644, $0;
}

use Getopt::Euclid qw( :minimal_keys );
use Test::More 'no_plan';


my $man = <<EOS;
\=head1 NAME

std_arguments.t - Convert a file to Melkor's .orc format

\=head1 SYNOPSIS

   my \$var = 'asdf';

\=head1 VERSION

This document refers to std_arguments.t version 1.9.4 

\=head1 USAGE

    std_arguments.t -i <file> -o= <out_file> [options]

\=head1 REQUIRED ARGUMENTS

\=over

\=item -i[nfile]  [=]<file>

Specify input file

\=item -o[ut][file]= <out_file>

Specify output file

\=back



\=head1 OPTIONS

\=over

\=item size <h>x<w>

Specify height and width

\=item -l[[en][gth]] <l>

Display length [default: 24 ]

\=item -girth <g>

Display girth [default: 42 ]

\=item -v[erbose]

Print all warnings

\=item [-]-timeout [<min>] [<max>]

\=item -w <space>

Test something spaced

\=item [-]-no[-fudge]

Automaticaly fudge the factors.

\=item <step>

Step size

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

EOS


my $podfile = "# This file was generated dynamically by Getopt::Euclid. Do not edit it.\n\n$man";

my $help = <<EOS;
\=head1 Usage:

       std_arguments.t -i <file> -o= <out_file> [options]
       std_arguments.t --help
       std_arguments.t --man
       std_arguments.t --usage
       std_arguments.t --version

\=head1 Required arguments:

\=over

\=item -i[nfile]  [=]<file>

Specify input file

\=item -o[ut][file]= <out_file>

Specify output file

\=back



\=head1 Options:

\=over

\=item size <h>x<w>

Specify height and width

\=item -l[[en][gth]] <l>

Display length [default: 24 ]

\=item -girth <g>

Display girth [default: 42 ]

\=item -v[erbose]

Print all warnings

\=item [-]-timeout [<min>] [<max>]

\=item -w <space>

Test something spaced

\=item [-]-no[-fudge]

Automaticaly fudge the factors.

\=item <step>

Step size

\=item --version

\=item --usage

\=item --help

\=item --man

Print the usual program information

\=back



EOS

my $usage = <<EOS;
Usage:
       std_arguments.t -i <file> -o= <out_file> [options]
       std_arguments.t --help
       std_arguments.t --man
       std_arguments.t --usage
       std_arguments.t --version
EOS

my $version = <<EOS;
This is std_arguments.t version 1.9.4

Copyright (c) 2002, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
EOS


my $man_test = Getopt::Euclid->man();
is $man_test, $man         => 'Correct man message';

my $file = Getopt::Euclid->podfile();
ok -e $file                => 'Podfile was created';
my $podfile_test = '';
open my $in, '<', $file or die "Could not open file $file\n$!\n";
while (<$in>) {
  $podfile_test .= $_;
}
close $in;
is $podfile_test, $podfile => 'Correct podfile content';
unlink $file;

my $help_test = Getopt::Euclid->help();
is $help_test, $help       => 'Correct help message';

my $usage_test = Getopt::Euclid->usage();
is $usage_test, $usage     => 'Correct usage message';

my $version_test = Getopt::Euclid->version();
is $version_test, $version => 'Correct version message';

SKIP: {
    skip 'Need Pod::Checker for this tests', 3 unless eval { require Pod::Checker };

    require Pod::Checker;

    open my $pod_fh, '<', \$man;
    my $nof_errors = Pod::Checker::podchecker( $pod_fh );
    is $nof_errors, 0;
    close $pod_fh;

    open $pod_fh, '<', \$podfile_test;
    $nof_errors =  Pod::Checker::podchecker( $pod_fh );
    is $nof_errors, 0;
    close $pod_fh;

    open $pod_fh, '<', \$help_test;
    $nof_errors =  Pod::Checker::podchecker( $pod_fh );
    is $nof_errors, 0;
    close $pod_fh;

}

__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 SYNOPSIS

   my $var = 'asdf';

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

Step size

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
