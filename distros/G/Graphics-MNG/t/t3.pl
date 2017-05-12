#!perl 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 396 };
use Graphics::MNG;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Graphics::MNG qw( MNG_OUTOFMEMORY );
ok(1);   # loaded an export-ok constant

sub constants_testing()
{
   use Graphics::MNG qw( :all %EXPORT_TAGS );

   # get a list of things in the 'all' tag of the %EXPORT_TAGS hash,
   # and see what doesn't overlap with anything else...

   foreach my $category ( sort keys %EXPORT_TAGS )
   {
      next if $category =~ /fns$/;
      next if $category eq 'all';
    # print "Processing category $category\n";

      foreach my $item ( @{ %EXPORT_TAGS->{$category} } )
      {
         $item =~ s/^&//;  # this is so very important...

         my $eval = qq( return $item() );
         my $out = eval "$eval";
      #  print "$item => $out\n" if $out;

         if ( $@ )
         {
            if ( $@ =~ /vendor has not defined/i )
            {
               ok( 1, 0, "$item (in $category) not supplied by vendor" );
            }
            elsif ( $@ =~ /not enough arguments/i )
            {
               skip( "$item (in $category) needs args, probably OK",1 );
            }
            elsif ( $@ =~ /syntax error/i )
            {
               ok( 1, 0, "$item (in $category) syntax error" );
            }
            else
            {
               ok( 1, 0, "$item (in $category) unknown error: $@" );
            }
         }
         elsif ( $out =~ /::/ )
         {
            ok( 1, 0, "$item (in $category) isn't a constant" );
         }
         else
         {
         #  print "$item => $out\n" if $item =~ /TEXT/;
            ok( 1, 1, "testing $item (in $category)" );
         }
      }
   }
}

### here's where it all happens...
constants_testing();
exit(0);


