use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME               => 'Firefox::Sync::Client',
    VERSION_FROM       => 'lib/Firefox/Sync/Client.pm', # finds $VERSION
    PREREQ_PM          => {
        'MIME::Base32'         => 0,
        'MIME::Base64'         => 0,
        'Digest::SHA'          => 0,
        'Crypt::Rijndael'      => 0,
        'JSON'                 => 0,
        'LWP::UserAgent'       => 0,
        'LWP::Protocol::https' => 0,
        'Storable'             => 0,
    },
    ($] >= 5.005 ?    # Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'lib/Firefox/Sync/Client.pm', # retrieve abstract from module
         AUTHOR        => 'Robin Schroeder <schrorg@cpan.org>') : ()),
);
