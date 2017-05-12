use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'MIME::Expander',
    'AUTHOR'        => 'WATANABE Hiroaki <hwat@cpan.org>',
    'LICENSE'       => 'perl',
    'VERSION_FROM'  => 'lib/MIME/Expander.pm', # finds $VERSION
    'PREREQ_PM'     => {
        'Archive::Tar'              => '1.82',
        'Class::Data::Inheritable'  => '0.03',
        'Email::MIME'               => '1.905',
        'Email::MIME::ContentType'  => 0,
        'File::MMagic'              => '1.29',
        'IO::Uncompress::Gunzip'    => '2.048',
        'IO::Uncompress::Bunzip2'   => '2.048',
        'IO::Uncompress::Unzip'     => '2.048',
        'IO::Scalar'                => '2.110',
        'MIME::Type'                => '0.12',
        'MIME::Type::FileName'      => '1.00',
        'Module::Load'              => '0.22',
        'Module::Pluggable'         => 0,
        'parent'                    => 0,
        'Test::More'                => '0.32',
        'Scalar::Util'              => 0,
        },
    );
