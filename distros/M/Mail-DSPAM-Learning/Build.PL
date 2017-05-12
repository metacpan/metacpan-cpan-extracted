use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Mail::DSPAM::Learning',
     dist_version_from => 'lib/Mail/DSPAM/Learning.pm',
     license => 'gpl',
     requires => {'perl' => '5.8.8',
		  Mail::MboxParser => 0,
		  Mail::Builder => 0,
		  Email::Send => 0,
		  Mail::Box::Manager => 0,
		  Term::ReadKey => 0,
		  File::Basename => 0,
		  File::Path => 0,
		  Net::DNS => 0,
		  Sys::HostIP => 0,
		  Module::TestConfig => 0,
		  Getopt::Long => 0,
		  Pod::Usage => 0,
	      },
    build_requires => {
        "Module::Build"     => 0.28,
	'Test::More' => 0.62
    },
     );

my $default_personal_dir = $build->prompt("Default directory for personal configuration", "$ENV{HOME}/.dspam-learning");
print "default_personal_dir: $default_personal_dir\n";

my $default_mailbox = $build->prompt("Default mailbox containing the SPAMS", "$ENV{HOME}/Mail/SPAMMailbox");
print "Default mailbox: $default_mailbox\n";

&set_local_vars($default_personal_dir, $default_mailbox);

$build->create_build_script;

sub set_local_vars {
    my ($personal_dir, $mailbox) = @_;

    my $line;

    warn "Setting local paths in dspam-learn\n";

    open PROG, "bin/dspam-learn" or die "No such file";
    open NEWPROG, ">bin/dspam-learn.new" or die "No such file";

    while($line = <PROG>) {
	if ($line =~ /^my \$MyConfigDir/) {
	    $line = 'my $MyConfigDir = ' . "\"$personal_dir\";\n";
	}
	if ($line =~ /^my \$spam_mailbox/) {
	    $line = 'my $spam_mailbox = ' . "\"$mailbox\";\n";
	}
	print NEWPROG $line;
    }

    close PROG;
    close NEWPROG;
    rename "bin/dspam-learn", "bin/dspam-learn.old";
    rename "bin/dspam-learn.new", "bin/dspam-learn";
    warn "done\n";
}
