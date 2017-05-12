package main;

use strict;
use warnings;

use Cwd;
use Path::Class;
use autodie; # die if problem reading or writing a file

# This script is executable without installing the DocRaptor module from CPAN.
# If you have installed the DocRaptor module, then you do not need FindBin.
use FindBin;
use lib "$FindBin::Bin/../lib";

use DocRaptor;
use DocRaptor::DocOptions;

my $doc_raptor = DocRaptor->new(
    api_key => 'YOUR_API_KEY_HERE',
);

my $options = DocRaptor::DocOptions->new(
    document_content => 'I am a document!',
    is_test          => 1,
    document_type    => 'pdf',
    document_name    => 'perl-test.pdf',
);

my $response = $doc_raptor->create($options);

if ($response->code == 200)
{
    my $file_name = 'perl-test.pdf';
    my $dir = dir(cwd());
    my $file = $dir->file( $file_name );
    my $file_handle = $file->openw();
    $file_handle->print( $response->content );
    $file_handle->close();
    print "Your document was generated and saved to '$file_name'.\n";
}
else
{
    print( "There was an error generating your document.\n" );
    print( 'Error code: '.$response->code."\n" );
    print( 'Error text: '.$response->content."\n" );
}

1;
