package Media::Convert::Asset::Concat;

use Moose;

extends 'Media::Convert::Asset';

=head1 NAME

Media::Convert::Asset::Concat - a Media::Convert::Asset made up of multiple assets

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Asset::Concat;
  use Media::Convert::Pipe;

  my $file1 = Media::Convert::Asset->new(url => $input_file_1);
  my $file2 = Media::Convert::Asset->new(url => $input_file_2);
  my $input = Media::Convert::Asset::Concat->new(url => "/tmp/concat.txt", components => [$file1, $file2]);
  my $output = Media::Convert::Asset->new(url => $output_file);

  Media::Convert::Pipe->new(inputs => [$input], output => $output, vcopy => 1, acopy => 1)->run();

=head1 DESCRIPTION

The C<ffmpeg> command has a "concat" file format, selected with
C<-f concat>, which is essentially a text file containing a header,
followed by a number of URLs to other files.

When C<ffmpeg> is asked to read from such a file, it will start reading
from the first file, and then move on to the next file when the data
from the first file is complete.

In order for this to work well, note that I<all files must be the same
format>, to beyond the level that C<Media::Convert::Asset> can detect.
It is probably not safe to use C<Media::Convert::Asset::Concat> except
on files that were created from the same recording.

Since the files I<should> be the same, C<Media::Convert::Asset::Concat>
assumes that they are, and will run C<ffprobe> on only the first of its
components when requested.

=head1 ATTRIBUTES

C<Media::Convert::Asset::Concat> supports all attributes supported by
L<Media::Convert::Asset> plus the following:

=head2 components

Should be an array of L<Media::Convert::Asset> objects making up the
contents of this asset.

To add more components, the C<add_component> handle exists.

=cut

has 'components' => (
	traits => ['Array'],
	isa => 'ArrayRef[Media::Convert::Asset]',
	required => 1,
	is => 'rw',
	handles => {
		add_component => 'push',
	},
);

has '+duration' => (
	builder => '_build_duration',
);

sub readopts {
	my $self = shift;

	if(($self->has_pass && $self->pass < 2) || !$self->has_pass) {
		die "refusing to overwrite file " . $self->url . "!\n" if (-f $self->url);

		my $content = "ffconcat version 1.0\n\n";
		foreach my $component(@{$self->components}) {
			my $input = $component->url;
			$content .= "file '$input'\n";
		}
		print "Writing " . $self->url . " with content:\n$content\n";
		open CONCAT, ">" . $self->url;
		print CONCAT $content;
		close CONCAT;
	}

	return ('-f', 'concat', '-safe', '0', $self->Media::Convert::Asset::readopts());
}

sub _build_duration {
	my $self = shift;
	my $rv = 0;
	foreach my $component(@{$self->components}) {
		$rv += $component->duration;
	}
	return $rv;
}

sub _probe {
	my $self = shift;
	return $self->components->[0]->_get_probedata;
}

no Moose;

1;
