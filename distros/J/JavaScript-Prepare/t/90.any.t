use strict;
use warnings;

use Test::More tests => 3;
use JavaScript::Prepare;
use Data::Dumper;



my $jsprep   = JavaScript::Prepare->new();
my $expected = <<JSMIN;
if(typeof namespace=="undefined"||!namespace){var namespace={};}
namespace.create=function(){var args=arguments;var alen=args.length;var dest,ns;for(var i=0;i<alen;i++){dest=(""+args[i]).split(".");dlen=dest.length;ns=namespace;for(var j=(dest[0]=="namespace")?1:0;j<dlen;j++){ns[dest[j]]=ns[dest[j]]||{};ns=ns[dest[j]];}}
return ns;};
JSMIN


my $minified = $jsprep->process( 't/dir' );
ok( $minified eq $expected )
    or print $minified;


$minified = $jsprep->process( 't/control/master.js' );
ok( $minified eq $expected )
    or print $minified;


$minified = $jsprep->process(
    't/dir/00-before/namespace.js',
    't/dir/create_namespace.js'
);
ok( $minified eq $expected )
    or print $minified;
