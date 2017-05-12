package Kollos;

use Moo;

our $VERSION = '0.01';

# ------------------------------------------------

sub run
{
	my($self) = @_;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Kollos> - A placeholder for the Kollos::* hierarchy

=head1 Synopsis

	perl -e -MKollos 'use Kollos; my($k) = Kollos -> new; $k -> run'

=head1 Description

C<Kollos> pplaceholder for the Kollos::* hierarchy.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Kollos> as you would for any C<Perl> module:

Run:

	cpanm Kollos

or run:

	sudo cpan Kollos

or unpack the distro, and then:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($k) = Kollos -> new.

It returns a new object of type C<Kollos>.

C<new()> does not accept any parameters.

=head1 Methods

=head2 run()

Does nothing but return 0.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Kollos>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Kollos>.

=head1 Author

L<Kollos> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2017.

My homepage: L<http://savage.net.au/>

=head1 Copyright

Australian copyright (c) 2017, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
