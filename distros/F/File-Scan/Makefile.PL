use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# Last Modification: Wed May  4 12:45:56 WEST 2005

use strict;

my $debug = 0;
my $bufflen = 1024;
my $min_txt_size = 0;
my $signs = "files/signatures.txt";
my $susp = "files/suspicious.txt";

my @html_scripting = ("HTMLVBS", "HTMLJS");
my $script_lang = {
	'in'  => {
		"HTMLVBS" => "< *script[^>]+language *=[\"' ]*vbscript[\"']*[^>]*\>",
		"HTMLJS"  => "< *script[^>]*(language *=[\"' ]*javascript[\"']*)*[^>]*>",
	},
	'out' => {
		"BAT"     => "Batch",
		"JS"      => "JavaScript",
		"VBS"     => "VBScript",
		"TEST"    => "Test",
	},
	'mix' => {
		"MIXVBS"  => "HTMLVBS/VBS",
	},
};

my $app_signatures = {
	'4d5a'             => { sign     => '\x4d\x5a',
				subtypes => [
					{ type => '4d5a000000',
					  sign => '\x4d\x5a\x00\x00\x00', },
					{ type => '4d5a000001',
					  sign => '\x4d\x5a\x00\x00\x01', },
					{ type => '4d5a000002',
					  sign => '\x4d\x5a\x00\x00\x02', },
					{ type => '4d5a420002',
					  sign => '\x4d\x5a\x42\x00\x02', },
					{ type => '4d5a500002',
					  sign => '\x4d\x5a\x50\x00\x02', },
					{ type => '4d5a900003',
					  sign => '\x4d\x5a\x90\x00\x03', },
					{ type => '4d5a930001',
					  sign => '\x4d\x5a\x93\x00\x01', }, ],
				},
	'4d534654'         => { sign     => '\x4d\x53\x46\x54', },
	'49545346'         => { sign     => '\x49\x54\x53\x46', },
	'd0cf11e0a1b11ae1' => { sign     => '\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1', },
	'474554'           => { sign     => '\x47\x45\x54', },
	'e9'               => { sign     => '\xe9', },
	'7f454c46'         => { sign     => '\x7f\x45\x4c\x46', }
};

my %conversion = ();
my $firstbytes = 32;
my $hash = &load_signatures($signs);
my $linesusp = load_suspicious($susp);
my $code = &get_code($hash);
&make_module($code);

my @ppd;
if ($] >= 5.00503) {
	@ppd = (
		'AUTHOR'   => 'Henrique Dias <hdias@aesbuc.pt>',
		'ABSTRACT' => 'Extension for Scanning files for Viruses',
	);
}

WriteMakefile(
	'NAME'         => 'File::Scan',
	'DISTNAME'     => 'File-Scan',
	'VERSION_FROM' => 'Scan.pm', # finds $VERSION
	'PREREQ_PM'    => {}, # e.g., Module::Name => 1.1
	'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
	@ppd,
);

sub load_suspicious {
	my $file = shift;

	my @all = ();
	my $pattern = '(?<![\\{\\\\])([\\da-f]{2})(?!\\})';
	open(FILE, "<$file") or die("Can't open $file: $!");
	while(<FILE>) {
		next if(/^#/);
		chomp();
		my ($txt, $hex) = split(/::/);
		$hex =~ s/$pattern/\\x$1/og;
		push(@all, "\/$hex\/s");
	}
	close(FILE);
	return(join(" ||\n\t\t\t\t\t\t", @all));
}

sub load_signatures {
	my $file = shift;

	my $pattern = '(?<![\\{\\\\])([\\da-f]{2})(?!\\})';
	my %script = ();
	@script{keys(%{$script_lang->{'in'}})} = ();
	@script{keys(%{$script_lang->{'out'}})} = ();

	my $hash = {};
	open(FILE, "<$file") or die("Can't open $file: $!");
	while(<FILE>) {
		next if(/^#/);
		chomp;
		my @elem = split(/::/);
		scalar(@elem) == 5 or die("Wrong signature: $_");
		$elem[2] =~ s/\@/\\\@/g;
		$elem[3] =~ s/ +//g;
		$elem[3] =~ s/eq/\=\=/ig;
		$elem[3] =~ s/ne/\!\=/ig;
		$elem[3] =~ s/lt/\</ig;
		$elem[3] =~ s/le/\<\=/ig;
		$elem[3] =~ s/gt/\>/ig;
		$elem[3] =~ s/ge/\>\=/ig;
		$elem[3] =~ s/([\=\!\<\>][\=]?\d+)/\$total$1/g;
		$elem[3] =~ s/or/ \|\| /ig;
		$elem[3] =~ s/and/ \&\& /ig;
		if(exists($script{$elem[1]})) {
			my (@tmp) = ($elem[4] =~ /$pattern/og);
			my $len = int(length(join("", @tmp))/2);
			$min_txt_size = $len if($len < $min_txt_size || !$min_txt_size);
		}
		$elem[4] =~ s/$pattern/\\x$1/og;
		$hash->{$elem[1]}->{$elem[3]}->{$elem[2]} = $elem[4];
	}
	close(FILE);
	return($hash);
}

sub make_module {
	my $code = shift;

	open(BASEFILE, "<files/Scan.base") or die("Can't open files/Scan.base: $!");
	open(PMFILE, ">Scan.pm") or die("Can't open Scan.pm: $!");
	while(<BASEFILE>) {
		s/\$min_txt_size/$min_txt_size/;
		print PMFILE $_;
		if(/^__DATA__/) {
			print PMFILE $code;
		}
	}
	close(PMFILE);
	close(BASEFILE);
}

sub get_code {
	my $patterns = shift;

	my $today = &string_date();
	my $code = <<ENDOFCODE1;
# generated in: $today

sub get_app_sign {
	\$_ = pop;
ENDOFCODE1
	my $c = 0;
	for my $key (keys(%{$app_signatures})) {
		$c++;
		$conversion{$key} = $c;
		my $n = length($key)/2;
		$firstbytes = $n if($n > $firstbytes);
		my $sign = $app_signatures->{$key}->{sign};
		if(exists($app_signatures->{$key}->{subtypes})) {
			$code .= "\t/\^$sign/o and \$_[0] = $c;\n";
			my $sc = 0;
			for my $a (@{$app_signatures->{$key}->{subtypes}}) {
				$sc++;
				my $t = $a->{type};
				my $s = $a->{sign};
				$conversion{$t} = $sc;
				$code .= "\t/\^$s/o and return(\$_[1] = $sc);\n";
				my $n = length($t)/2;
				$firstbytes = $n if($n > $firstbytes);
			}
		} else {
			$code .= "\t/\^$sign/o and return(\$_[0] = $c);\n";
		}
	}
	$code .= <<ENDOFCODE2;
	return(0);
}

sub exception {
	\$_ = shift;
	return(/^%PDF-/o ? 1 : 0);
}

sub scan_text {
	my \$self = shift;
	my \$file = shift;

	my (\$buff, \$save, \$virus, \$script) = ("", "", "", "");
	my \$skip = 0;
	my \$size = $bufflen;
ENDOFCODE2

	$code .= ($] < 5.006) ? "\tsysopen(FILE, \$file, 0)" : "\topen(FILE, \"<\", \$file)";
	$code .= " or return(&_set_error(\"Can't open \$file: \$!\"));\n";

	$code .= <<ENDOFCODE3;
	LINE: while(read(FILE, \$buff, \$size)) {
		unless(\$save) {
			last LINE if(\$skip = &exception(\$buff));
			if(exists(\$self->{'callback'})) {
				if(my \$ret = \$self->{'callback'}->(\$file, \$buff) || "") {
					&ret_callback(\$ret);
					\$ret and last LINE;
				}
			}
		}
		study;
		\$_ = (\$save .= \$buff);
		unless(\$script) {
			TEST: {
				local \$_ = lc(\$save);
ENDOFCODE3
	for my $sl (@html_scripting) {
		$code .= "\t\t\t\t/" . $script_lang->{'in'}->{$sl} . "/os and \$script = \"$sl\", last TEST;\n";
	}
	$code .= "\t\t\t}\n\t\t}\n\t\tif(\$script) {\n";
	for my $sl (keys(%{$script_lang->{'in'}})) {
		if(scalar(keys(%{$patterns->{$sl}->{'0'}}))) {
			$code .= "\t\t\tif(\$script eq \"$sl\") {\n";
			while(my($key, $value) = each(%{$patterns->{$sl}->{'0'}})) {
				$code .= "\t\t\t\t/$value/s and \$virus = \"$key\", last LINE;\n";
			}
			$code .= "\t\t\t}\n";
		}
	}
	$code .= <<ENDOFCODE4;
			local \$_ = lc(\$save);
			/<\\/script[^>]*>/s and \$script = "";
		} else {
ENDOFCODE4
	for my $sl (keys(%{$script_lang->{'out'}})) {
		while(my($key, $value) = each(%{$patterns->{$sl}->{'0'}})) {
			$code .= "\t\t\t/$value/s and \$virus = \"$key\", last LINE;\n";
		}
	}
	$code .= "\t\t}\n";
	if(scalar(keys(%{$script_lang->{'mix'}}))) {
		$code .= "\t\tunless(\$script eq \"HTMLJS\") {\n";
		for my $sl (keys(%{$script_lang->{'mix'}})) {
			while(my($key, $value) = each(%{$patterns->{$sl}->{'0'}})) {
				$code .= "\t\t\t/$value/s and \$virus = \"$key\", last LINE;\n";
			}
		}
		$code .= "\t\t}\n";
	}
	$code .= <<ENDOFCODE5;
		\$save = substr(\$buff, (length(\$buff)/2));
	}
	close(FILE);
	&_set_skip(\$skip) if(\$skip);
	return(\$virus);
}

sub scan_binary {
	my \$self = shift;
	my \$file = shift;

	my (\$skip, \$suspicious, \$type, \$subtype, \$total) = (0, 0, 0, 0, 0);
	my (\$virus, \$buff, \$save) = ("", "", "");
	my \$size = $bufflen;
ENDOFCODE5

	$code .= ($] < 5.006) ? "\tsysopen(FILE, \$file, 0)" : "\topen(FILE, \"<\", \$file)";
	$code .= " or return(&_set_error(\"Can't open \$file: \$!\"));\n";

	$code .= <<ENDOFCODE6;
	binmode(FILE);
	LINE: while(read(FILE, \$buff, \$size)) {
		\$total += length(\$buff);
ENDOFCODE6
	$code .= "\t\tprint STDERR \"\$total\\n\";\n" if($debug);

	$code .= <<ENDOFCODE7;
		unless(\$save) {
			my \$begin = substr(\$buff, 0, $firstbytes, "");
			unless(length(\$begin) >= $firstbytes) { \$skip = 3; last LINE; }
			if(exists(\$self->{'callback'})) {
				if(my \$ret = \$self->{'callback'}->(\$file, \$begin) || "") {
					&ret_callback(\$ret);
					\$ret and last LINE;
				}
			}
			&get_app_sign(\$type, \$subtype, \$begin);
			unless(\$type) { \$skip = 1; last LINE; }
		}
		study;
		\$_ = (\$save .= \$buff);
		unless(\$suspicious) {
			local \$_ = lc(\$save);
			\$suspicious = 1 if($linesusp);
		}
ENDOFCODE7
	my $lcode = "";
	for my $key (keys(%{$app_signatures})) {
		my $c = $conversion{$key};
		$lcode .= ($lcode) ? "\t\t} els" : "\t\t";
		$lcode .= "if(\$type == $c) {\n";
		if(exists($app_signatures->{$key}->{subtypes})) {
			my $stcode = "";
			for my $a (@{$app_signatures->{$key}->{subtypes}}) {
				my $st = $a->{type};
				my $c = $conversion{$st};
				$stcode .= ($stcode) ? "\t\t\t} els" : "\t\t\t";
				$stcode .= "if(\$subtype == $c) {\n";
				$stcode .= &subgene($patterns->{$st}, "\t\t\t\t");
			}
			$lcode .= "$stcode\t\t\t\}\n" if($stcode);
		}
		$lcode .= &subgene($patterns->{$key}, "\t\t\t");
	}
	$code .= $lcode;
	$code .= <<ENDOFCODE8;
		}
		\$save = substr(\$buff, (length(\$buff)/2));
	}
	close(FILE);
	&_set_skip(\$skip) if(\$skip);
	\$suspicious = 0 if(\$virus);
	&_set_suspicious(\$suspicious) if(\$suspicious);
	return(\$virus);
}
ENDOFCODE8
	return($code);
}

sub subgene {
	my $pat = shift;
	my $tab = shift;

	my $code = "";
	for my $limit (keys(%{$pat})) {
		my $tabs = $tab;
		if($limit) {
			$code .= $tabs . "if($limit) \{\n";
			$tabs .= "\t";
		}
		while(my($key, $value) = each(%{$pat->{$limit}})) {
			$code .= $tabs . "/$value/s and \$virus = \"$key\", last LINE;\n";
		}
		$code .= "$tab\}\n" if($limit);
	}
	return($code);
}

sub string_date {
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
		$year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}
