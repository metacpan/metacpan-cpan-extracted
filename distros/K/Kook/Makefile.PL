use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Kook',
    ABSTRACT          => 'task automation utility like Make, Rake, or Ant',
    AUTHOR            => 'makoto kuwata <kwa(at)kuwata-lab.com>',
    VERSION           => ('$Release: 0.0100 $' =~ /(\d[.\d]+)/ && $1),
    PREREQ_PM         => { 'Oktest' => 0 },
    #PMLIBDIRS         => ['lib'],
    EXE_FILES         => ['bin/plkook', 'bin/kk'],
    LICENSE           => 'MIT-License',
);


## prepend 'Kookbook.pl' to be installed into 'lib/perl5'
sub MY::libscan {
    package MY;
    my ($self, $file) = @_;
    return if $file =~ /Kookbook\.pl/;
    return $self->SUPER::libscan($file);
}
