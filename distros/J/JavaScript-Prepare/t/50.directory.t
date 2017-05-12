use strict;
use warnings;

use Test::More tests => 3;
use JavaScript::Prepare;
use Data::Dumper;



my $jsprep = JavaScript::Prepare->new();

# get the files
my @file_list = $jsprep->get_files_in_directory( 't/dir' );
my @expected  = (
    't/dir/00-before/namespace.js',
    't/dir/create_namespace.js',
);

is_deeply( \@file_list, \@expected )
    or print Dumper \@file_list;


# process the files
my $minified;
my $expected = <<JSMIN;
if(typeof namespace=="undefined"||!namespace){var namespace={};}
namespace.create=function(){var args=arguments;var alen=args.length;var dest,ns;for(var i=0;i<alen;i++){dest=(""+args[i]).split(".");dlen=dest.length;ns=namespace;for(var j=(dest[0]=="namespace")?1:0;j<dlen;j++){ns[dest[j]]=ns[dest[j]]||{};ns=ns[dest[j]];}}
return ns;};
JSMIN

foreach my $file ( @file_list ) {
    $minified .= $jsprep->process_file( $file );
}
ok( $minified eq $expected )
    or print $minified;


# see if the module way is the same
$minified = $jsprep->process_directory( 't/dir' );
ok( $minified eq $expected )
    or print $minified;
