requires 'Class::Accessor::Lite';
requires 'Class::Inspector';
requires 'Filesys::Notify::Simple';
requires 'Gearman::Worker';
requires 'Getopt::Long';
requires 'Hash::Rename';
requires 'Module::Load';
requires 'Parallel::Prefork';
requires 'Parallel::Scoreboard';
requires 'Pod::Usage';
requires 'perl', '5.008001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'File::Which';
    requires 'Gearman::Client';
    requires 'Net::EmptyPort';
    requires 'Test::More', '0.98';
    requires 'Test::TCP';
};
