requires 'Cwd';
requires 'DBIx::Class::Core';
requires 'DBIx::Class::Schema';
requires 'Data::Dumper';
requires 'DateTime';
requires 'HPC::Runner';
requires 'HPC::Runner::Command';
requires 'JSON::XS';
requires 'List::Uniq';
requires 'Log::Log4perl';
requires 'Moose::Role';
requires 'MooseX::App::Command';
requires 'base';
requires 'perl', '5.008005';
requires 'strict';
requires 'utf8';
requires 'warnings';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'File::Path';
    requires 'File::Slurp';
    requires 'File::Spec::Functions';
    requires 'FindBin';
    requires 'HPC::Runner::Command';
    requires 'IPC::Cmd';
    requires 'Slurp';
    requires 'Test::Class::Moose';
    requires 'Test::Class::Moose::Load';
    requires 'Test::Class::Moose::Runner';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Milla', 'v1.0.16';
    requires 'Test::Pod', '1.41';
};
