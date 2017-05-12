use lib 'inc';
use Java::JCR::Build;

Java::JCR::Build->new( 
    module_name     => 'Java::JCR',
    requires        => {
        'Inline::Java'   => '0.21',
        'LWP::UserAgent' => 0,
    },
    license         => 'perl',
    create_makefile => 'passthrough',
)->create_build_script;
