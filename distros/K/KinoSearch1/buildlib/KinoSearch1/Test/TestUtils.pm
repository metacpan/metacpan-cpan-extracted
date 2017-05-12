use strict;
use warnings;

package KinoSearch1::Test::TestUtils;
use base qw( Exporter );

our @EXPORT_OK = qw(
    working_dir
    create_working_dir
    remove_working_dir
    create_index
    create_persistent_test_index
    test_index_loc
    persistent_test_index_loc
    init_test_index_loc
    get_uscon_docs
    utf8_test_strings
    test_analyzer
);

use KinoSearch1::InvIndexer;
use KinoSearch1::Store::RAMInvIndex;
use KinoSearch1::Store::FSInvIndex;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Analysis::TokenBatch;
use KinoSearch1::Analysis::PolyAnalyzer;

use File::Spec::Functions qw( catdir catfile curdir );
use Encode qw( _utf8_off );
use File::Path qw( rmtree );
use Carp;

my $working_dir = catfile( curdir(), 'kinosearch_test' );

# Return a directory within the system's temp directory where we will put all
# testing scratch files.
sub working_dir {$working_dir}

sub create_working_dir {
    mkdir( $working_dir, 0700 ) or die "Can't mkdir '$working_dir': $!";
}

# Verify that this user owns the working dir, then zap it.  Returns true upon
# success.
sub remove_working_dir {
    return unless -d $working_dir;
    rmtree $working_dir;
    return 1;
}

# Return a location for a test index to be used by a single test file.  If
# the test file crashes it cannot clean up after itself, so we put the cleanup
# routine in a single test file to be run at or near the end of the test
# suite.
sub test_index_loc {
    return catdir( $working_dir, 'test_index' );
}

# Return a location for a test index intended to be shared by multiple test
# files.  It will be cleaned as above.
sub persistent_test_index_loc {
    return catdir( $working_dir, 'persistent_test_index' );
}

# Destroy anything left over in the test_index location, then create the
# directory.  Finally, return the path.
sub init_test_index_loc {
    my $dir = test_index_loc();
    rmtree $dir;
    die "Can't clean up '$dir'" if -e $dir;
    mkdir $dir or die "Can't mkdir '$dir': $!";
    return $dir;
}

# Build a RAM index, using the supplied array of strings as source material.
# The index will have a single field: "content".
sub create_index {
    my @docs = @_;

    my $tokenizer  = KinoSearch1::Analysis::Tokenizer->new;
    my $invindex   = KinoSearch1::Store::RAMInvIndex->new;
    my $invindexer = KinoSearch1::InvIndexer->new(
        invindex => $invindex,
        analyzer => $tokenizer,
        create   => 1,
    );

    $invindexer->spec_field( name => 'content' );

    for (@docs) {
        my $doc = $invindexer->new_doc;
        $doc->set_value( content => $_ );
        $invindexer->add_doc($doc);
    }

    $invindexer->finish;

    return $invindex;
}

# Slurp us constitition docs and build hashrefs.
sub get_uscon_docs {

    my $uscon_dir = catdir( 't', 'us_constitution' );
    opendir( my $uscon_dh, $uscon_dir )
        or die "couldn't opendir '$uscon_dir': $!";
    my @filenames = grep {/\.html$/} sort readdir $uscon_dh;
    closedir $uscon_dh or die "couldn't closedir '$uscon_dir': $!";

    my %docs;

    for my $filename (@filenames) {
        next if $filename eq 'index.html';
        my $filepath = catfile( $uscon_dir, $filename );
        open( my $fh, '<', $filepath )
            or die "couldn't open file '$filepath': $!";
        my $content = do { local $/; <$fh> };
        $content =~ m#<title>(.*?)</title>#s
            or die "couldn't isolate title in '$filepath'";
        my $title = $1;
        $content =~ m#<div id="bodytext">(.*?)</div><!--bodytext-->#s
            or die "couldn't isolate bodytext in '$filepath'";
        my $bodytext = $1;
        $bodytext =~ s/<.*?>//sg;
        $bodytext =~ s/\s+/ /sg;

        $docs{$filename} = {
            title    => $title,
            bodytext => $bodytext,
            url      => "/us_constitution/$filename",
        };
    }

    return \%docs;
}

sub create_persistent_test_index {
    my $invindexer;
    my $polyanalyzer
        = KinoSearch1::Analysis::PolyAnalyzer->new( language => 'en' );

    $invindexer = KinoSearch1::InvIndexer->new(
        invindex => persistent_test_index_loc(),
        create   => 1,
        analyzer => $polyanalyzer,
    );
    $invindexer->spec_field( name => 'content' );
    for ( 0 .. 10000 ) {
        my $doc = $invindexer->new_doc;
        $doc->set_value( content => "zz$_" );
        $invindexer->add_doc($doc);
    }
    $invindexer->finish;
    undef $invindexer;

    $invindexer = KinoSearch1::InvIndexer->new(
        invindex => persistent_test_index_loc(),
        analyzer => $polyanalyzer,
    );
    $invindexer->spec_field( name => 'content' );
    my $source_docs = get_uscon_docs();
    for ( values %$source_docs ) {
        my $doc = $invindexer->new_doc;
        $doc->set_value( content => $_->{bodytext} );
        $invindexer->add_doc($doc);
    }
    $invindexer->finish;
    undef $invindexer;

    $invindexer = KinoSearch1::InvIndexer->new(
        invindex => persistent_test_index_loc(),
        analyzer => $polyanalyzer,
    );
    $invindexer->spec_field( name => 'content' );
    my @chars = ( 'a' .. 'z' );
    for ( 0 .. 1000 ) {
        my $content = '';
        for my $num_words ( 1 .. int( rand(20) ) ) {
            for ( 1 .. ( int( rand(10) ) + 10 ) ) {
                $content .= @chars[ rand(@chars) ];
            }
            $content .= ' ';
        }
        my $doc = $invindexer->new_doc;
        $doc->set_value( content => $content );
        $invindexer->add_doc($doc);
    }
    $invindexer->finish( optimize => 1 );
}

# Return 3 strings useful for verifying UTF-8 integrity.
sub utf8_test_strings {
    my $smiley       = "\x{263a}";
    my $not_a_smiley = $smiley;
    _utf8_off($not_a_smiley);
    my $frowny = $not_a_smiley;
    utf8::upgrade($frowny);
    return ( $smiley, $not_a_smiley, $frowny );
}

# Verify an Analyzer's analyze() method.
sub test_analyzer {
    my ( $analyzer, $source, $expected, $message ) = @_;

    my $batch = KinoSearch1::Analysis::TokenBatch->new;
    $batch->append( $source, 0, length($source) );
    
    $batch = $analyzer->analyze($batch);
    my @got;
    while ( $batch->next ) {
        push @got, $batch->get_text;
    }
    Test::More::is_deeply( \@got, $expected, "analyze: $message" );
}

1;

__END__

__COPYRIGHT__

Copyright 2005-2010 Marvin Humphrey

This program is free software; you can redistribute it and/or modify
under the same terms as Perl itself.

