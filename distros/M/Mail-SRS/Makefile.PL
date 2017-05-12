use 5.006;
use ExtUtils::MakeMaker;

# Thanks to YAML
my @programs = ();
for (split "\n", <<'QUERIES') {
srs|y|SRS command line interface
srsd|y|SRS address translation daemon
srsc|y|SRS daemon commandline client
QUERIES
	my ($program, $default, $description) = split /\|/, $_;
	if (prompt("Do you want to install '$program', the $description?", 
			   $default) =~ /^y/) {
		push(@programs, $program);
	}
}

WriteMakefile(
    'NAME'		=> 'Mail::SRS',
    'VERSION_FROM'	=> 'lib/Mail/SRS.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'Digest::HMAC_SHA1'	=> 1.01,
				'Test::More'		=> 0.40,
				'MLDBM'				=> 2.01,
				'Storable'			=> 2.04,
				'DB_File'			=> 1.806,
				'Fcntl'				=> 0,
				'Carp'				=> 0,
				'Exporter'			=> 0,
				'Getopt::Long'		=> 2.30,
			}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM => 'lib/Mail/SRS.pm', # retrieve abstract from module
	AUTHOR     => 'Shevek <cpan@anarres.org>',
	EXE_FILES	=> \@programs,
	clean		=> { FILES => 'test.db' },
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : teach aux readme

teach : all
	$(PERL) -Mblib eg/teach.pl

aux : readme

readme : lib/Mail/SRS.pm
	perldoc -t lib/Mail/SRS.pm > README

EON
	return $old . $new;
}
