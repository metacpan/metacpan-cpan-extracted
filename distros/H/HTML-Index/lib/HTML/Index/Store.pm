package HTML::Index::Store;

use Carp;
no Carp::Assert;
use Compress::Zlib;
use Text::Soundex qw( soundex );
require Lingua::Stem;

=head1 NAME

HTML::Index::Store - subclass'able module for storing inverted index files for
the L<HTML::Index> modules.

=head1 SYNOPSIS

    my $store = HTML::Index::Store->new( 
        MODE => 'r',
        COMPRESS => 1,
        DB => $db,
        STOP_WORD_FILE => $path_to_stop_word_file,
    );

=head1 DESCRIPTION

The HTML::Index::Store module is generic interface to provide storage for the
inverted indexes used by the HTML::Index modules. The reference implementation
uses in memory storage, so is not suitable for persistent applications (where
the search / index functionality is seperated).

There are two subclasses of this module provided with this distribution;
HTML::Index::Store::BerkeleyDB and HTML::Index::Store::DataDumper

=cut

my %OPTIONS = (
    DB => { sticky => 0 },
    MODE => { sticky => 0 },
    STOP_WORD_FILE => { sticky => 1 },
    COMPRESS => { sticky => 1 },
    STEM => { sticky => 1 },
    SOUNDEX => { sticky => 1 },
    VERBOSE => { sticky => 0 },
    NOPACK => { sticky => 1 },
);

=head1 CONSTRUCTOR OPTIONS

Constructor options allow the HTML::Index::Store to provide a token to identify
the database that is being used (this might be a directory path of a Berkeley
DB implementation, or a database descriptor for a DBI implementation). It also
allows options to be set. Some of these options are then stored in an options
table in the database, and are therefore "sticky" - so that the search
interface can automatically use the same options setting used at creating time.

=over 4

=item DB

Database identifier. Available to subclassed modules using the DB method call.
Not sticky.

=item MODE

Either 'r' or 'rw' depending on whether the HTML::Index::Store module is
created in read only or read/write mode. Not sticky.

=item STOP_WORD_FILE

The path to a stopword file. If set, the same stopword file is available for
both creation and searching of the index (i.e. sticky).

=item COMPRESS

If true, use Compress::Zlib compression on the inverted index file. The same
compression is used for searching and indexing (i.e. sticky).

=item STEM

An option, if set, causes the indexer to use the Lingua::Stem module to stem
words before they are indexed, and the searcher to use the same stemming on the
search terms (i.e. sticky). Takes a locale as an argument.

=item SOUNDEX

An option, if set, causes the searcher to use the Text::Soundex to expand a
query term on search if an exact match isn't found. To work, this option needs
to be set at indexing, so that entries for soundex terms can be added to the
index (i.e. sticky). If this has been done, then a SOUNDEX option can be passed
to the search function to ennable soundex matching for a particular query.

=item VERBOSE

An option which causes the indexer / searcher to print out some debugging
information to STDERR.

=item NOPACK

An option which prevents the storer from packing data into binary format.
Mainly used for debugging (sticky).

=back

=cut

my %BITWISE = (
    and => '&',
    or  => '|',
    not => '~',
);

my $BITWISE_REGEX = '(' . join( '|', keys %BITWISE ) . ')';

use vars qw( %TABLES );

%TABLES = (
    options => 'HASH',
    file2fileid => 'HASH',
    fileid2file => 'ARRAY',
    word2fileid => 'HASH',
);

affirm { print STDERR "WARNING: Debugging is switched on ... " };

sub new
{
    my $class = shift;
    my %opts = @_;
    my $self = bless \%opts, $class;
    $self->init();
    return $self;
}

=head1 PUBLIC INTERFACE

These methods are used as an interface to the underlying store. Subclasses of
HTML::Index::Store should implement L</"SUB-CLASSABLE METHODS">, but can
optionally directly subclass methods in the public interface as well.

=over 4

=item index_document( $document )

Takes an HTML::Index::Document object as an argument, and adds it to the index.

=cut

sub index_document
{
    my $self = shift;
    my $document = shift;

    croak "$document isn't an HTML::Index::Document object\n"
        unless ref( $document ) eq 'HTML::Index::Document'
    ;
    my $name = $document->name;
    croak "$document doesn't have a name\n" unless defined( $name );
    my $file_id = $self->_get_file_id( $name );
    if ( defined( $file_id ) )
    {
        carp "$name ($file_id) already indexed ...\n" if $self->{VERBOSE};
    }
    else
    {
        $file_id = $self->_new_file_id();
        affirm { defined( $file_id ) };
        carp "$name is a new document ($file_id) ...\n" if $self->{VERBOSE};
        $self->_put( 'file2fileid', $name, $file_id );
        affirm { $self->_get( 'file2fileid', $name ) == $file_id };
        $self->_put( 'fileid2file', $file_id, $name );
        affirm { $self->_get( 'fileid2file', $file_id ) eq $name };
    }
    carp "index $name ...\n" if $self->{VERBOSE};
    if ( defined $file_id )
    {
        my $text = $document->parse();
        $self->_add_words( $file_id, $text );
    }
}

=item deindex_document( $document )

Takes an HTML::Index::Document object as an argument, and removes it from the
index.

=cut

sub deindex_document
{
    my $self = shift;
    my $document = shift;

    croak "$document isn't an HTML::Index::Document object\n"
        unless ref( $document ) eq 'HTML::Index::Document'
    ;
    my $name = $document->name;
    croak "$document doesn't have a name\n" unless defined( $name );
    carp "deindex $name\n" if $self->{VERBOSE};
    my $file_id = $self->_get( 'file2fileid', $name );
    croak "document $name not in dataset\n" unless defined $file_id;
    for my $word ( $self->get_keys( 'word2fileid' ) )
    {
        my $file_ids = $self->_get( 'word2fileid', $word );
        affirm { defined( $file_ids ) };
        my $new_file_ids = $self->_remove_file_id( $file_ids, $file_id );
        next if $new_file_ids eq $file_ids;
        $self->_put( 'word2fileid', $word, $new_file_ids );
        affirm { $self->_get( 'word2fileid', $word ) eq $new_file_ids };
    }
}

=item search( $q )

Takes a search query, $q, and  returns a list of HTML::Index::Document objects
corresponding to the documents that match that query.

=cut

sub search
{
    my $self = shift;
    my $q = shift;

    carp "Search for $q\n" if $self->{VERBOSE};
    my %options = @_;
    return () unless defined $q and length $q;
    my $bitstring = $self->_create_bitstring( $q, $options{SOUNDEX} );
    return () unless $bitstring and length( $bitstring );
    my @bits = split( //, $self->_str2bits( $bitstring ) );
    return () unless @bits;
    carp "bits @bits\n" if $self->{VERBOSE};
    my @results = map { $bits[$_] == 1 ? $_ : () } 0 .. $#bits;
    @results = map { $self->_get( 'fileid2file', $_ ) } @results;
    carp "results @results\n" if $self->{VERBOSE};
    return @results;
}

=item filter( @w )

Takes a list of words, and returns a filtered list after filtering
(lowercasing, non-alphanumerics removed, short (<2 letter) words removed,
stopwords, stemming).

=cut

sub filter
{
    my $self = shift;
    my @w = @_;
    my @n;
    for ( @w )
    {
        tr/A-Z/a-z/;                    # convert to lc
        tr/a-z0-9//cd;                  # delete all non-alphanumeric 
        next unless length( $_ );       # ... and delete empty strings that
                                        # result ...
        next unless /^.{2,}$/;          # at least two characters long
        next unless /[a-z]/;            # at least one letter
        next if $self->_is_stopword( $_ );
        $_ = $self->_stem( $_ );
        push( @n, $_ ) if defined $_;
    }
    return wantarray ? @n : $n[0];
}

=head1 SUB-CLASSABLE METHODS

=over 4

=item init

Initialisation method called by the constructor, which gets passed the options
hash (see L</"CONSTRUCTOR OPTIONS">). Any subclass of init should call
$self->SUPER::init().

=cut

sub init
{
    my $self = shift;
    my %options = @_;

    while ( my ( $table, $type ) = each %TABLES )
    {
        $self->create_table( $table, $type );
    }
    for ( keys %options )
    {
        croak "unrecognised option $_\n" unless exists $OPTIONS{$_};
    }
    for ( grep { $OPTIONS{$_}->{sticky} } keys %OPTIONS )
    {
        if ( defined $self->{$_} )
        {
            # save options
            $self->_put( 'options', $_, $self->{$_} );
        }
        else
        {
            # get options
            $self->{$_} = $self->_get( 'options', $_ );
            carp "OPTION $_ = $self->{$_}\n" if $self->{$_} and $self->{VERBOSE};
        }
    }
    $self->_init_stopwords();
    $self->{stemmer} = Lingua::Stem->new( -locale => $self->{STEM} )
        if $self->{STEM}
    ;
    $self->{words} = [];
}

=item create_table( $table )

Create a table named $table.

=cut

sub create_table
{
}

=item get( $table, $key )

Get the $key entry in the $table table.

=cut

sub get
{
    my $self = shift;
    my $table = shift;
    my $key = shift;

    confess "searching for undefined key\n" unless defined $key;
    return $self->{$table}{$key};
}

=item put( $table, $key, $val )

Set the $key entry in the $table table to the value $val.

=cut

sub put
{
    my $self = shift;
    my $table = shift;
    my $key = shift;
    my $val = shift;

    $self->{$table}{$key} = $val;
}

=item del( $table, $key )

Delete the $key entry from the $table table.

=cut

sub del
{
    my $self = shift;
    my $table = shift;
    my $key = shift;

    delete( $self->{$table}{$key} );
}

=item get_keys( $table )

Delete a list of the keys from the $table table.

=cut

sub get_keys
{
    my $self = shift;
    my $table = shift;
    return keys( %{$self->{$table}} );
}

=item nkeys( $table )

Returns the number of keys in the $table table.

=back

=cut

sub nkeys
{
    my $self = shift;
    my $table = shift;

    return scalar $self->get_keys( $table );
}

#------------------------------------------------------------------------------
#
# Private methods
#
#------------------------------------------------------------------------------


sub _deflate
{
    my $data = shift;
    return $data unless $self->{COMPRESS};
    my ( $deflate, $out, $status );
    ( $deflate, $status ) = deflateInit( -Level => Z_BEST_COMPRESSION )
        or croak "deflateInit failed: $status\n"
    ;
    ( $out, $status ) = $deflate->deflate( \$data );
    croak "deflate failed: $status\n" unless $status == Z_OK;
    $data = $out;
    ( $out, $status ) = $deflate->flush();
    croak "flush failed: $status\n" unless $status == Z_OK;
    $data .= $out;
    return $data;
}

sub _inflate
{
    my $data = shift;
    return $data unless $self->{COMPRESS};
    my ( $inflate, $status );
    ( $inflate, $status ) = inflateInit()
        or croak "inflateInit failed: $status\n"
    ;
    ( $data, $status ) = $inflate->inflate( \$data )
        or croak "inflate failed: $status\n"
    ;
    return $data;
}

sub _get
{
    my $self = shift;
    my $table = shift;
    my $key = shift;
    return _inflate( $self->get( $table, $key ) );
}

sub _put
{
    my $self = shift;
    my $table = shift;
    my $key = shift;
    my $val = shift;
    $self->put( $table, $key, _deflate( $val ) );
}

sub _stem
{
    my $self = shift;
    my $w = shift;
    return $w unless $self->{stemmer};
    $wa = $self->{stemmer}->stem( $w );
    carp "stem $w -> $wa->[0]\n" if $self->{VERBOSE};
    return $wa->[0];
}

sub _init_stopwords
{
    my $self = shift;
    return unless $self->{STOP_WORD_FILE};
    return unless -e $self->{STOP_WORD_FILE};
    return unless -r $self->{STOP_WORD_FILE};
    return unless open( STOPWORDS, $self->{STOP_WORD_FILE} );
    my @w = <STOPWORDS>;
    close( STOPWORDS );
    chomp( @w );
    $self->{stopwords} = { map { lc($_) => 1 } @w };
}

sub _is_stopword
{
    my $self = shift;
    my $word = shift;
    return 0 unless $self->{STOP_WORD_FILE};
    return exists $self->{stopwords}{lc($word)};
}


sub _bits2str
{
    my $self = shift;
    my $bits = shift;
    return $self->{NOPACK} ? $bits : pack( "B*", $bits );
}

sub _str2bits
{
    my $self = shift;
    my $str = shift;
    return $self->{NOPACK} ? $str : join( '', unpack( "B*", $str ) );
}

sub _get_file_id
{
    my $self = shift;
    my $name = shift;

    return $self->_get( 'file2fileid', $name );
}

sub _new_file_id
{
    my $self = shift;
    return $self->nkeys( 'fileid2file' ) || 0;
}

sub _del_document
{
    my $self = shift;
    my $name = shift;

    my $file_id = $self->_get( 'file2fileid', $name );
    croak "$name is not in the dataset\n" unless $file_id;
    $self->del( 'file2fileid', $name );
    $self->del( 'fileid2file', $file_id );
    return $file_id;
}

sub _get_words
{
    my $self = shift;
    my $text = shift;

    my %seen = ();
    my @w = grep /\w/, split( /\b/, $text );
    @w = $self->filter( @w );
    @w = grep { ! $seen{$_}++ } @w;
    return @w;
}

sub _get_bitstring
{
    my $self = shift;
    my $w = shift;
    my $use_soundex = shift;

    return "\0" if not $w;
    $w = $self->filter( $w );
    return "\0" if not $w;
    carp "$w ...\n" if $self->{VERBOSE};
    my $file_ids = $self->_get( 'word2fileid', $w );
    if ( not $file_ids and $self->{SOUNDEX} and $use_soundex )
    {
        my $soundex = soundex( $w );
        carp "soundex( $w ) = $soundex\n" if $self->{VERBOSE};
        $file_ids = $self->_get( 'word2fileid', $soundex );
    }
    return "\0" unless $file_ids;
    push( @{$self->{words}}, $w );
    $file_ids =~ s/\\/\\\\/g;
    $file_ids =~ s/'/\\'/g;
    return $file_ids;
}

sub _create_bitstring
{
    my $self = shift;
    my $q = lc( shift );
    my $use_soundex = shift;

    $q =~ s/-/ /g;              # split hyphenated words
    $q =~ s/[^\w\s()]//g;       # get rid of all non-(words|spaces|brackets)
    $q =~ s/\b$BITWISE_REGEX\b/$BITWISE{$1}/gi;  
                                # convert logical words to bitwise operators
    1 while $q =~ s/\b(\w+)\s+(\w+)\b/$1 & $2/g;
                                # assume any consecutive words are AND'ed
    $q =~ s/\b(\w+)\b/"'" . $self->_get_bitstring( $1, $use_soundex ) . "'"/ge;
                                # convert words to bitwise string
    my $result = eval $q;       # eval bitwise strings / operators
    if ( $@ )
    {
        carp "eval error: $@\n";
    }
    return $result;
}

sub _add_words
{
    my $self = shift;
    my $file_id = shift;
    my $text = shift;

    for my $w ( $self->_get_words( $text ) )
    {
        my $file_ids = $self->_get( 'word2fileid', $w );
        $file_ids = $self->_add_file_id( $file_ids, $file_id );
        $self->_put( 'word2fileid', $w, $file_ids );
        if ( $self->{SOUNDEX} )
        {
            my $soundex = soundex( $w );
            $file_ids = $self->_get( 'word2fileid', $soundex );
            $file_ids = $self->_add_file_id( $file_ids, $file_id );
            $self->_put( 'word2fileid', $soundex, $file_ids );
        }
    }
}

sub _get_mask
{
    my $self = shift;
    my $bit = shift;

    my $bits = ( "0" x ($bit) ) . "1";
    my $str = $self->_bits2str( $bits );
    return $str;
}

sub _add_file_id
{
    my $self = shift;
    my $file_ids = shift;
    my $file_id = shift;

    my $mask = $self->_get_mask( $file_id );
    if ( defined $file_ids )
    {
        $file_ids = ( '' . $file_ids ) | ( '' . $mask );
    }
    else
    {
        $file_ids = $mask;
    }
    return $file_ids;
}

sub _remove_file_id
{
    my $self = shift;
    my $file_ids = shift;
    my $file_id = shift;

    my $mask = $self->_get_mask( $file_id );
    my $block = $file_ids;
    if ( $self->{NOPACK} )
    {
        my @mask = split( '', $mask );
        my @block = split( '', $block );
        my @file_ids = map { $mask[$_] && $block[$_] ? 1 : 0 } 0 .. @block;
        return join( '', @file_ids );
    }
    $file_ids = ( '' . $block ) & ~ ( '' . $mask );
    return $file_ids;
}

#------------------------------------------------------------------------------
#
# True
#
#------------------------------------------------------------------------------

1;

=head1 SEE ALSO

=over 4

=item L<HTML::Index>

=item L<HTML::Index::Store::BerkeleyDB>

=item L<HTML::Index::Store::DataDumper>

=item L<Compress::Zlib>

=item L<Lingua::Stem>

=item L<Text::Soundex>

=back

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2003 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
