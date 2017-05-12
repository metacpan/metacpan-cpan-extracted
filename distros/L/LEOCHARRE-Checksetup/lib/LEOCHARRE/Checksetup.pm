package LEOCHARRE::Checksetup;
use strict;
use Exporter;
use Carp;
use Test::Simple '';
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK $VERSION);
@ISA = qw/Exporter/;
@EXPORT_OK = qw(bad good ok_app ok_conf ok_mysql_local_server ok_os ok_perldeps ok_root say yn);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;



sub bad;
sub good;
sub say;






sub yn {
        my $question = shift; $question ||='Your answer? ';
        my $val = undef;
        until (defined $val){
                print "$question (y/n): ";
                $val = <STDIN>;
                chomp $val;
                if ($val eq 'y'){ $val = 1; }
                elsif ($val eq 'n'){ $val = 0;}
                else { $val = undef; }
        }
        return $val;
}





sub ok_app {
   my $what = shift;
   ok( _require_app($what), "Found '$what' installed.") or bad;
}

sub _require_app {
   my $app = shift;

   require File::Which;
   File::Which::which($app) and return 1;
   
   print "Sorry, you're missing the application '$app'.\n";

   if ( File::Which::which('yum') ){
   
      yn("It seems that you have 'yum'. Would you like me try to install '$app' via yum?") 
         or say "In that case you should find '$app' and install it.\n"
         and bad;

      ok_root();

      system('yum','-y','install',$app);

      File::Which::which($app) or say "Still can't find path to '$app'. Error.\n"
         and bad;

      return 1;
   }
   bad;
}

#use Smart::Comments '###';
sub _makefile_deps {
   local $/;
   open(FILE,'<','./Makefile.PL') or die($!);
   my $txt = <FILE>;
   close FILE;
   
   $txt=~/PREREQ_PM\s*=>\s*({[^\}]+})/s or return;

   ### $txt
   my $href = eval "$1";

   ### $href
   my @m = keys %$href;
   return @m;

}



sub say { print STDERR "@_" }
sub bad { say("\nCHECK FAILED.\n"); exit 1 }
sub good { say("\nCHECK PASSED.\n"); exit }

# MODULE CHECKS
sub ok_perldeps {
   sub _havemod { my $name = shift; ( eval "require $name;"  )  ? 1 : 0 }


   my @mods = _makefile_deps();
   my @missing;
   MODULE: for my $mod ( @mods ){

      if (_havemod($mod)){
         ok(1,"Have module '$mod'") and next MODULE;
      }



      else {
         push @missing, $mod;
      }

   }

   if (@missing and scalar @missing){
      say("Missing modules:\n");
      say("\t$_\n") for @missing;
      yn("Want me to call cpan to install these?") or bad;

      system("cpan @missing");

      for my $mod (@missing){
         ok( _havemod($mod),"Found module: $mod.") or bad;
      }

   }
         
} # END MODULE CHECKS


sub ok_os {

   ok( $^O=~/linux/, 'using Linux') or bad;

}

sub ok_root {
   my $who = `whoami`;
   ok( $who=~/\broot\b/,'installing as root') or bad();
}


sub ok_conf {
   my $abs = shift;
   defined $abs or croak('missing abs conf arg');
   ok( -e $abs,"have conf file '$abs'") or bad;
}

sub ok_mysql_local_server {

   require File::Which;
   ok( File::Which::which('mysql'),'found mysql cli') or bad;


   my $mysqld  = '/etc/init.d/mysqld';
   if ( -e $mysqld ){
      my $status = `$mysqld status`;
      ok( $status=~/is running/,"$mysqld status, is running") or bad;
   }
   else {
      ok( 1, "no '$mysqld'");
   }


}

1;

__END__

=pod

=head1 NAME

LEOCHARRE::Checksetup

=head1 DESCRIPTION

Linux app setup, ideally for fedora core.

=head1 SUBS

=head2 yn()

Argument is question.
Prompts, returns true or false depending pn user selection.

=head2 ok_root()

Make sure we are root.

=head2 ok_mysql_local_server()

Checks that sql server is running etc.
Also for mysql cli etc.
Only call if local

=head2 ok_os()

Checks that os is linux.

=head2 ok_app()

Argument is cli application, such as 'find' or 'tesseract'
if not found, bad().

=head2 ok_perdeps()

Reads the Makefile.PL and checks that we have each required perl module.

=head2 good()

Exit with success.

=head2 bad()

Exit with fail.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2008 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

