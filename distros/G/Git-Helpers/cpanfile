requires "Browser::Open" => "0";
requires "Carp" => "0";
requires "File::pushd" => "0";
requires "Getopt::Long" => "0";
requires "Git::Sub" => "0";
requires "MetaCPAN::Client" => "0";
requires "Moo" => "0";
requires "Sub::Exporter" => "0";
requires "Try::Tiny" => "0";
requires "Types::Standard" => "0";
requires "URI" => "0";
requires "URI::FromHash" => "0";
requires "URI::Heuristic" => "0";
requires "URI::git" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "File::Touch" => "0";
  requires "Git::Version" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::Git" => "1.313";
  requires "Test::More" => "0";
  requires "Test::Requires::Git" => "1.005";
  requires "Test::RequiresInternet" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.88";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
};
