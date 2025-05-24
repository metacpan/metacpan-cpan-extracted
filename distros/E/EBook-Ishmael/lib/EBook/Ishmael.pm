package EBook::Ishmael;
use 5.016;
our $VERSION = '1.07';
use strict;
use warnings;

use Encode qw(find_encoding encode);
use File::Basename;
use File::Path qw(remove_tree);
use File::Temp qw(tempfile);
use Getopt::Long;
use List::Util qw(max);

use JSON;
use XML::LibXML;

use EBook::Ishmael::EBook;
use EBook::Ishmael::ImageID;
use EBook::Ishmael::TextBrowserDump;

use constant {
	MODE_TEXT      => 0,
	MODE_META      => 1,
	MODE_ID        => 2,
	MODE_HTML      => 3,
	MODE_RAW_TIME  => 4,
	MODE_COVER     => 5,
	MODE_IMAGE     => 6,
};

my $PRGNAM = 'ishmael';
my $PRGVER = $VERSION;

my $HELP = <<"HERE";
$PRGNAM - $PRGVER

Usage:
  $0 [options] file [output]

Options:
  -d|--dumper=<dumper>      Specify dumper to use for formatting text
  -e|--encoding=<enc>       Print text output in specified encoding
  -I|--file-encoding=<enc>  Specify ebook character encoding
  -f|--format=<format>      Specify ebook format
  -w|--width=<width>        Specify output line width
  -N|--no-network           Disable fetching remove resources
  -t|--text                 Dump formatted ebook text
  -H|--html                 Dump ebook HTML
  -c|--cover                Dump ebook cover image
  -g|--image                Dump ebook images
  -i|--identify             Identify ebook format
  -m|--metadata[=<form>]    Print ebook metadata
  -r|--raw                  Dump the raw, unformatted ebook text

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

my $STDOUT = '-';

my %FORMAT_ALTS = (
	'fb2'       => 'fictionbook2',
	'azw'       => 'mobi',
	'azw3'      => 'kf8',
);

my %META_MODES = map { $_ => 1 } qw(
	ishmael json pjson xml pxml
);

# Replace characters that cannot be encoded with empty strings.
my $ENC_SUBST = sub { q[] };

sub _get_out {

	my $file = shift;

	if ($file ne $STDOUT) {
		open my $fh, '>', $file
			or die "Failed to open $file for writing: $!\n";
		return $fh;
	} else {
		return *STDOUT;
	}

}

sub init {

	my $class = shift;

	my $self = {
		Ebook   => undef,
		Mode    => MODE_TEXT,
		Dumper  => $ENV{ISHMAEL_DUMPER},
		Encode  => $ENV{ISHMAEL_ENCODING},
		FileEnc => undef,
		Format  => undef,
		Output  => undef,
		Width   => 80,
		Meta    => undef,
		Network => 1,
	};

	Getopt::Long::config('bundling');
	GetOptions(
		'dumper|d=s'        => \$self->{Dumper},
		'encoding|e=s'      => \$self->{Encode},
		'file-encoding|I=s' => \$self->{FileEnc},
		'format|f=s'        => \$self->{Format},
		'width|w=i'         => \$self->{Width},
		'no-network|N'      => sub { $self->{Network} = 0 },
		'text|t'            => sub { $self->{Mode} = MODE_TEXT },
		'html|H'            => sub { $self->{Mode} = MODE_HTML },
		'cover|c'           => sub { $self->{Mode} = MODE_COVER },
		'image|g'           => sub { $self->{Mode} = MODE_IMAGE },
		'identify|i'        => sub { $self->{Mode} = MODE_ID },
		'metadata|m:s'      => sub {
			# Some DWIMery that if the given argument is not a valid metadata
			# format, assume the user meant for it be a file argument and put
			# it back into @ARGV.
			$self->{Mode} = MODE_META;
			if (!$_[1] or exists $META_MODES{ lc $_[1] }) {
				$self->{Meta} = lc $_[1] || 'ishmael';
			} else {
				$self->{Meta} = 'ishmael';
				unshift @ARGV, $_[1];
			}
		},
		'raw|r'             => sub { $self->{Mode} = MODE_RAW_TIME },
		'help|h'    => sub { print $HELP;        exit 0; },
		'version|v' => sub { print $VERSION_MSG; exit 0; },
	) or die "Error in command line arguments\n$HELP";

	$self->{Ebook} = shift @ARGV or die $HELP;
	$self->{Output} = shift @ARGV;

	if ($self->{Mode} == MODE_COVER) {
		$self->{Output} //= (fileparse($self->{Ebook}, qr/\.[^.]*/))[0] . '.-';
	} elsif ($self->{Mode} == MODE_IMAGE) {
		$self->{Output} //= (fileparse($self->{Ebook}, qr/\.[^.]*/))[0];
	} else {
		$self->{Output} //= $STDOUT;
	}

	if (defined $self->{Format}) {

		$self->{Format} = lc $self->{Format};

		if (exists $FORMAT_ALTS{ $self->{Format} }) {
			$self->{Format} = $FORMAT_ALTS{ $self->{Format} };
		}

		unless (exists $EBOOK_FORMATS{ $self->{Format} }) {
			die "$self->{Format} is not a recognized ebook format\n";
		}

	}

	if (defined $self->{Encode} and not defined find_encoding($self->{Encode})) {
		die "'$self->{Encode}' is an invalid character encoding\n";
	}

	if (defined $self->{FileEnc} and not defined find_encoding($self->{FileEnc})) {
		die "'$self->{FileEnc}' is an invalid character encoding\n";
	}

	bless $self, $class;

	return $self;

}

sub text {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	my $tmp = do {
		my ($tf, $tp) = tempfile(UNLINK => 1);
		close $tf;
		$tp;
	};

	$ebook->html($tmp);

	my $oh = _get_out($self->{Output});

	unless (defined $self->{Encode}) {
		binmode $oh, ':utf8';
	}

	my $dump = browser_dump(
		$tmp,
		{
			browser => $self->{Dumper},
			width   => $self->{Width},
		}
	);

	if (defined $self->{Encode}) {
		print { $oh } encode($self->{Encode}, $dump, $ENC_SUBST);
	} else {
		print { $oh } $dump;
	}

	close $oh unless $self->{Output} eq $STDOUT;

	1;

}

sub meta {

	my $self = shift;

	if ($self->{Meta} eq 'ishmael') {
		$self->meta_ishmael;
	} elsif ($self->{Meta} eq 'json') {
		$self->meta_json(0);
	} elsif ($self->{Meta} eq 'pjson') {
		$self->meta_json(1);
	} elsif ($self->{Meta} eq 'xml') {
		$self->meta_xml(0);
	} elsif ($self->{Meta} eq 'pxml') {
		$self->meta_xml(1);
	} else {
		die "'$self->{Meta}' is not a valid metadata format\n";
	}

	1;

}

sub meta_ishmael {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	my %meta = %{ $ebook->metadata };

	my $oh = _get_out($self->{Output});
	binmode $oh, ':utf8';

	my $klen = max(map { length } keys %meta) + 1;
	for my $k (sort keys %meta) {
		printf { $oh } "%-*s %s\n", $klen, "$k:", join ", ", @{ $meta{ $k } };
	}

	close $oh unless $self->{Output} eq $STDOUT;

	1;

}

sub meta_json {

	my $self   = shift;
	my $pretty = shift // 0;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	my $meta = $ebook->metadata;

	my $oh = _get_out($self->{Output});

	for my $k (keys %{ $meta }) {
		# Flatten arrays that contain a single item
		if (@{ $meta->{ $k } } == 1) {
			$meta->{ $k } = $meta->{ $k }->[0];
		}
	}

	say { $oh } to_json($meta, { utf8 => 1,  pretty => $pretty, canonical => 1 });

	close $oh unless $self->{Output} eq $STDOUT;

	1;

}

sub meta_xml {

	my $self   = shift;
	my $pretty = shift // 0;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	my $meta = $ebook->metadata;

	my $oh = _get_out($self->{Output});

	my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
	my $root = XML::LibXML::Element->new('ishmael');
	$dom->setDocumentElement($root);
	$root->setAttribute('version', $PRGVER);
	my $metan = $root->appendChild(
		XML::LibXML::Element->new('metadata')
	);

	for my $k (sort keys %$meta) {

		my $n = $metan->appendChild(
			XML::LibXML::Element->new(lc $k)
		);

		for my $i (@{ $meta->{ $k } }) {

			my $in = $n->appendChild(
				XML::LibXML::Element->new('item')
			);

			$in->appendChild(
				XML::LibXML::Text->new($i)
			);

		}

	}

	$dom->toFH($oh, $pretty);

	close $oh unless $self->{Output} eq $STDOUT;

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
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	my $oh = _get_out($self->{Output});

	unless (defined $self->{Encode}) {
		binmode $oh, ':utf8';
	}

	my $html = $ebook->html;

	if (defined $self->{Encode}) {
		say { $oh } encode($self->{Encode}, $html, $ENC_SUBST);
	} else {
		say { $oh } $html;
	}

	close $oh unless $self->{Output} eq $STDOUT;

	1;

}

sub raw {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	my $oh = _get_out($self->{Output});

	unless (defined $self->{Encode}) {
		binmode $oh, ':utf8';
	}

	my $raw = $ebook->raw;

	if (defined $self->{Encode}) {
		say { $oh } encode($self->{Encode}, $raw, $ENC_SUBST);
	} else {
		say { $oh } $raw;
	}

	close $oh unless $self->{Output} eq $STDOUT;

	1;

}

sub cover {

	my $self = shift;

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	unless ($ebook->has_cover) {
		say "$self->{Ebook} does not have a cover";
		return;
	}

	my $cover = $ebook->cover;
	my $fmt = image_id(\$cover);

	unless (defined $fmt) {
		die "Could not dump $self->{Ebook} cover; could not identify cover image format\n";
	}

	if ($self->{Output} =~ /\.\*$/) {
		warn "Using '.*' for suffix substitution is deprecated; please use '.-' instead\n";
	}

	$self->{Output} =~ s/\.[\-@]$/.$fmt/;

	my $oh = _get_out($self->{Output});
	binmode $oh;

	print { $oh } $ebook->cover;

	close $oh unless $self->{Output} eq $STDOUT;

	1;

}

sub image {

	my $self = shift;

	if ($self->{Output} eq $STDOUT) {
		die "Cannot dump images to stdout\n";
	}

	my $ebook = EBook::Ishmael::EBook->new(
		$self->{Ebook},
		$self->{Format},
		$self->{FileEnc},
		$self->{Network},
	);

	my $num = $ebook->image_num;

	unless ($num) {
		say "$self->{Ebook} has no images";
		return;
	}

	my $base = basename($self->{Output});
	my $pad = length $num;

	my $mkdir = 0;

	unless (-d $self->{Output}) {
		mkdir $self->{Output}
			or die "Failed to mkdir $self->{Output}: $!\n";
		$mkdir = 1;
	}

	my @created;

	eval {
		for my $i (0 .. $num - 1) {

			my $ii = $i + 1;

			my $img = $ebook->image($i);
			my $id = image_id($img);

			unless (defined $id) {
				warn "Could not identify image #$ii\'s format, skipping\n";
				next;
			}

			my $b = sprintf "%s-%0*d.%s", $base, $pad, $ii, $id;

			my $p = File::Spec->catfile($self->{Output}, $b);

			open my $fh, '>', $p
				or die "Failed to open $p for writing: $!\n";
			binmode $fh;
			print { $fh } $$img;
			close $fh;

			push @created, $p;

		}
		1;
	} or do {

		for my $c (@created) {
			unlink $c;
		}

		rmdir $self->{Output} if $mkdir;

		die $@;
	};

	unless (@created) {
		rmdir $self->{Output} if $mkdir;
		die "Could not dump any images in $self->{Output}\n";
	}

	say $self->{Output};
	for my $c (map { basename($_) } @created) {
		say "  $c";
	}

	1;

}

sub run {

	my $self = shift;

	if ($self->{Mode} == MODE_TEXT) {
		$self->text;
	} elsif ($self->{Mode} == MODE_META) {
		$self->meta;
	} elsif ($self->{Mode} == MODE_ID) {
		$self->id;
	} elsif ($self->{Mode} == MODE_HTML) {
		$self->html;
	} elsif ($self->{Mode} == MODE_RAW_TIME) {
		$self->raw;
	} elsif ($self->{Mode} == MODE_COVER) {
		$self->cover;
	} elsif ($self->{Mode} == MODE_IMAGE) {
		$self->image;
	}

	1;

}

1;


=head1 NAME

EBook::Ishmael - EBook dumper

=head1 SYNOPSIS

  use EBook::Ishmael;

  my $ishmael = EBook::Ishmael->init();
  $ishmael->run();

=head1 DESCRIPTION

B<EBook::Ishmael> is the workhorse module for L<ishmael>. If you're looking for
user documentation, you should consult its manual instead of this (this is
developer documentation).

=head1 METHODS

=head2 $i = EBook::Ishmael->init()

Reads C<@ARGV> and returns a blessed C<EBook::Ishmael> object. Consult the
manual for L<ishmael> for a list of options that are available.

=head2 $i->text()

Dumps ebook file to text, default run mode.

=head2 $i->meta()

Dumps ebook metadata, C<--metadata> mode.

=head2 $i->meta_ishmael()

Dumps ebook metadata, C<--metadata=ishmael> mode.

=head2 $i->meta_json($pretty)

Dumps ebook metadata in JSON form, C<--metadata=p?json> mode.

=head2 $i->meta_xml($pretty)

Dumps ebook metadata in XML form, C<--metadata=p?xml> mode.

=head2 $i->id()

Identify the format of the given ebook, C<--identify> mode.

=head2 $i->html()

Dump the HTML-ified contents of a given ebook, C<--html> mode.

=head2 $i->raw()

Dump the raw, unformatted text contents of a given ebook, C<--raw> mode.

=head2 $i->cover()

Dump the binary data of the cover image of a given ebook, if one is present,
C<--cover> mode.

=head2 $i->run()

Runs L<ishmael> based on the parameters processed during C<init()>.

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
