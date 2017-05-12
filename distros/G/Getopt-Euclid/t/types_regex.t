BEGIN {
    @ARGV = (
        "-h=hostname1234",
        "-dim=3,4",
    );
}

use Getopt::Euclid;

use Test::More 'no_plan';

sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

is $ARGV{'-h'}{dev},  'hostname'  => 'Got expected value for -h <dev>';
is $ARGV{'-h'}{port}, 1234        => 'Got expected value for -h <port>';
is $ARGV{'-dim'}, '3,4'           => 'Got expected value for -dim';

__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 USAGE

    orchestrate  -in source.txt  --out dest.orc  -verbose  -len=24

=head1 REQUIRED ARGUMENTS

=over

=item  -h = <dev>[<port>]

Specify device/port

=for Euclid:
    dev.type:    /[^:\s\d]+\D/
    port.type:   /\d+/

=item  -dim=<dim>

=for Euclid:
    dim.type:    /\d+,\d+/

=back

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

