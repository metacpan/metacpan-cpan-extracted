package Genealogy::Gedcom::Reader;

use strict;
use warnings;

use Genealogy::Gedcom::Reader::Lexer;

use Log::Handler;

use Moo;

use Set::Array;

use Types::Standard qw/Any Int Str/;

has input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has items =>
(
	default  => sub{return Set::Array -> new},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has report_items =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has strict =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '0.88';

# --------------------------------------------------

sub BUILD
{
	my($self) = @_;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
				utf8           => 1,
			}
		);
	}

} # End of BUILD.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> $level($s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub run
{
	my($self)  = @_;
	my($lexer) = Genealogy::Gedcom::Reader::Lexer -> new
		(
		 input_file   => $self -> input_file,
		 logger       => $self -> logger,
		 maxlevel     => $self -> maxlevel,
		 minlevel     => $self -> minlevel,
		 report_items => $self -> report_items,
		 strict       => $self -> strict,
		);
	my($result) = $lexer -> run;

	$self -> items($lexer -> items);

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<Genealogy::Gedcom::Reader> - An OS-independent reader for GEDCOM data

=head1 Synopsis

See L<Genealogy::Gedcom::Reader::Lexer>.

=head1 Description

L<Genealogy::Gedcom::Reader> provides a reader for GEDCOM data.

See L<The GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/en/Main_Page>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Genealogy::Gedcom> as you would for any C<Perl> module:

Run:

	cpanm Genealogy::Gedcom

or run:

	sudo cpan Genealogy::Gedcom

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

See L<Genealogy::Gedcom::Reader::Lexer>.

=head1 FAQ

See L<Genealogy::Gedcom/FAQ>.

=head1 Repository

L<https://github.com/ronsavage/Genealogy-Gedcom>

=head1 See Also

L<Genealogy::Gedcom::Date>.

<Gedcom::Date>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who worked on L<Gedcom>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy::Gedcom>.

=head1 Author

L<Genealogy::Gedcom> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
