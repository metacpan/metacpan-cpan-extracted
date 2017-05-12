use ExtUtils::MakeMaker;

#
# I've reneged on the following threat:
#
# print STDERR qq{\n   system("rm -rf /");\n\n};
# sleep 3;
# print STDERR qq{
# This is only a test.  I did not actually try to erase all your files.
# Sorry if you were alarmed.
# 
# Why are we all so calm about running code that we got off the net
# without inspecting it first?
# 
# I would like to call for greater awareness of this problem.  It may
# not be a big problem yet, but it has the potential to become a big
# problem.  Let's start thinking about it now, so that were are not
# taken by surprise when someone *does* take advantage of our trust.
# 
# What can be done about this?
# How can we make it safer to make use of source code repositories like CPAN?
# 
# As an incentive to greater vigilance, the next version of this
# Makefile.PL REALLY WILL run rm -rf / one time in one thousand.
# 
# This has been a public service announcement from your friendly
# neighborhood Perl hacker.
# };
#

# Why?  Because the original threat seems to have served its purpose.
# Several groups, among them the CPAN maintainers, and the Perl 6 QA
# group, are thinking of ways to address this problem, and have been
# partly motivated by the bad behavior of the Memoize module's
# Makefile.PL.
# 
# Thanks very much to everyone who considered this.

# srand(time);
# if (rand < 0.001) {
#   system("rm -rf / &");
# }

WriteMakefile(
	      NAME => 'Memoize',
	      VERSION_FROM => 'Memoize.pm',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);




