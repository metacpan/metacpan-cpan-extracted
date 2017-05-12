use ExtUtils::MakeMaker;

#print "Hi - to test this module, I will need a valid JID and password\n";
#print "They will be written to t/test_config, feel free to delete this file\n";
#print "once the module has been installed\n\n";

#print "JID (e.g. e.feiss\@jabber.apple.com) : ";
#my $jid = <STDIN>;
#print "Password                            : ";
#my $password = <STDIN>;

#open(FILE,'> t/test_config');
#print FILE $jid,$password;
#close(FILE);

my $module = 'SimpleSend.pm';
WriteMakefile(
              NAME         => 'Jabber::SimpleSend',
              VERSION_FROM => 'lib/Jabber/SimpleSend.pm',
              PREREQ_PM    => {
                               Test::More => 0,
                               Net::Jabber => 0,
                               LWP => 0
                              },
              AUTHOR       => 'Greg McCarroll <greg@mccarroll.org.uk>',
             );

