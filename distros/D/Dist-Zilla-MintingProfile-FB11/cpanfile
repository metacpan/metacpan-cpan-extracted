requires "Dist::Zilla" => "5.045";
requires "Dist::Zilla::Plugin::MungeFile::WithDataSection";
requires "Dist::Zilla::Plugin::Run::AfterMint";
requires "Dist::Zilla::Plugin::Git::Init";

# The Makefile won't work if you don't have this
# I'm going to assume you want that.
requires "Dist::Zilla::App::Command::distversion" => '0.03';

on 'test' => sub {
    requires 'Test::Most';
    requires 'File::Temp';
    requires 'Cwd';
    requires 'autodie';
    requires 'strictures';
};
