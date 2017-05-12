#! /usr/bin/perl -w

use strict;

use ExtUtils::testlib;
use GSSAPI;

my $targethostname = 'HTTP@moerbsen.grolmsnet.lan';
my $status;
#-----------------------------------------------------------------
my $server =  $ARGV[0] || die "\n\nusage: $0 servicename \n (eg HTTP\@moerbsen.grolmsnet.lan) \n\n";

$server eq 'servicename' && die "\n\ngreat, you have just copypasted the parametername. But the testscript wants you to pass a servername for test if getting a GSSAPI token works.\n\n";


#-----------------------------------------------------------------
TRY: {
     my ($target, $tname, $ttl );
     $status = GSSAPI::Name->import( $target,
                                     $server,
                                     GSSAPI::OID::gss_nt_hostbased_service)
               or last;
     $status = $target->display($tname) or last;
     print "\n using Name $tname";

     my $ctx = GSSAPI::Context->new();
     my $imech = GSSAPI::OID::gss_mech_krb5;
     my $iflags = 0 ;
     my $bindings = GSS_C_NO_CHANNEL_BINDINGS;
     my $creds = GSS_C_NO_CREDENTIAL;
     my $itime = 0;
     my $itoken = q{};
     my $otoken;

     $status = $ctx->init($creds,$target,
                          $imech,$iflags,$itime,$bindings,$itoken,
                          undef, $otoken,undef,undef) or last;
     $status = $ctx->valid_time_left($ttl) or last;
     print "\n Security context's time to live $ttl secs";
}

unless ($status->major == GSS_S_COMPLETE  ) {
   print "\nErrors: ", $status;
} else {
   print "\n seems everything is fine, type klist to see the ticket\n";
}