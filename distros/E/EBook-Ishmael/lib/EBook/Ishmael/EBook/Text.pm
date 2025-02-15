package EBook::Ishmael::EBook::Text;
use 5.016;
our $VERSION = '0.04';
use strict;
use warnings;

use File::Basename;
use File::Spec;

use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::TextToHtml;

# Use -T to check if file is a text file. EBook.pm's ebook_id() makes sure
# to use the Text heuristic last, so that it doesn't incorrectly identify other
# plain text ebook formats as just text.
sub heuristic {

	my $class = shift;
	my $file  = shift;

	return -T $file;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => EBook::Ishmael::EBook::Metadata->new,
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->{Metadata}->title([ basename($self->{Source}) ]);
	$self->{Metadata}->modified([ scalar gmtime((stat $self->{Source})[9]) ]);
	$self->{Metadata}->format([ 'Text' ]);

	return $self;

}

sub html {

	my $self = shift;
	my $out  = shift;

	my $html = '';

	open my $wh, '>', $out // \$html
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';

	open my $rh, '<', $self->{Source}
		or die "Failed to open $self->{Source} for reading: $!\n";

	local $/ = undef;
	print { $wh } text2html(readline $rh);

	close $rh;
	close $wh;

	return $out // $html;

}

sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

1;
