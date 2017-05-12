use 5.006;
use ExtUtils::MakeMaker;

# Thanks to YAML
my @programs = ();
for (split "\n", <<'QUERIES') {
karmaclient|y|Karmasphere command line query client
karmad-exim|y|Karmasphere exim policy daemon
karmad-postfix|y|Karmasphere Postfix policy daemon
karma-publish|y|Karmasphere feed publisher command
QUERIES
	my ($program, $default, $description) = split /\|/, $_;
	if (prompt("Do you want to install '$program', the $description?", 
				$default) =~ /^y/) {
		push(@programs, $program);
	}
}


#my $sa_postamble = "# --- Mail::SpamAssassin is not installed; skipping init-ks.pre and local-ks.cf\n";
#if (not require Mail::SpamAssassin) {
#   print STDERR "Unable to require Mail::SpamAssassin::Plugin; concluding that SpamAsassin is not installed!\n";
#}
#else {
#	my $sa = new Mail::SpamAssassin;
#	my   $def_rules_dir = $sa->{  DEF_RULES_DIR};
#	my $local_rules_dir = $sa->{LOCAL_RULES_DIR};
#
#	# we want to place
#	# an init.pre file into /etc/mail/spamassassin
#	# a 26_karmasphere.cf file into /usr/share/spamasssassin
#
#	# how do we figure out where those files are?
#    # mengwong@newyears:~% perl -MMail::SpamAssassin -MYAML -le 'print Dump new Mail::SpamAssassin' | head -4
#    # --- &1 !!perl/hash:Mail::SpamAssassin
#    # DEF_RULES_DIR: /usr/local/share/spamassassin
#    # LOCAL_RULES_DIR: /etc/mail/spamassassin
#
#	$sa_postamble = <<EOPOSTAMBLE; "# --- Mail::SpamAssassin is not installed; skipping init-ks.pre and local-ks.cf\n";
#
#$sa_postamble
#conf__install:
#	-$(MKPATH) $(B_CONFDIR)
#	$(PERL) -MFile::Copy -e "copy(q{rules/local.cf}, q{$(B_CONFDIR)/local.cf}) unless -f q{$(B_CONFDIR)/local.cf}"
#	$(PERL) -MFile::Copy -e "copy(q{rules/init.pre}, q{$(B_CONFDIR)/init.pre}) unless -f q{$(B_CONFDIR)/init.pre}"
#	$(PERL) -MFile::Copy -e "copy(q{rules/v310.pre}, q{$(B_CONFDIR)/v310.pre}) unless -f q{$(B_CONFDIR)/v310.pre}"
#
#
#}


WriteMakefile(
	'NAME'		=> 'Mail::Karmasphere::Client',
	'VERSION_FROM'	=> 'lib/Mail/Karmasphere/Client.pm',
	'PREREQ_PM'		=> {
				'Convert::Bencode'	=> 0,
				'IO::Socket'		=> 0,
				'IO::Select'		=> 0,
				'Time::HiRes'		=> 0,
				'Text::CSV'			=> 0,
				'LWP'				=> 0,
				'HTTP::Request'		=> 0,
				'YAML'				=> 0,
				'Lingua::EN::Inflect' => 0,
				'Unix::Syslog'      => 0,
			},
	ABSTRACT_FROM => 'lib/Mail/Karmasphere/Client.pm',
	AUTHOR		=> 'Shevek <cpan@anarres.org>',
	EXE_FILES	=> \@programs,
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux readme

aux : readme

readme : lib/Mail/Karmasphere/Client.pm
	perldoc -t lib/Mail/Karmasphere/Client.pm > README

EON
	return $old . $new;
}
