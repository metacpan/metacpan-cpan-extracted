package
        JavaScript::Duktape::C::libPath;
use File::Spec;
my $file = File::Spec->rel2abs(__FILE__);
$file =~ m/(.*?)libPath\.pm/;
our $dir = File::Spec->canonpath( $1 );

sub getPath {
    my $extra = shift;
    return File::Spec->canonpath( $dir . '/' . $extra );
}

sub getFile {
    my $file = shift;
    $file = File::Spec->canonpath( $dir . '/' . $file );
}

1;
