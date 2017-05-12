BEGIN {
    @ARGV = (
        "-norequired",
        "-optionalless",
        "--unabbr",
        "-necessary",
        "--opt",
    );
}

use Getopt::Euclid;
use Test::More 'no_plan';

sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

got_arg -norequired   => 1;
got_arg -required     => 0;

got_arg -necessary    => 1;
got_arg -unnecessary  => 0;

got_arg -optional     => 0;
got_arg -optionalless => 1;

got_arg '--abbr'          => 0;
got_arg '--abbrev'        => 0;
got_arg '--abbreviated'   => 0;
got_arg '--unabbr'        => 1;
got_arg '--unabbrev'      => 1;
got_arg '--unabbreviated' => 1;

got_arg '--opt'           => 1;
got_arg '--optout'        => undef;


__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 USAGE

    orchestrate  -in source.txt  --out dest.orc  -verbose  -len=24

=head1 REQUIRED ARGUMENTS

=over

=item  -[no]required

Specify verbosity

=for Euclid:
    false: -norequired

=item  -[un]necessary

Specify verbosity

=for Euclid:
    false: -unnecessary

=item  --[un]abbr[ev[iated]]

Specify verbosity

=for Euclid:
    false: --unabbr
    false: --unabbrev
    false: --unabbreviated

=back

=head1 OPTIONS

=over

=item  -optional[less]

Test optionality

=for Euclid:
    false: -optionalless

=item  --opt

Test optionality

=for Euclid:
    false: --optout

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

