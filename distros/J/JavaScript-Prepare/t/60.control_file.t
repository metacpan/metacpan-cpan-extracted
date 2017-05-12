use strict;
use warnings;

use Test::More tests => 2;
use JavaScript::Prepare;
use Data::Dumper;



my $jsprep = JavaScript::Prepare->new();


# process the files manually
my @file_list = (
    't/control/namespace.js',
    't/control/create_namespace.js',
);

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
$minified = $jsprep->process_file( 't/control/master.js' );
ok( $minified eq $expected )
    or print $minified;
