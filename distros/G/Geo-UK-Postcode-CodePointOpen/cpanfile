requires "Geo::Coordinates::OSGB" => "2.12";
requires "Geo::UK::Postcode::Regex";
requires "List::MoreUtils";
requires "Moo";
requires "Path::Tiny" => "0.048";
requires "Text::CSV";
requires "Types::Path::Tiny";
requires "perl" => "5.006";

on 'test' => sub {
    requires "ExtUtils::MakeMaker";
    requires "File::Spec::Functions";
    requires "List::Util";
    requires "Test::More";
    requires "Test::Most";
    requires "strict";
    requires "warnings";
};

on 'test' => sub {
    recommends "CPAN::Meta";
    recommends "CPAN::Meta::Requirements";
};

on 'configure' => sub {
    requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
    requires "Dist::Milla";
    requires "File::Spec";
    requires "File::Temp";
    requires "IO::Handle";
    requires "IPC::Open3";
    requires "Pod::Coverage::TrustPod";
    requires "Test::CPAN::Meta";
    requires "Test::More";
    requires "Test::Pod"           => "1.41";
    requires "Test::Pod::Coverage" => "1.08";
};
