use ExtUtils::MakeMaker;

WriteMakefile(
   NAME            => 'LEGO::NXT',
   VERSION_FROM    => 'lib/LEGO/NXT.pm',
   PREREQ_PM       => {'Net::Bluetooth'=>0}
);
