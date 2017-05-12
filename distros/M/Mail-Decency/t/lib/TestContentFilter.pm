package TestContentFilter;

use strict;
use TestMisc;
use Mail::Decency::ContentFilter;
use MIME::Parser;
use FindBin qw/ $Bin /;
use Test::More;
use base qw/ Exporter /;
our @EXPORT = qw/ ok_mime_header /;

sub create {
    return TestMisc::create_server( 'Mail::Decency::ContentFilter', 'content-filter', {
        spool_dir => "$Bin/data/spool-dir"
    } );
}


sub get_test_file {
    
    # there is the orig file
    my $testmail = "$Bin/data/mime-test/testmail.eml";
    open my $fh, '<', $testmail or die "Cannot open '$testmail' for read: $!";
    
    # new temp file
    my $temp_file = "$Bin/data/tempmail-1234";
    open my $th, '>', $temp_file or die "Canot open temp file '$temp_file' for write: $!";
    
    # copy
    print $th $_ while( <$fh> );
    
    # lose
    close $th;
    close $fh;
    
    return ( $temp_file, -s $temp_file );
}


sub ok_mime_header {
    my ( $file, $header, $sub_check, $message ) = @_;
    
    # testing output dir
    my $mime_dir = "$Bin/data/test-mime";
    mkdir( $mime_dir )
        or die "Cannot make temp mime dir '$mime_dir'\n"
        unless -d $mime_dir;
    
    # create new parser
    my $parser = MIME::Parser->new();
    $parser->output_under( $mime_dir );
    
    # reade mime file
    open my $fh, '<', $file or die "Cannot open mime file '$file' for read: $!\n";
    my $entity = $parser->parse( $fh );
    close $fh;
    
    my $res = 0;
    if ( $entity && scalar ( my @values = $entity->head->get( $header ) ) > 0 ) {
        eval {
            $res = $sub_check->( \@values );
        };
        diag( "Error in check method for mime: $@" ) if $@;
    }
    else {
        $res = $sub_check->( [] );
    }
    
    # cleanup
    $parser->filer->purge;
    
    ok( $res, $message );
}


1;
