use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Email::Folder::Exchange',
    VERSION_FROM      => 'lib/Email/Folder/Exchange.pm', # finds $VERSION
    PREREQ_PM         => {
        'Email::Simple' => 0,
        'Email::Folder' => 0,
        'LWP::UserAgent' => 0,
				'Crypt::SSLeay' => 0,
        'URI' => 0,
				'Authen::NTLM' => 0,
				'SOAP::Lite' => 0,
				'MIME::Base64' => 0,
    }, # e.g., Module::Name => 1.1
    clean => {
        FILES => 'test.config'
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Email/Folder/Exchange.pm', # retrieve abstract from module
       AUTHOR         => 'Warren Smith <wsmith@cpan.org>') : ()),
);


if(open my $config_fh, ">", "test.config") {
    print <<"INFO";
The test suite can attempt to connect to an existing exchange server to ensure
that the code is working properly.  If you are behind a strict firewall or have
no network connectivity, these tests may fail (through no fault of the code).

When 'make test' is run, you will be prompted to enter a valid exchange URL,
username, and password. The indicated mailbox should have at least one message
and one folder inside of it. The subfolder should also have at least one
message in it.

INFO
    my $network_tests = prompt "Do you want to run the live tests [y/N]? ", "N";

    print $config_fh "live_tests ", ( $network_tests =~ /y/i ? 1 : 0), "\n";

}
