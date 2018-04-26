requires "Dist::Zilla" => "5.045";
requires "Dist::Zilla::Plugin::MungeFile::WithDataSection";
requires "Dist::Zilla::Plugin::Run::AfterMint";
requires "Dist::Zilla::Plugin::Git::Init";

on 'test' => sub {
    requires 'Test::Most';
    requires 'File::Temp';
    requires 'Cwd';
    requires 'autodie';
    requires 'strictures';
};
