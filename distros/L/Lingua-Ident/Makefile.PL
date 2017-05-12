use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Lingua::Ident',
    'AUTHOR'        => 'Michael Piotrowski <mxp@dynalabs.de>',
    'VERSION_FROM'  => 'Ident.pm',
    'ABSTRACT_FROM' => 'Ident.pm',
    'LICENSE'       => 'perl',
    'EXE_FILES'     => ['trainlid'],
    'clean'         => {FILES    => 'data/data.*'},
    'dist'          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);

package MY;

sub postamble
{
   '
DATA ::
	$(PERL) trainlid -s de.iso-8859-1 < data/sample.de > data/data.de
	$(PERL) trainlid -s de.utf-8      < data/sample.de.utf-8 > data/data.de.utf-8
	$(PERL) trainlid -s en.iso-8859-1 < data/sample.en > data/data.en
	$(PERL) trainlid -s fr.iso-8859-1 < data/sample.fr > data/data.fr
	$(PERL) trainlid -s it.iso-8859-1 < data/sample.it > data/data.it
	$(PERL) trainlid -s ko.eucKR      < data/sample.ko > data/data.ko
	$(PERL) trainlid -s ko.utf-8      < data/sample.ko.utf-8 > data/data.ko.utf-8
	$(PERL) trainlid -s zh.big5       < data/sample.zh > data/data.zh
';
}

sub test
{
   my $self = shift;
   my $make = $self->SUPER::test(@_);

   # add dependencies for test targets
   $make =~ s/(test ::)(.*)/$1 DATA $2/g;

   return $make;
}

