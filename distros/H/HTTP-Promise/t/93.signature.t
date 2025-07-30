#!/usr/bin/perl

use Test2::V0;
# use Test2::Tools::Basic;

if ($ENV{AUTHOR_TESTING} < 2) {
    skip_all( "Set the environment variable AUTHOR_TESTING to enable this test." );
}
elsif (!eval { require Module::Signature; 1 }) {
    skip_all( "Next time around, consider installing Module::Signature, ".
      "so you can verify the integrity of this distribution." );
}
elsif ( !-e 'SIGNATURE' ) 
{
    skip_all( "SIGNATURE not found" );
}
elsif ( -s 'SIGNATURE' == 0 ) {
    skip_all( "SIGNATURE file empty" );
}
elsif (!eval { require Socket; Socket::inet_aton('keyserver.ubuntu.com') }) {
    skip_all( "Cannot connect to the keyserver to check module signature" );
}
else {
    plan tests => 1;
}

my $ret = Module::Signature::verify();
SKIP: {
    skip "Module::Signature cannot verify", 1 
      if $ret eq Module::Signature::CANNOT_VERIFY();

    cmp_ok $ret, '==', Module::Signature::SIGNATURE_OK(), "Valid signature";
}

done_testing();

__END__

