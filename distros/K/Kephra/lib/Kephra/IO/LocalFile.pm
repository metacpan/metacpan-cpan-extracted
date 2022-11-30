use v5.12;
use warnings;
use Encode;
use Encode::Guess;
use File::Spec;

package Kephra::IO::LocalFile;


sub normalize_path {
	my $file = shift;
	return unless defined $file and $file;

	$file = File::Spec->canonpath($file);
	local $/ = "\r\n";
	chomp($file);
	return $file;
}

sub read {
	my $file = normalize_path( shift );
	my $encoding;
	return warning("can't load nonexising file") unless $file and -e $file;
	return warning("can't read $file") unless -r $file;
	open my $FH, '<', $file;
	binmode($FH);
	my $content = do { local $/; <$FH> };
	if ($content) {
		my @guesses = qw/utf-8 iso8859-1 latin1/;
		my $guess = Encode::Guess::guess_encoding( $content, @guesses );
		if ( ref($guess) and ref($guess) =~ m/^Encode::/ ) { $encoding = $guess->name }
		elsif (                   $guess =~ m/utf8/      ) { $encoding = 'utf-8' }
		elsif (                   $guess =~ m/or/        ) {
			my @suggest_encodings = split /\sor\s/, "$guess";
			$encoding = $suggest_encodings[0];
		} else                                             { $encoding = 'utf-8' }
		$content = Encode::decode( $encoding,  $content ); 
	}
	return $content, $encoding;
}

sub write {
	my ($file, $encoding, $content) = @_;
	$file = normalize_path( $file );
	$encoding = 'utf-8' unless defined $encoding;
	return say("need a file path") unless $file;
	return say("can't overwrite $file") if -e $file and not -w $file;
	open my $FH, "> :raw :encoding($encoding)", $file;
	print $FH $content;
}


1;