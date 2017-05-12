use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => "JSON::RPC::Simple",
    VERSION_FROM      => "lib/JSON/RPC/Simple.pm", # finds $VERSION
    PREREQ_PM         => {
        "LWP::UserAgent"    => 0,
        "JSON"              => 0,
        "HTTP::Response"    => 0,
        "HTTP::Request"     => 0,
        "Test::Exception"   => 0,
        "Scalar::Util"      => 0,
        "URI::Escape"       => 1.31,
    }, 
    ABSTRACT_FROM   => "lib/JSON/RPC/Simple.pm",
    AUTHOR          => "Claes Jakobsson <claesjac\@cpan.org>",
    LICENSE         => "perl",
    EXE_FILES       => [qw(bin/jsonrpc-simple eg/json-rpc-simple.psgi)],
);
