
requires 'List::Util' => "1.28";
requires 'Scalar::Util' => "0";
requires "overload" => "0";
requires "IPC::Open3" => "0";
requires "POSIX" => "0";
requires "Try::Tiny" => "0";
requires "parent" => "0";
requires "File::Spec" => "0";
requires "Exporter" => "5.57";
requires 'Encode';
requires 'parent';

suggests "Data::Focus" => "0.03";

on 'test' => sub {
    requires 'Test::More' => "0";
    requires 'Test::Identity' => "0";
    requires 'Test::Memory::Cycle' => "0";
    requires 'Test::Fatal';
    requires 'Test::Requires';
    requires 'Scalar::Util';
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};

on 'develop' => sub {
    requires 'File::Temp' => "0";
};
