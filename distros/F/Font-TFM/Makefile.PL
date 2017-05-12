
use ExtUtils::MakeMaker;

my $dir = '.';

eval 'use Font::TFM';
if ($@ eq '' and defined $Font::TFM::TEXFONTSDIR) {
	print <<EOF;
	It seems you already have Font::TFM installed -- you might
	want to keep the old value of TEXFONTSDIR.
EOF
	$dir = $Font::TFM::TEXFONTSDIR;
}

$dir = prompt "The search path for tfm files (value of \$Font::TFM::TEXFONTSDIR)\n", $dir;


sub MY::processPL {
	package MY;
	my $inherited = shift->SUPER::processPL(@_);
	$inherited =~ s/(\$\(PERL\) .* TFM.pm.PL)/$1 -dTEXFONTSDIR=$dir/;
	$inherited;
}

sub MY::postamble {
	my $src = MM->catfile('backup', 'TFM.pm.src');
	my $dest = MM->catfile('backup', 'TFM.pm');
qq!$dest : Makefile
	\$\(PERL\) -pe 's/^\\\$\$VERSION = .*/\\\$\$VERSION = \$(VERSION);/' $src > $dest
!
}

WriteMakefile(
	'NAME'	=>	'Font::TFM',
	'VERSION_FROM' =>	'TFM.pm.PL',
	'PL_FILES' =>	{ 'TFM.pm.PL' => 'TFM.pm' },
	'PM' =>		{ 'TFM.pm' => '$(INST_LIBDIR)/TFM.pm' },
	'clean' =>	{ FILES => 'TFM.pm' },
	'dist'	=>	{
			COMPRESS =>	'gzip -9f',
			SUFFIX =>	'.gz',
			DIST_DEFAULT =>	'backup/TFM.pm tardist',
			POSTOP =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
			},
	);


