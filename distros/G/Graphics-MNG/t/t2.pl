#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 16 };
use Graphics::MNG;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Graphics::MNG qw( MNG_UINT_MHDR MNG_FUNCTIONINVALID );
ok(1);   # loaded an export-ok constant

my $global_called = undef;
sub callback
{
   $global_called = 1;
   return 1;
}

sub trace_fn
{
   my ( $hHandle, $iFuncnr, $iFuncseq, $zFuncname ) = @_;
   print "Trace: \n",
         "\thHandle=$hHandle\n",
         "\tiFuncnr=$iFuncnr\n",
         "\tiFuncseq=$iFuncseq\n",
         "\tzFuncname=$zFuncname\n";
   return MNG_TRUE;
}

sub functional_testing
{
   use Graphics::MNG qw( :fns MNG_TEXT_AUTHOR );


   ok(MNG_NULL(),        0,        "checking MNG_NULL");          # used an exported constant OK
   ok(MNG_TEXT_AUTHOR(), "Author", "checking MNG_TEXT_AUTHOR");   # used an exported constant OK

   {
      my $out = '';
      $out .= version_text();
      $out .= version_so();
      $out .= version_dll();
      $out .= version_major();
      $out .= version_minor();
      $out .= version_release();
      ok(1,1,"checking version numbers");   # printed out version numbers OK
   }

   my $handle;

   my $data = $0;
   $handle = initialize( $data );
   $data=undef;
   undef $data;
   ok( MNG_NULL != $handle ? 1:0, 1, "checking initialize retval" );  # loaded the library OK

   my $dollar_zero = get_userdata( $handle );
   ok( $dollar_zero, $0, "checking user data" );   # successfully saved/restored data
   $dollar_zero=undef;
   undef $dollar_zero;

   my $rv;
   $rv = reset( $handle );
   ok( $rv, MNG_NOERROR, "checking reset retval" );

   {
      no warnings 'Graphics::MNG';
      $rv = reset( 0 );
      ok( $rv, MNG_INVALIDHANDLE, "checking for invalid handle" );
   }

   {
      my ( $rv, @stuff ) = getlasterror($handle);
      ok( $rv, MNG_NOERROR, "getting last error message" );
      ok( int @stuff, 0, "checking for empty args from getlasterror on MNG_NOERROR" );
   }

   $rv = putchunk_info( $handle, MNG_UINT_MHDR );
   ok($rv,MNG_FUNCTIONINVALID,"trying to write an mhdr block before calling create()");
   {
      my ( $stat, $severity, $chunkname, $chunkseq, $extra1, $extra2, $text ) = getlasterror($handle);
      ok( $stat, MNG_FUNCTIONINVALID, "getting last error message" );
      ok( ($text ne '')?1:0, 1, "checking for non-NULL text description of error" );
      print "Last error: $stat: severity=$severity, chunk=$chunkname, seq=$chunkseq, [$extra1, $extra2]:\n\tmsg='$text'\n";
   }




   $rv = cleanup( $handle );
   ok( $rv, MNG_NOERROR, "checking cleanup retval" );
   ok( $handle, MNG_NULL, "checking cleanup handle" );
}

### here's where it all happens...
functional_testing();
exit(0);


