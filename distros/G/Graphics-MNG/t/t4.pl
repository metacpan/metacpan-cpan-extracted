#!perl 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 2 };
use Graphics::MNG;
ok(1); # If we made it this far, we're ok.


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Graphics::MNG qw( MNG_OUTOFMEMORY );
ok(1);   # loaded an export-ok constant

sub examples_testing()
{
   no warnings 'vars';

   # this is all of the possible TAGS that you can import:
   use Graphics::MNG qw( :all :callback_types :canvas :canvas_fns :chunk_fns :chunk_names :chunk_properties :compile_options :constants :errors :fns :misc :version :IJG :ZLIB );
   # note that :all implies everthing, and :constants are imported by default.

   # OO-interface
   use Graphics::MNG;
   my $it=['user data'];
   my $obj = new Graphics::MNG (                   ); # without user data
   my $obj = new Graphics::MNG ( undef             ); # without user data
   my $obj = new Graphics::MNG ( $it               ); # with user data
   my $obj = Graphics::MNG::new(                   ); # with no classname and no data
   my $obj = Graphics::MNG::new('Graphics::MNG'    ); # with classname but no data
   my $obj = Graphics::MNG::new('Graphics::MNG',$it); # with classname and data
   $obj->set_userdata(['user data']);
   my $data = $obj->get_userdata();
   print @$data[0],"\n";
   undef $obj;

   # functional interface
   use Graphics::MNG qw( :fns );
   my $handle = initialize( ['more user data'] );
   die "Can't get an MNG handle" if ( MNG_NULL == $handle );
   my $rv = reset( $handle );
   die "Can't reset the MNG handle" unless ( MNG_NOERROR == $rv );
   my $data = get_userdata( $handle );
   print @$data[0],"\n";
   $rv = cleanup( $handle );
   die "handle not zero" unless ( MNG_NULL == $handle );

}

### here's where it all happens...
examples_testing();
exit(0);



