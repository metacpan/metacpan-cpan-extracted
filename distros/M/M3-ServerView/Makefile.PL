use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => "M3::ServerView",
    VERSION_FROM        => "lib/M3/ServerView.pm",
    PREREQ_PM           => {
        URI                 => "0",
        HTML::Parser        => "3.28",
        Scalar::Util        => "0",
        Object::Tiny        => "0",
        LWP::UserAgent      => "0",
        HTTP::Request       => "0",
        Time::HiRes         => "0",
        Test::Exception     => "0",
        Time::Local         => "0",
        Test::More          => "0",
    },
    LICENSE             => "perl",
    ABSTRACT_FROM       => "lib/M3/ServerView.pm",
    AUTHOR              => "Martin Wilderoth <marwil\@cpan.org>",
);
