package BenchmarkingIndexer;
use strict;
use warnings;

use Carp;
use Config;
use File::Spec::Functions qw( catfile catdir );
use POSIX qw( uname );

sub new {
    my $either = shift;
    my $class = ref($either) || $either;
    return bless {
        docs      => undef,
        increment => undef,
        store     => undef,
        engine    => undef,
        version   => undef,
        index_dir => undef,
        corpus_dir        => 'extracted_corpus',
        article_filepaths => undef,
        @_,
    }, $class;
}

sub init_indexer { confess "abstract method" }
sub build_index  { confess "abstract method" }

sub delayed_init {
    my $self = shift;
    my $article_filepaths = $self->{article_filepaths} = $self->build_file_list;
    $self->{docs} = @$article_filepaths unless defined $self->{docs};
    $self->{increment} = $self->{docs} + 1 unless defined $self->{increment};
}

# Return a lexically sorted list of all article files from all subdirs.
sub build_file_list {
    my $self = shift;
    my $corpus_dir = $self->{corpus_dir};
    my @article_filepaths;
    opendir CORPUS_DIR, $corpus_dir
        or confess "Can't opendir '$corpus_dir': $!";
    my @article_dir_names = grep {/articles/} readdir CORPUS_DIR;
    for my $article_dir_name (@article_dir_names) {
        my $article_dir = catdir( $corpus_dir, $article_dir_name );
        opendir ARTICLE_DIR, $article_dir
            or die "Can't opendir '$article_dir': $!";
        push @article_filepaths, map { catfile( $article_dir, $_ ) }
            grep {m/^article\d+\.txt$/} readdir ARTICLE_DIR;
    }
    @article_filepaths = sort @article_filepaths;
    $self->{article_filepaths} = \@article_filepaths;
}

# Print out stats for one run.
sub print_interim_report {
    my ( $self, %args ) = @_;
    printf( "%-3d  Secs: %.2f  Docs: %-4d\n", @args{qw( rep secs count )} );
}

sub start_report {
    # start the output
    print '-' x 60 . "\n";
}

# Print out aggregate stats
sub print_final_report {
    my ( $self, $times ) = @_;

    # produce mean and truncated mean
    my @sorted_times = sort @$times;
    my $num_to_chop = int( @sorted_times >> 2 );
    my $mean = 0; 
    my $trunc_mean = 0;
    my $num_kept = 0;
    for ( my $i = 0; $i < @sorted_times; $i++ ) {
        $mean += $sorted_times[$i];
        # discard fastest 25% and slowest 25% of runs
        next if $i < $num_to_chop;
        next if $i > ( $#sorted_times - $num_to_chop );
        $trunc_mean += $sorted_times[$i];
        $num_kept++;
    }

    $mean /= @sorted_times;
    $trunc_mean /= $num_kept;
    my $num_discarded = @sorted_times - $num_kept;
    $mean = sprintf("%.2f", $mean);
    $trunc_mean = sprintf("%.2f", $trunc_mean);

    # get some info about the system
    my $thread_support = $Config{usethreads} ? "yes" : "no";
    my @uname_info = (uname)[0, 2, 4];
    
    print <<END_REPORT;
------------------------------------------------------------
$self->{engine} $self->{version} 
Perl $Config{version}
Thread support: $thread_support
@uname_info
Mean: $mean secs 
Truncated mean ($num_kept kept, $num_discarded discarded): $trunc_mean secs
------------------------------------------------------------
END_REPORT
}

package BenchmarkingIndexer::KinoSearch1;
use strict;
use warnings;
use base qw( BenchmarkingIndexer );

use Time::HiRes qw( gettimeofday );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    require KinoSearch1;
    require KinoSearch1::InvIndexer;
    require KinoSearch1::Analysis::Tokenizer;

    $self->{index_dir} = 'kinosearch_index';
    $self->{engine}    = 'KinoSearch1';
    $self->{version}   = $KinoSearch1::VERSION;

    return $self;
}

sub init_indexer {
    my ( $self, $count ) = @_;
    my $create = $count ? 0 : 1;

    # spec out the invindexer
    my $analyzer
        = KinoSearch1::Analysis::Tokenizer->new( token_re => qr/\S+/, );
    my $invindexer = KinoSearch1::InvIndexer->new(
        invindex => $self->{index_dir},
        create   => $create,
        analyzer => $analyzer,
    );
    $invindexer->spec_field(
        name       => 'body',
        stored     => $self->{store},
        vectorized => $self->{store},
    );
    $invindexer->spec_field(
        name       => 'title',
        vectorized => 0,
    );

    return $invindexer;
}

# Build an index, stopping at $max docs if $max > 0.
sub build_index {
    my $self = shift;
    $self->delayed_init;
    my ( $max, $increment, $article_filepaths ) 
        = @{$self}{qw( docs increment article_filepaths )};

    # start timer
    my $start = gettimeofday();

    my $invindexer = $self->init_indexer(0);

    my $count = 0;
    while ($count < $max) {
        for my $article_filepath (@$article_filepaths) {
            # the title is the first line, the body is the rest
            open( my $article_fh, '<', $article_filepath )
                or die "Can't open file '$article_filepath'";
            my $title = <$article_fh>;
            my $body  = do { local $/; <$article_fh> };

            # add content to index
            my $doc = $invindexer->new_doc;
            $doc->set_value( title => $title );
            $doc->set_value( body  => $body );
            $invindexer->add_doc($doc);

            # bail if we've reached spec'd number of docs
            $count++;
            last if $count >= $max;
            if ( $count % $increment == 0 and $count ) {
                $invindexer->finish;
                undef $invindexer;
                $invindexer = $self->init_indexer($count);
            }
        }
    }

    # finish index
    $invindexer->finish( optimize => 1 );

    # return elapsed seconds
    my $end = gettimeofday();
    my $secs = $end - $start;
    return ( $count, $secs );
}

package BenchmarkingIndexer::Plucene;
use strict;
use warnings;
use base qw( BenchmarkingIndexer );

use Time::HiRes qw( gettimeofday );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    require Plucene;
    require Plucene::Document;
    require Plucene::Document::Field;
    require Plucene::Index::Writer;
    require Plucene::Analysis::WhitespaceAnalyzer;

    $self->{index_dir} = 'plucene_index';
    $self->{engine}    = 'Plucene';
    $self->{version}   = $Plucene::VERSION;

    return $self;
}

sub init_indexer {
    my ( $self, $count ) = @_;
    my $create = $count ? 0 : 1;
    my $writer = Plucene::Index::Writer->new( $self->{index_dir},
        Plucene::Analysis::WhitespaceAnalyzer->new(), $create );
    $writer->set_mergefactor(1000);
    return $writer;
}

# Build an index, stopping at $max docs if $max > 0.
sub build_index {
    my $self = shift;
    $self->delayed_init;
    my ( $max, $increment, $article_filepaths ) 
        = @{$self}{qw( docs increment article_filepaths )};

    # cause text to be stored if spec'd
    my $field_constructor = $self->{store} ? 'Text' : 'UnStored';

    # start timer
    my $start = gettimeofday();

    my $writer = $self->init_indexer(0);

    my $count = 0;
    while ($count < $max) {
        for my $article_filepath (@$article_filepaths) {
            # the title is the first line, the body is the rest
            open( my $article_fh, '<', $article_filepath )
                or die "Can't open file '$article_filepath'";
            my $title = <$article_fh>;
            my $body  = do { local $/; <$article_fh> };

            # add content to index
            my $doc = Plucene::Document->new;
            $doc->add( Plucene::Document::Field->Text( title => $title ) );
            $doc->add( 
                Plucene::Document::Field->$field_constructor( body  => $body ) 
            );
            $writer->add_document($doc);

            # bail if we've reached spec'd number of docs
            $count++;
            last if ( $count >= $max );
            if ( $count % $increment == 0 and $count ) {
                undef $writer;
                $writer = $self->init_indexer($count);
            }
        }
    }

    # finish index
    $writer->optimize;

    # return elapsed seconds
    my $end = gettimeofday();
    my $secs = $end - $start;
    return ( $count, $secs );
}

1;
