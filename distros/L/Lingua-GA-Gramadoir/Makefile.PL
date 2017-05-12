use warnings;
use strict;
use 5.008;
use ExtUtils::MakeMaker;

if( build_hashes() ) {
	WriteMakefile(
  	  NAME              => 'Lingua::GA::Gramadoir',
  	  VERSION_FROM      => 'lib/Lingua/GA/Gramadoir.pm',
	  EXE_FILES         => ['scripts/gram-ga.pl',
	  			'scripts/groo-ga.pl'],
  	  PREREQ_PM         => { 
	  			'Archive::Zip' => '1.06',
	  			'Carp' => '0',
				'Encode' => '0',
				'ExtUtils::MakeMaker' => '6.03',
	  			'File::Spec' => '0.83',
				'Getopt::Long' => '2.32',
				'Memoize' => '0.52',
	  			'Storable' => '2.04',
	  			'String::Approx' => '3.19',
				'Term::ANSIColor' => '1.05',
	    			},
	  clean		    => { 
	  			FILES => "lib/Lingua/GA/Gramadoir/*.hash"
				},
  	  ($] >= 5.005 ?
   	   (ABSTRACT_FROM  => 'lib/Lingua/GA/Gramadoir.pm',
   	    AUTHOR         => 'Kevin P. Scannell <kscanne@gmail.com>') : ()),
	);
}
else {
	die "Problem creating dictionary hash tables.\n";
}

sub build_hashes {
	use Storable;
	use File::Spec;

	my $dir = File::Spec->catfile( 'lib', 'Lingua', 'GA', 'Gramadoir' );
	my $srcdir = File::Spec->catfile( 'share' );


	my $combofile = File::Spec->catfile( $dir, 'nocombo.hash');
	my $replfile = File::Spec->catfile( $dir, 'eile.hash');
	my $errfile = File::Spec->catfile( $dir, 'earraidi.hash');
	my $posfile = File::Spec->catfile( $dir, 'pos.hash');
	my $gramfile = File::Spec->catfile( $dir, '3grams.hash');
	my $morphfile = File::Spec->catfile( $dir, 'morph.hash');
	my $tokenfile = File::Spec->catfile( $dir, 'token.hash');
	my $messagesfile = File::Spec->catfile( $dir, 'messages.hash');
	my $rawfile;

	for my $i (0 .. 6) {
		my $lexfile = File::Spec->catfile( $dir, "focail$i.hash");
		unless( -f $lexfile ) {
			my %FOCAIL;
	
			$rawfile = File::Spec->catfile( $srcdir, "focail$i.bs");
			open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
			binmode DATABASE, ":utf8";
			{
			local $/ = "\cJ";
			my $grambytes;
			binmode DATABASE, ":bytes";
			chomp(my $currword=<DATABASE>);
			binmode DATABASE, ":utf8";
			chomp($grambytes = <DATABASE>);
			$FOCAIL{$currword} = $grambytes;
			binmode DATABASE, ":bytes";
			while (<DATABASE>) {
				chomp;
				m/^([0-9]?)(.*)/;
				$currword = substr($currword,0,$1).$2;
				binmode DATABASE, ":utf8";
				chomp ($grambytes = <DATABASE>);
				$FOCAIL{$currword} = $grambytes;
				binmode DATABASE, ":bytes";
			}
			}
			close DATABASE;
			store \%FOCAIL, $lexfile;
		}
	}
	unless ( -f $replfile ) {
		my %EILE;
		$rawfile = File::Spec->catfile( $srcdir, 'eile.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":utf8";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			chomp;
			my ($key, $repl) = m/^([^ ]*) (.*)$/;
			$repl =~ s/ /_/g;
			if (exists($EILE{$key})) {
				$EILE{$key} .= ",_$repl";
			}
			else {
				$EILE{$key} = $repl;
			}
		}
		close DATABASE;
		store \%EILE, $replfile;
	}

	unless ( -f $errfile ) {
		my %EARRAIDI;
		$rawfile = File::Spec->catfile( $srcdir, 'earraidi.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":utf8";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			chomp;
			my ($key, $repl) = m/^([^ ]*) (.*)$/;
			$repl =~ s/ /_/g;
			if (exists($EARRAIDI{$key})) {
				$EARRAIDI{$key} .= ",_$repl";
			}
			else {
				$EARRAIDI{$key} = $repl;
			}
		}
		close DATABASE;
		store \%EARRAIDI, $errfile;
	}

	unless ( -f $posfile ) {
		my %POS;
		$rawfile = File::Spec->catfile( $srcdir, 'pos.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":utf8";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			chomp;
			s/^#.*$//;
			if (/\S/) {
				m/^([0-9]+)\s+(<[^>]+>) *$/;
				$POS{pack('U',$1)} = $2;
			}
		}
		close DATABASE;
		store \%POS, $posfile;
	}

	unless ( -f $tokenfile ) {
		my @TokenRules;
		$rawfile = File::Spec->catfile( $srcdir, 'token.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":utf8";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			chomp;
			s/^#.*$//;
			if (/\S/) {
				/^(.*):(<[^>]+>)$/;
				push @TokenRules, {'patt' => "($1)", 'tag' => $2};
			}
		}
		close DATABASE;
		store \@TokenRules, $tokenfile;
	}

	unless ( -f $morphfile ) {
		my @MorphRules;
		$rawfile = File::Spec->catfile( $srcdir, 'morph.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":utf8";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			s/#.*$//;
			if (/\S/) {
				my ($patt, $repl, $level, $rootpos, $replpos) = /\s*(\S+)\s+(\S+)\s+(\S+)\s+(<[^>]+>)\s+(<[^>]+>)/;
				$repl =~ s/(.*)/"$1"/;
				$repl =~ s/\\l\$([1-9])/".mylcfirst(\$$1)."/g;
				$repl =~ s/\\L\$([1-9])/".mylc(\$$1)."/g;
				$replpos =~ s/"/\\"/g;
				$replpos =~ s/(.*)/"$1"/;
				push @MorphRules, {'patt' => $patt, 'repl' => $repl, 'level' => $level, 'rootpos' => $rootpos, 'replpos' => $replpos};
			}
		}
		close DATABASE;
		store \@MorphRules, $morphfile;
	}

	unless ( -f $gramfile ) {
		my %GRAMS;
		$rawfile = File::Spec->catfile( $srcdir, '3grams.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":utf8";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			chomp;
			m/^([^ ]*) (.*)$/;
			$GRAMS{$1} = $2;
		}
		close DATABASE;
		store \%GRAMS, $gramfile;
	}
	unless ( -f $combofile ) {
		my %COMBO;
		$rawfile = File::Spec->catfile( $srcdir, 'nocombo.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":utf8";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			chomp;
			$COMBO{$_}++;
		}
		close DATABASE;
		store \%COMBO, $combofile;
	}
	unless ( -f $messagesfile ) {
		my %MESSAGES;
		$rawfile = File::Spec->catfile( $srcdir, 'messages.bs');
		open(DATABASE, $rawfile) or die "Can't open dictionary: $!";
		binmode DATABASE, ":bytes";
		binmode DATABASE, ":bytes";
		while (<DATABASE>) {
			chomp;
			if (m/^(\S+)\s+'(.*)' *$/) {
				my $msgid = $2;
				my @macros = split /=/,$1;
				$msgid =~ s/\\'/'/g;
				$MESSAGES{$_} = $msgid foreach (@macros);
			}
		}
		close DATABASE;
		store \%MESSAGES, $messagesfile;
	}
	return ( -f $replfile and -f $combofile and -f $morphfile and
		-f $errfile and -f $posfile and -f $gramfile and
		-f $messagesfile and -f $tokenfile);
}
