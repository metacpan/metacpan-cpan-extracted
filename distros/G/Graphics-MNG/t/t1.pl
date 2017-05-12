#!perl 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 24 };
use Graphics::MNG;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Graphics::MNG qw( MNG_OUTOFMEMORY MNG_INCLUDE_TRACE_PROCS MNG_NOCALLBACK );
ok(1);   # loaded an export-ok constant


# we purposely generate a warning, but we don't want to display it.
my $actual_warnings = 0;
sub trap_warnings;
sub trap_warnings
{
   $SIG{'__WARN__'} = \&trap_warnings;

   return unless @_;

   if ( $_[0] =~ /wrong type for callback function/ )
   {
      $actual_warnings++;
      return;
   }

   warn(@_);
}

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

sub oo_testing
{
   use Graphics::MNG qw( MNG_TEXT_WARNING );
   # test object oriented functionality
   my $rv;
   my $data = "this";
   my $dataref = \$data;
   my $obj1 = Graphics::MNG::new();
   ok(1);
   my $obj2 = new Graphics::MNG ( $dataref );
   ok(1);
   undef $dataref;

   $rv = $obj1->setcb_traceproc( \&trace_fn );
   ok( $rv, (MNG_INCLUDE_TRACE_PROCS() ? MNG_NOERROR : MNG_NOCALLBACK), "testing setcb_traceproc()" );
   $rv = $obj1->setcb_traceproc( \&trace_fn );
   ok( $rv, (MNG_INCLUDE_TRACE_PROCS() ? MNG_NOERROR : MNG_NOCALLBACK), "testing setcb_traceproc()" );
   $rv = $obj1->setcb_traceproc( undef );
   ok( $rv, (MNG_INCLUDE_TRACE_PROCS() ? MNG_NOERROR : MNG_NOCALLBACK), "testing setcb_traceproc()" );



   # what happens if we call get_userdata on this thing now?
   $rv = $obj1->reset();
   ok( $rv, MNG_NOERROR, "checking OO::reset()" );

   $rv = $obj1->get_userdata();
   ok( $rv, undef, "checking OO::get_userdata()" );

   $rv = $obj2->get_userdata();
   ok( $$rv, $data, "checking OO::get_userdata()" );

   $rv = $obj2->get_userdata();
   ok( $$rv, $data, "checking OO::get_userdata()" );

   # test inline'd functions from XS
   my $version_text = $obj1->version_text() || '';
   my ( $major, $minor, $release ) =  $version_text =~ m/^(1).(0).([23])$/;
   ok( ($version_text ne ""), 1, "testing mng_version_text()" );
   ok( $obj1->version_major(), $major, "testing mng_version_major()" );
   ok( $obj1->version_minor(), $minor, "testing mng_version_minor()" );
   ok( $obj1->version_release(), $release, "testing mng_version_release()" );


   # make sure that the capitalized constant functions still exist
   ok( MNG_TEXT_WARNING(), "Warning", "testing MNG_TEXT_WARNING()" );

   my $called = undef;
   my $bool;
   $bool = $obj2->test_callback_fn( sub{ $called=1; return 0; } );
   ok($bool,0, "checking test callback function");
   ok($called,1, "checking test callback function");
   $global_called=undef;
   $bool = $obj2->test_callback_fn( \&callback );
   ok($bool,1, "checking test callback function");
   ok($global_called,1, "checking test callback function");

   # check lexically scoped warning pragmas for our module
   {
      no warnings 'Graphics::MNG';
      $bool = $obj2->test_callback_fn( $obj2 );
      ok($bool,undef, "checking test callback function");

      use warnings 'Graphics::MNG';
      $bool = $obj2->test_callback_fn( undef );
      ok($bool,undef, "checking test callback function");
   }

   # make sure we generated the right number of warnings
   ok($actual_warnings,1,'intercepted warnings');

   my $stuff;
   my $in = 'hey';
   $stuff = $obj2->get_userdata();
   $stuff = $obj2->get_userdata();
   $stuff = $obj2->get_userdata();
   $obj2->set_userdata($in);
   $in = undef;
   undef $in;
   $stuff = $obj2->get_userdata();
   $stuff = $obj2->get_userdata();
   $stuff = $obj2->get_userdata();
   $obj2->set_userdata('man');
   $stuff = $obj2->get_userdata();
   $stuff = $obj2->get_userdata();
   $stuff = $obj2->get_userdata();
   

   # -------------- these should be the last statements in this subroutine
   undef $obj2; 
   undef $obj1;
   ok(1);
}


### here's where it all happens...


trap_warnings();
oo_testing();
exit(0);


