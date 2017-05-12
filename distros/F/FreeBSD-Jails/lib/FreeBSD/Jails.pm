package FreeBSD::Jails;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

use version; $VERSION = qv('v0.2');               

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

bootstrap FreeBSD::Jails;
1;

=head1 NAME

FreeBSD::Jails - Get the list of running Jails in a FreeBSD system

=head1 SYNOPSIS

 my $jails = FreeBSD::Jails::get_jails ; 

=head1 DESCRIPTION

This is a simple module to query a FreeBSD system for the list of running jails. 
Unfortunately there isn't a good way to call the jail_get system call with pure Perl,
so a little piece of C code is required to make this possible. 

=head1 METHODS

=over 2

=item get_jails

Returns a reference to a hash whose keys are jail ids (i.e. integers) and values are 
the names of the jails. 

=back

=head1 AUTHOR

Athanasios Douitsis C<< <aduitsis@cpan.org> >>

=head1 SUPPORT

Please open a ticket at L<https://github.com/aduitsis/FreeBSD-Jails>. 

I am new to XS, so unforeseen bugs or a small memory leak may be
present in the module. Caveat emptor. 

=head1 COPYRIGHT & LICENSE

Copyright 2015 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

