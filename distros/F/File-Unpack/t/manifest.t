#!perl -T

use strict;
use warnings;
use Test::More;

#unless ( $ENV{RELEASE_TESTING} ) {
#    plan( skip_all => "ok" );
#}

eval "use Test::CheckManifest 0.9;";
if ($@)
  {
    plan (skip_all => "Test::CheckManifest 0.9 not there" );
  }
else
  {
    ok_manifest({filter => [ qr{/\.(svn|git)\b}, 
	qr/\.(sw.|files|orig|bak|old|tmp|tar\.bz2)$/,
    	qr{/file_unpack$}
      ]});
  }

# done_testing does not exist on 11.1
#done_testing();
