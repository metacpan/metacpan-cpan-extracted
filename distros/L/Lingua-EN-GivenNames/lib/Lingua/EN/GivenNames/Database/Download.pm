package Lingua::EN::GivenNames::Database::Download;

use feature 'say';
use parent 'Lingua::EN::GivenNames::Database';
use strict;
use warnings;
use warnings qw(FATAL utf8);

use File::Spec;

use HTML::HTML5::Entities; # For decode_entities().

use HTTP::Tiny;

use Moo;

use Types::Standard qw/Str/;

has url =>
(
	default  => sub{return 'http://www.20000-names.com/'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.04';

# -----------------------------------------------

sub get_1_page
{
	my($self, $url, $data_file) = @_;

	my($response) = HTTP::Tiny -> new -> get($url);

	if (! $$response{success})
	{
		$self -> log(error => "Failed to get $url");
		$self -> log(error => "HTTP status: $$response{status} => $$response{reason}");

		if ($$response{status} == 599)
		{
			$self -> log(error => "Exception message: $$response{content}");
		}

		# Return 0 for success and 1 for failure.

		return 1;
	}

	decode_entities $$response{content};

	open(OUT, '>', $data_file) || die "Can't open file: $data_file: $!\n";
	print OUT $$response{content};
	close OUT;

	$self -> log(info => "Downloaded '$url' to '$data_file'");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_1_page.

# -----------------------------------------------

sub get_name_pages
{
	my($self)  = @_;
	my(%limit) = %{$self -> page_counts};

	my($delay, $data_file);
	my($file_name);
	my($page);
	my($result);
	my($url);

	for my $sex (qw/male/)
	{
		$file_name = "${sex}_english_names";

		for my $page_number (16 .. $limit{$sex})
		{
			# Generate input and output url/file names.

			$data_file = File::Spec -> catfile($self -> data_dir, $file_name);
			$url       = $self -> url . $file_name;

			if ($page_number > 1)
			{
				$page      = sprintf '_%02d', $page_number;
				$data_file .= $page;
				$url       .= $page;
			}

			$data_file .= '.htm';
			$url       .= '.htm';

			# Sleep randomly to avoid causing displeasure.

			$delay = 30 + int rand 1000;

			$self -> log(info => "Sleeping for $delay seconds before processing '$url' => '$data_file'");

			sleep $delay;

			$result = $self -> get_1_page($url, $data_file);
		}
	}

	return $result;

} # End of get_name_pages.

# -----------------------------------------------

1;

=pod

=head1 NAME

Lingua::EN::GivenNames::Database::Download - An SQLite database of derivations of English given names

=head1 Synopsis

See L<Lingua::EN::GivenNames/Synopsis> for a long synopsis.

See also L<Lingua::EN::GivenNames/How do the scripts and modules interact to produce the data?>.

=head1 Description

Documents the methods used to download web pages which will be imported into
I<lingua.en.givennames.sqlite> (which ships with this distro).

Specifically, downloads these pages (for sex in ['female', 'male']):

Input: L<http://www.20000-names.com/${sex}_english_names*.htm>.

Output: data/${sex}_english_names*.htm.

The * means there are a set of pages for each sex.

See scripts/get.name.pages.pl .

Note: These pages I<have been downloaded>, and are shipped with the distro.

=head1 Constructor and initialization

new(...) returns an object of type C<Lingua::EN::GivenNames::Database::Download>.

This is the class's contructor.

Usage: C<< Lingua::EN::GivenNames::Database::Download -> new() >>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Methods

This module is a sub-class of L<Lingua::EN::GivenNames::Database> and consequently inherits its methods.

=head2 get_1_page($url, $data_file)

Called by get_name_pages().

Download $url and save it in $data_file. $data_file takes the form 'data/${sex}_english_names*.htm'.

Returns 0 to indicate success.

=head2 get_name_pages()

Downloads 20 pages of female given names and 17 pages of male given names.

See scripts/get.name.pages.pl.

Returns the result of the last call to L</get_1_page($url, $data_file)> (which will be 0) to indicate success.

=head2 new()

See L</Constructor and initialization>.

=head2 url()

Returns the string 'http://www.20000-names.com/'.

=head1 FAQ

For the database schema, etc, see L<Lingua::EN::GivenNames/FAQ>.

=head1 References

See L<Lingua::EN::GivenNames/References>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua::EN::GivenNames>.

=head1 Author

C<Lingua::EN::GivenNames> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
