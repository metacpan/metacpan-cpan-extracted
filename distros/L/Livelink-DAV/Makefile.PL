use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if(open my $config_fh, ">", "test.config") {

   print <<EOP;

Please Note:

For 'make test' to run properly, you must provide login credentials
for your working Livelink server, and have enough privileges to 
create and delete files in the testdir of your choosing.

I do apologize for the need of interaction for my tests, but livetests
are the only way to make sure that this will work for your environment,
and to do live tests, I'll need to use your credentials to log in.

sleeping for 4 seconds..

EOP

   sleep 4;
   my $network_tests = prompt "Do you want to run the live tests [y/N]? ", "N";
   print $config_fh "live_tests ", ( $network_tests =~ /y/i ? 1 : 0), "\n";
}


WriteMakefile(
    NAME              => 'Livelink::DAV',
    VERSION_FROM      => 'lib/Livelink/DAV.pm', # finds $VERSION
    PREREQ_PM         => {'CopyTree::VendorProof'=>0.0011, 'namespace::autoclean' => 0.13, 'HTTP::DAV' =>0.47, 'Moose' =>2.0602, 'MooseX::NonMoose' =>0.22, 'Data::Dumper' =>2.121, 'Carp' =>1.02 ,'File::Basename'=>2.82, 'Term::ReadKey' =>2.30, 'MIME::Base64'=>3.13}, # e.g., Module::Name => 1.1
    clean => {
        FILES => 'test.config'
    },

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Livelink/DAV.pm', # retrieve abstract from module
       AUTHOR         => 'dbmolester de gmail') : ()),
);

