use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Device::PiGlow',
    VERSION_FROM      => 'lib/Device/PiGlow.pm', 
    PREREQ_PM         => {
                           'Moose' => '2.0402',
                           'Device::SMBus' => '0.35',
                         },
    ABSTRACT  => 'Interface for the PiGlow LED board for the Raspberry PI', 
    AUTHOR         => 'Jonathan Stowe <jns@gellyfish.co.uk>',
    LICENSE	=> 'perl',
     META_MERGE        => {

             "meta-spec" => { version => 2 },

             resources => {

               repository => {
                   type => 'git',
                   url => 'https://github.com/jonathanstowe/Device-PiGlow.git',
                   web => 'https://github.com/jonathanstowe/Device-PiGlow',
               },

             },

           },
);

