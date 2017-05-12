
requires "File::Temp" => "0";
requires "IPC::Open3" => "0";
requires "Gnuplot::Builder" => "0.13";
requires "File::Spec" => "0";

on 'test' => sub {
    requires 'Test::More' => "0";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
