use ExtUtils::MakeMaker;

#my $OSSPATH = '/opt/oss';

if (defined $OSSPATH) {

    WriteMakefile('NAME'         => 'MIDI::Music',
                  'VERSION_FROM' => 'Music.pm',
                  'LIBS'         => ["-L$OSSPATH -lOSSlib"],
                  'DEFINE'       => '-DOSSLIB',
                  'INC'          => "-I$OSSPATH/include",
                  );

} else {

    WriteMakefile('NAME'         => 'MIDI::Music',
                  'VERSION_FROM' => 'Music.pm',
                  'LIBS'         => [''],
                  'DEFINE'       => '',
                  'INC'          => '',
                  );

}
