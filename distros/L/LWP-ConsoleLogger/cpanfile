requires "Class::Method::Modifiers" => "0";
requires "Data::Printer" => "0.36";
requires "DateTime" => "0";
requires "HTML::Restrict" => "0";
requires "HTTP::Body" => "0";
requires "HTTP::CookieMonster" => "0";
requires "JSON::MaybeXS" => "1.003005";
requires "LWP::UserAgent" => "0";
requires "List::AllUtils" => "0";
requires "Log::Dispatch" => "2.56";
requires "Module::Load::Conditional" => "0";
requires "Moo" => "0";
requires "MooX::StrictConstructor" => "0";
requires "Parse::MIME" => "0";
requires "String::Trim" => "0";
requires "Sub::Exporter" => "0";
requires "Term::Size::Any" => "0";
requires "Text::SimpleTable::AutoWidth" => "0.09";
requires "Try::Tiny" => "0";
requires "Types::Common::Numeric" => "0";
requires "Types::Standard" => "0";
requires "URI::Query" => "0";
requires "URI::QueryParam" => "0";
requires "XML::Simple" => "0";
requires "perl" => "5.013010";
requires "strict" => "0";
requires "warnings" => "0";
recommends "HTML::FormatText::Lynx" => "23";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "HTML::FormatText::WithLinks" => "0";
  requires "HTTP::Request" => "0";
  requires "Log::Dispatch::Array" => "0";
  requires "Path::Tiny" => "0";
  requires "Plack::Handler::HTTP::Server::Simple" => "0.016";
  requires "Plack::Test" => "0";
  requires "Plack::Test::Agent" => "0";
  requires "Test::FailWarnings" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::LWP::UserAgent" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "Test::Needs" => "0";
  requires "Test::RequiresInternet" => "0";
  requires "URI::file" => "0";
  requires "WWW::Mechanize" => "0";
  requires "perl" => "5.013010";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.88";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
};
