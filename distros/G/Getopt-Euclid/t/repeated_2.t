BEGIN {
    @ARGV = (
        '-compare', 'aaa', 'aaaa',
    );
}

use Getopt::Euclid;
use Test::More 'no_plan';

is ref $ARGV{'-compare'}, 'HASH'          => 'Hash reference returned for -b';
is $ARGV{'-compare'}{old_dir},  'aaa'     => 'Got expected value for -b{first}';
is $ARGV{'-compare'}{new_dir}, 'aaaa'     => 'Got expected value for -b{rest}[0]';


__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 USAGE

    orchestrate  -in source.txt  --out dest.orc  -verbose  -len=24

=head1 OPTIONS

=over

=item -compare <old_dir> <new_dir>

=for Euclid:
    old_dir.type:  string
    new_dir.type: string

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
