use warnings;
use Test::More;
use strict;
use warnings;
require 't/test-lib.pm';
require_ok('./scripts/downloadSamlMetadata');
use LWP::UserAgent;

my $metadata_body;

my $fixture_valid_metadata = <<EOF;
<md:EntitiesDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata">
</md:EntitiesDescriptor>
EOF

sub write_file {
    my ( $file, $content ) = @_;
    open( my $fh, '>', $file ) or die $!;
    print $fh $content;
    close($fh);
}

sub read_file {
    my ($file) = @_;
    open( my $fh, '<', $file ) or die $!;

    my $content = join( '', <$fh> );
    close($fh);

    return $content;
}

sub check_leftovers {
    my ($file) = @_;
    my @files = glob("$file?*");
    is( scalar(@files), 0, "Temporary files were cleaned up" )
      or diag explain \@files;
}

# Mocking
{
    no warnings 'redefine', 'once';
    *printlog = sub {
        note @_;
    };

    *printfatal = sub {
        note "FATAL: ", @_;
    };

    sub LWP::UserAgent::request {
        my ( $self, $req, $file ) = @_;

        if ( $req->uri eq "http://xx.yy/" ) {

            ok( $file, "File destination was provided" );

            # Write to file
            write_file( $file, $metadata_body );

            # Return result
            my $httpResp = HTTP::Response->new( 200, 'OK' );
            $httpResp->header( 'Content-Type',   'application/json' );
            $httpResp->header( 'Content-Length', length($metadata_body) );
            return $httpResp;
        }
        else {
            my $httpResp = HTTP::Response->new( 404, 'Not found' );
            return $httpResp;
        }
    }
}

sub checkcontent {
    my ( $file, $content ) = @_;

    my $read_content = read_file($file);

    is( $read_content, $content, "Correct content found" );
}

my $dest = do {
    no warnings 'once';
    "$main::tmpDir/output.xml";
};

subtest "Dry run, do not create file" => sub {
    $metadata_body = $fixture_valid_metadata;
    is(
        downloadSamlMetadata(
            { metadata => "http://xx.yy/", output => $dest, "dry-run" => 1 }
        ),
        0,
        "Successful function run"
    );
    ok( !-e $dest, "Destination file not created" );
    check_leftovers($dest);
};

subtest "Download valid metadata, first time" => sub {
    $metadata_body = $fixture_valid_metadata;
    is(
        downloadSamlMetadata(
            { metadata => "http://xx.yy/", output => $dest }
        ),
        0,
        "Successful function run"
    );
    checkcontent( $dest, $metadata_body );
    check_leftovers($dest);

};

subtest "Download valid metadata, overwrite existing file" => sub {
    $metadata_body = $fixture_valid_metadata;
    write_file( $dest, "old" );
    checkcontent( $dest, "old" );
    is(
        downloadSamlMetadata(
            { metadata => "http://xx.yy/", output => $dest }
        ),
        0,
        "Failed function run"
    );
    checkcontent( $dest, $metadata_body );
    check_leftovers($dest);

};

subtest "Dry run, do not overwrite file" => sub {
    $metadata_body = $fixture_valid_metadata;
    write_file( $dest, "old" );
    checkcontent( $dest, "old" );
    is(
        downloadSamlMetadata(
            { metadata => "http://xx.yy/", output => $dest, "dry-run" => 1 }
        ),
        0,
        "Successful function run"
    );
    checkcontent( $dest, "old" );
    check_leftovers($dest);
};

subtest "URL not found" => sub {
    $metadata_body = "<xml>test</x";
    write_file( $dest, "old" );
    is(
        downloadSamlMetadata(
            { metadata => "http://404.404/", output => $dest }
        ),
        1,
        "Failed function run"
    );
    checkcontent( $dest, "old" );
    check_leftovers($dest);
};

subtest "Try to download invalid XML" => sub {
    $metadata_body = "<xml>test</x";
    write_file( $dest, "old" );
    is(
        downloadSamlMetadata(
            { metadata => "http://xx.yy/", output => $dest }
        ),
        1,
        "Failed function run"
    );
    checkcontent( $dest, "old" );
    check_leftovers($dest);
};

subtest "Download valid XML but not metadata" => sub {
    $metadata_body = "<xml>test</xml>";
    write_file( $dest, "old" );
    checkcontent( $dest, "old" );
    is(
        downloadSamlMetadata(
            { metadata => "http://xx.yy/", output => $dest }
        ),
        1,
        "Failed function run"
    );
    checkcontent( $dest, "old" );
    check_leftovers($dest);

};

done_testing();
