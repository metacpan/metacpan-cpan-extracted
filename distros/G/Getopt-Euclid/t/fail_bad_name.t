use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}



if (eval { require Getopt::Euclid and Getopt::Euclid->import(); 1 }) {
    ok 0 => 'Unexpectedly succeeded';
}
else {
    like $@, qr/Getopt::Euclid: Invalid argument specification: --delta <delta | -d <delta>/
         => 'Failed as expected'; 
}

__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 USAGE

    orchestrate  -in source.txt  --out dest.orc  -verbose  -len=24

=head1 OPTIONS

=over

=item --delta <delta | -d <delta>

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
