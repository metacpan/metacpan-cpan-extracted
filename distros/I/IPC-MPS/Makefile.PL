use 5.008008;
use ExtUtils::MakeMaker;


my @prereq_pm;
foreach (qw(Event EV)) {
	eval "require $_";
	if ($@) {
		my $prompt = prompt("Do you want to install $_?(Y/n)", 'Y');
		if ($prompt =~ m/[yY]/) {
			push @prereq_pm, $_ => 0;
		}
	}
}
my %pm = map { $_ => "\$(INST_LIB)/$_" } ('IPC/MPS.pm', 'IPC/MPS/Event.pm', 'IPC/MPS/EV.pm');


WriteMakefile(
    NAME              => 'IPC::MPS',
	LICENSE           => "perl",
    VERSION_FROM      => 'IPC/MPS.pm', # finds $VERSION
    PREREQ_PM         => { @prereq_pm }, # e.g., Module::Name => 1.1
	PM                => \%pm,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'IPC/MPS.pm', # retrieve abstract from module
       AUTHOR         => 'Nick Kostyria <kni@cpan.org>') : ()),
);
