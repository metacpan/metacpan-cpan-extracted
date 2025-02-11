package EBook::Ishmael::EBook::Text;
use 5.016;
our $VERSION = '0.02';
use strict;
use warnings;

use File::Basename;
use File::Spec;

use EBook::Ishmael::TextToHtml;

# Check for txt suffix, as that is the only indicator that a file is just a
# text file that I can think of.
sub heuristic {

	my $class = shift;
	my $file  = shift;

	return $file =~ /\.txt$/;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => {},
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->{Metadata}->{title} = [ basename($self->{Source}) ];

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

	return $self->{Metadata};

}

1;
