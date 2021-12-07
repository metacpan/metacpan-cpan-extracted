requires 'perl', '5.030000';
on 'test' => sub {
    requires 'Test::More' => '0.98';
    requires 'Test2::V0';
};
on 'configure' => sub {
    requires 'CPAN::Meta';
    requires 'ExtUtils::Config'  => 0.003;
    requires 'ExtUtils::Helpers' => 0.020;
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths' => 0.002;
    requires 'File::Basename';
    requires 'File::Find';
    requires 'File::Path';
    requires 'File::Spec::Functions';
    requires 'Getopt::Long' => 2.36;
    requires 'JSON::PP'     => 2;
    requires 'HTTP::Tiny';
    requires 'Path::Tiny';
    requires 'Archive::Tar';
    requires 'IO::Uncompress::Unzip';
    requires 'Module::Build::Tiny';
    requires 'Module::Load::Conditional';
};
feature 'object_pad', 'Object::Pad support' => sub {
    requires 'Object::Pad', 0.57;
};
