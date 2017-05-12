BEGIN {
    $INFILE  = $0;
    $OUTFILE = $0;

    @ARGV = (
        '-i', $INFILE,
        "-out=$OUTFILE",
    );

    chmod 0644, $0;
}

sub lucky {
    my ($num) = @_;
    return $num == 7;
}

use Getopt::Euclid;
use Test::More 'no_plan';

my $help = <<EOS;
\=head1 Usage:

       insert_defaults.t -i <file> -o= <out_file> [options]
       insert_defaults.t --help
       insert_defaults.t --man
       insert_defaults.t --usage
       insert_defaults.t --version

\=head1 Required arguments:

\=over

\=item -i[nfile]  [=]<file>

Specify input file [default: -]

\=item -o[ut][file]= <out_file>

Specify output file [default: -]

\=back



\=head1 Options:

\=over

\=item size [<h>]x[<w>]

Specify height and width [optional default: 1.8 x 0.2]

\=item -l[[en][gths]] <l>...

Display lengths [default: 24 36.3 10]

\=item -girth <g value>

Display girth [default: 42]

\=item -v[erbose]

Print all warnings

\=item --timeout [<min>] [<max>]

[default: min=none and max=-1]
[optional default: min=none and max=-3]

\=item -w <space> | --with <space>

Test something spaced

\=item <step>

Step size [default: none]

\=item --version

\=item --usage

\=item --help

\=item --man

Print the usual program information

\=back



EOS


my $help_test = Getopt::Euclid->help();
is $help_test, $help => 'Help has correct default values displayed';



my $man = <<EOS;
\=head1 NAME

insert_defaults.t - Convert a file to Melkor's .orc format

\=head1 VERSION

This document refers to insert_defaults.t version 1.9.4 

\=head1 USAGE

    insert_defaults.t -i <file> -o= <out_file> [options]

\=head1 REQUIRED ARGUMENTS

\=over

\=item -i[nfile]  [=]<file>

Specify input file [default: -]

\=item -o[ut][file]= <out_file>

Specify output file [default: -]

\=back



\=head1 OPTIONS

\=over

\=item size [<h>]x[<w>]

Specify height and width [optional default: 1.8 x 0.2]

\=item -l[[en][gths]] <l>...

Display lengths [default: 24 36.3 10]

\=item -girth <g value>

Display girth [default: 42]

\=item -v[erbose]

Print all warnings

\=item --timeout [<min>] [<max>]

[default: min=none and max=-1]
[optional default: min=none and max=-3]

\=item -w <space> | --with <space>

Test something spaced

\=item <step>

Step size [default: none]

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


my $man_test = Getopt::Euclid->man();
is $man_test, $man  => 'Man has correct default values displayed';

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

Specify input file [default: file.default]

=for Euclid:
    file.type:    readable
    file.default: '-'

=item  -o[ut][file]= <out_file>    

Specify output file [default: out_file.default]

=for Euclid:
    out_file.type:    writable
    out_file.default: '-'

=back

=head1 OPTIONS

=over

=item  size [<h>]x[<w>]

Specify height and width [optional default: h.opt_default x w.opt_default]

=for Euclid:
    h.type: number > 0
    h.opt_default: 1.8
    w.type: number > 0
    w.opt_default: 0.2

=item  -l[[en][gths]] <l>...

Display lengths [default: l.default]

=for Euclid:
    l.type:    int > 0
    l.default: [ 24, 36.3, 10 ]

=item  -girth <g value>

Display girth [default: g value.default]

=for Euclid:
    g value.default: 42

=item -v[erbose]

Print all warnings

=item --timeout [<min>] [<max>]

[default: min=min.default and max=max.default]
[optional default: min=min.opt_default and max=max.opt_default]

=for Euclid:
    min.type: int
    max.type: int
    max.default: -1
    max.opt_default: -3

=item -w <space> | --with <space>

Test something spaced

=item <step>

Step size [default: step.default]

=for Euclid:
    step.type: int, lucky(step)

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
