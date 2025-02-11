package EBook::Ishmael;
use 5.016;
our $VERSION = '0.02';
use strict;
use warnings;

use File::Temp qw(tempfile);
use Getopt::Long;
use List::Util qw(max);

use JSON;

use EBook::Ishmael::EBook;
use EBook::Ishmael::TextBrowserDump;

use constant {
	MODE_TEXT      => 0,
	MODE_META      => 1,
	MODE_META_JSON => 2,
	MODE_ID        => 3,
	MODE_HTML      => 4,
};

my $PRGNAM = 'ishmael';
my $PRGVER = $VERSION;

my $HELP = <<"HERE";
$PRGNAM - $PRGVER

Usage:
  $0 [options] file

Options:
  -d|--dumper=<dumper>   Specify dumper to use for formatting text
  -f|--format=<format>   Specify ebook format
  -o|--output=<file>     Write output to file
  -w|--width=<width>     Specify output line width
  -H|--html              Dump ebook HTML
  -i|--identify          Identify ebook format
  -j|--meta-json         Print ebook metadata in JSON
  -m|--metadata          Print ebook metadata

  -h|--help      Print help message
  -v|--version   Print version/copyright info
HERE

my $VERSION_MSG = <<"HERE";
$PRGNAM - $PRGVER

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
HERE

my %FORMAT_ALTS = (
	'fb2'   => 'fictionbook2',
	'xhtml' => 'html',
);

sub init {

	my $class = shift;

	my $self = {
		Ebook  => undef,
		Mode   => MODE_TEXT,
		Dumper => $ENV{ISHMAEL_DUMPER},
		Format => undef,
		Output => undef,
		Width  => 80,
	};

	Getopt::Long::config('bundling');
	GetOptions(
		'dumper|d=s'  => \$self->{Dumper},
		'format|f=s'  => \$self->{Format},
		'output|o=s'  => \$self->{Output},
		'width|w=i'   => \$self->{Width},
		'html|H'      => sub { $self->{Mode} = MODE_HTML },
		'identify|i'  => sub { $self->{Mode} = MODE_ID },
		'meta-json|j' => sub { $self->{Mode} = MODE_META_JSON },
		'metadata|m'  => sub { $self->{Mode} = MODE_META },
		'help|h'    => sub { print $HELP;        exit 0; },
		'version|v' => sub { print $VERSION_MSG; exit 0; },
	) or die "Error in command line arguments\n$HELP";

	$self->{Ebook} = shift @ARGV or die $HELP;

	if (defined $self->{Format}) {

		$self->{Format} = lc $self->{Format};

		if (exists $FORMAT_ALTS{ $self->{Format} }) {
			$self->{Format} = $FORMAT_ALTS{ $self->{Format} };
		}

		unless (exists $EBOOK_FORMATS{ $self->{Format} }) {
			die "$self->{Format} is not a recognized ebook format\n";
		}

	}

	bless $self, $class;

	return $self;

}

sub text {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format}
	);

	my ($tfh, $tmp) = tempfile(UNLINK => 1);
	close $tfh;

	$ebook->html($tmp);

	my $oh;
	if (defined $self->{Output}) {
		open $oh, '>', $self->{Output}
			or die "Failed to open $self->{Output} for writing: $!\n";
	} else {
		$oh = *STDOUT;
	}

	print { $oh } browser_dump $tmp, { browser => $self->{Dumper}, width => $self->{Width} };

	close $oh if defined $self->{Output};

	1;

}

sub meta {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format}
	);

	my %meta = %{ $ebook->metadata };

	return unless %meta;

	# Make room for colon and extra space
	my $klen = max map { length($_) + 2 } keys %meta;

	for my $k (sort keys %meta) {
		say pack("A$klen", "$k:"), join(", ", @{ $meta{ $k } });
	}

	1;

}

sub meta_json {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format}
	);

	my $meta = $ebook->metadata;

	for my $k (keys %{ $meta }) {
		# Flatten arrays that contain a single item
		if (@{ $meta->{ $k } } == 1) {
			$meta->{ $k } = $meta->{ $k }->[0];
		}
	}

	say to_json($meta, { utf8 => 1, pretty => 1, canonical => 1 });

	1;

}

sub id {

	my $self = shift;

	my $id = ebook_id($self->{Ebook});

	say defined $id ? $id : "Could not identify format for $self->{Ebook}";

	1;

}

sub html {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format}
	);

	my $oh;
	if (defined $self->{Output}) {
		open $oh, '>', $self->{Output}
			or die "Failed to open $self->{Output} for writing: $!\n";
	} else {
		$oh = *STDOUT;
	}

	say { $oh } $ebook->html;

	close $oh if defined $self->{Output};

	1;

}

sub run {

	my $self = shift;

	if ($self->{Mode} == MODE_TEXT) {
		$self->text;
	} elsif ($self->{Mode} == MODE_META) {
		$self->meta;
	} elsif ($self->{Mode} == MODE_META_JSON) {
		$self->meta_json;
	} elsif ($self->{Mode} == MODE_ID) {
		$self->id;
	} elsif ($self->{Mode} == MODE_HTML) {
		$self->html;
	}

	1;

}

1;


=head1 NAME

EBook::Ishmael - Convert ebook documents to plain text

=head1 SYNOPSIS

  use EBook::Ishmael;

  my $ishmael = EBook::Ishmael->init();
  $ishmael->run();

=head1 DESCRIPTION

B<EBook::Ishmael> is the workhorse module for L<ishmael>. If you're looking for
user documentation, you should consult its manual instead of this (this is
developer documentation).

=head1 METHODS

=head2 $i = EBook::Ishmael->new()

Reads C<@ARGV> and returns a blessed C<EBook::Ishmael> object. Consult the
manual for L<ishmael> for a list of options that are available.

=head2 $i->text()

Dumps ebook file to text, default run mode.

=head2 $i->meta()

Dumps ebook metadata, C<--metadata> mode.

=head2 $i->meta_json()

Dumps ebook metadata in JSON form, C<--meta-json> mode.

=head2 $i->id()

Identify the format of the given ebook, C<--identify> mode.

=head2 $i->html()

Dump the HTML-ified contents of a given ebook, C<--html> mode.

=head2 $i->run()

Runs L<ishmael> based on the parameters processed during C<new()>.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<ishmael>

=cut
