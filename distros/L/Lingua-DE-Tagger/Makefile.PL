use warnings;
use strict;
use ExtUtils::MakeMaker;
use FileHandle;

my %_LEXICON;
my %_HMM;

# written by Tobias Schulz

if( install() ){

WriteMakefile(
    NAME                => 'Lingua::DE::Tagger',
    AUTHOR              => 'Tobias Schulz <t-schulz@tobias-schulz.info>',
    VERSION_FROM        => 'lib/Lingua/DE/Tagger.pm',
#    ABSTRACT_FROM       => 'lib/Lingua/DE/Tagger.pm',
    PL_FILES            => {},
    'PREREQ_PM'         => { 'Lingua::Stem' => '0.81', 
                                'HTML::Parser' => '3.45',
                                'Memoize' => '1.01',
                                'Memoize::ExpireLRU' => '0.55',
                                'File::Spec' => '0.84',
                                'Storable' => '2.10'
                        }, # e.g., Module::Name => 1.1
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-DE-Tagger-*' },
);


} else {
        die "Encountered problems installing the lexicon!\nMakefile not written!\n";
}
        

sub install {
        use Storable;
        use File::Spec;
        my $lex_dir = 'Tagger';
        my $word_path = File::Spec->catfile( $lex_dir, 'pos_words.hash' );
        my $tag_path = File::Spec->catfile( $lex_dir, 'pos_tags.hash' );
        
        unless( -f $word_path and -f $tag_path ){
                print "Creating part-of-speech lexicon\n";
                _load_tags( File::Spec->catfile( $lex_dir, 'tags.yml' ) );
                _load_words( File::Spec->catfile( $lex_dir, 'words.yml' ) );
                _load_words( File::Spec->catfile( $lex_dir, 'unknown.yml' ) );
                store \%_LEXICON, $word_path;
                store \%_HMM, $tag_path;
        }

        if( -f $word_path and -f $tag_path ){
                return 1;
        } else {
                return 0;
        }
}

sub _load_words {
        my ( $file ) = @_;
        my $fh = new FileHandle $file;
        while ( <$fh> ){
                my ( $key, $data ) = m/^"?([^{"]+)"?: { (.*) }/;
                next unless $key and $data;
                my %tags = split /[:,]\s+/, $data;
                foreach( keys %tags ){
                        $_LEXICON{$key}{$_} = \$tags{$_};
                }
        }
        $fh->close;
}

sub _load_tags {
        my ( $file ) = @_;
        my $fh = new FileHandle $file;
        while ( <$fh> ){
                my ( $key, $data ) = m/^"?([^{"]+)"?: { (.*) }/;
                next unless $key and $data;
                my %tags = split /[:,]\s+/, $data;
                foreach( keys %tags ){
                        $_HMM{$key}{$_} = $tags{$_};
                }
        }
        $fh->close;
}

        
