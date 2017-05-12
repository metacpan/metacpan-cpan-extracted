use ExtUtils::MakeMaker;
use strict;

# tests demande ?
my $ans = 
  prompt("Do you want make smbclient tests ?\n".
   "(you will be prompted for server / worgroup / share / user / password\n".
   "to make read write access.", "no");
if ($ans =~ /^y(es)?$/i) 
  {
    my $server = prompt("Server ?","localhost");
    my $share = prompt("Share ?","homes");
    my $workgroup = prompt("Workgroup/Domain ?","");
    my $user = prompt("Smb user ?",$ENV{'USER'});
    my $pass = prompt("Smb password ?");
    open(FILE,">.m") || warn "Can't create .m for test: $!\n";
    print FILE $server,"\t",$share,"\t",$workgroup,"\t",$user,"\t",$pass;
    close FILE;
  }


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	=> 'Filesys::SmbClientParser',
   'VERSION_FROM' => 'SmbClientParser.pm', # finds $VERSION
   'PREREQ_PM'	  => { 'Test::Simple' => 0}, # e.g., Module::Name => 1.1
     ($] ge '5.005') ? 
		  (
		   'AUTHOR' => 'Alain BARBET (alian@cpan.org)',
		   'ABSTRACT' => 'Perl client to reach Samba ressources '.
		                 'with smbclient'
		  ) : ()
		 );
