package IP::Unique;

use 5.005;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('IP::Unique', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

IP::Unique - Store and count unique IPv4 addresses, optimized for large numbers of IPs 

=head1 SYNOPSIS

	use IP::Unique;
	my $ipun = IP::Unique->new();

	$ipun->add_ip("127.0.0.1");
	$ipun->add_ip("127.0.0.1");
	$ipun->add_ip("12.34.56.78");

	$ipun->unique(); #In this example, 2
	$ipun->total(); #In this example, 3

	$ipun->compact();

=head1 DESCRIPTION

IP::Unique solves the problem of how to account for uniqueness, given a large number of IP addresses.  Since this module is written in C to take advantage of fast integer handling, it performs (in my experience) several times as fast and with (on average), about 1/5th the amount of memory of similar perl solutions.

A traditional way to account for the uniqueness of a list of objects in perl is to use a hash as such:

	for(@iplist)
	{
		$ips->{$_} = 1;
	}
	$unique = int(keys %$ips);

The situation that quickly arises is that perl hashing algorithms perform poorly in regards to memory when they reach millions of objects. Databases are also cumbersome to work with, as 30 million rows are hard to keep distinct (and is a needless waste of time to look up and insert). This is where IP::Unique (hopefully) shines.  

=head2 METHODS

IP::Unique is an OO module, so nothing is exported.  The module contains the following methods

=over 4

=item * C<new()>

	new() works just as it does in every other module. It takes no parameters, and returns a reference to a new instance of the object.

=back

=over 4

=item * C<add_ip("127.0.0.1")>

	add_ip() takes a string parameter, formatted in AAA.BBB.CCC.DDD format. It returns 1 on the success of adding the IP address to the table, 0 if the address is poorly formatted or invalid.  For the purposes of validity, addresses such as "0.0.0.0" and "255.255.255.255" are considered valid, but "256.0.0.0" is not. Adding IPs increments the counter as returned by c<total>().

=back

=over 4

=item * C<compact()>

	This is a version 0.01 function that is no longer needed. The call simply returns.

=back

=over 4

=item * C<unique()>

	unique() returns the number of uniques stored in the counter.  This has to run C<compact>() to remove duplicates, so the same caveat applies here: this may take some time. 

=back

=over 4

=item * C<total()>

	total() returns the number of IPs (total) stored in the counter, so far. There is no way to remove an IP.

=back

=head1 CHANGES

B<Version 0.03> - May 11th, 2004

=over 4 

=item * Fixed a memory leak where the main base wasn't destroyed when the object was undef'ed

=back

B<Version 0.02> - May 11th, 2004

=over 4 

=item * Rewrite to bit-flag mechanism, away from STL lists.

=item * Compact is now deprecated

=back

B<Version 0.01> - Feb 19th, 2004

=over 4

=item * Initial release of the module, so everything is new

=back

=head1 BUGS

There are several items that can be considered bugs in the module

=over 4

=item * It is hardcoded to use g++. If you know a better way to tell Makefile.PL to use "any c++ compiler", please let me know.

=item * I've had difficulty getting this module to work under cygwin

=item * This module should work under versions of perl other than 5.8.3, but it hasn't been tested with such. If you can get it to run under a lower version of perl, please contact me.

=back

=head1 AUTHOR

Jay Bonci, E<lt>jaybonci@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jay Bonci, Open Source Development Network

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
