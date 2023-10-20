use v5.12;
use warnings;
use Encode;
use Encode::Guess;
use File::Spec;

package Kephra::IO::LocalFile;


sub dir_from_path {
    my $path = shift;
    return unless defined $path;
    my ($volume, $directories, $file) = File::Spec->splitpath( $path );
    File::Spec->catdir( $volume, $directories );
}

sub normalize_path {
    my $path = shift;
    return unless defined $path and $path;

    $path = File::Spec->canonpath( $path );
    local $/ = "\r\n";
    chomp( $path );
    return $path;
}

sub read {
    my $path = normalize_path( shift );
    my $encoding;
    return warning("can't load nonexising file") unless defined $path and -e $path;
    return warning("can't read $path") unless -r $path;
    open my $FH, '<', $path;
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
    my ($path, $encoding, $content) = @_;
    $path = normalize_path( $path );
    $encoding = 'utf-8' unless defined $encoding;
    return say "need a file path to write into" unless $path;
    return say "can't overwrite $path"  if -e $path and not -w $path;
    open my $FH, "> :raw :encoding($encoding)", $path;
    print $FH $content;
}


1;
