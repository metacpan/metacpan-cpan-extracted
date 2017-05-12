BEGIN {
    @ARGV = (
        '-e1with space1',
        '-e2', 'with space2',
        '-e3', 'with',
        'space3',
    );
    # This is equivalent to running:
    #    quoted_args.t -e1"with space1" -e2 "with space2" -e3 with space3
    # or:
    #    quoted_args.t -e1with\ space1 -e2 with\ space2 -e3 with space3
}

use Getopt::Euclid;
use Test::More 'no_plan';

sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

is keys %ARGV, 4 => 'Right number of args returned';

got_arg -e1 => 'with space1';
got_arg -e2 => 'with space2';
got_arg -e3 => 'with';
got_arg '<remainder>' => 'space3';

__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 USAGE

    orchestrate  -in source.txt  --out dest.orc  -verbose  -len=24

=head1 OPTIONS

=over

=item -e1 <text>

=item -e2 <text>

=item -e3 <text>

=item <remainder>

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
