requires "IO::Socket::SSL" => "1.12";
requires "Mail::Box::IMAP4" => "2.079";
requires "Mail::IMAPClient" => "3.02";
requires "Mail::Reporter" => "2.079";
requires "Mail::Transport::IMAP4" => "2.079";
requires "perl" => "5.006";
requires "strict" => "0";
requires "superclass" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0.86";
  requires "File::Spec::Functions" => "0";
  requires "IO::CaptureOutput" => "1.06";
  requires "List::Util" => "0";
  requires "Mail::Box::Manager" => "0";
  requires "Probe::Perl" => "0.01";
  requires "Proc::Background" => "1.08";
  requires "Test::More" => "0.74";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Dist::Zilla" => "5.008";
  requires "Dist::Zilla::PluginBundle::DAGOLDEN" => "0.059";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
