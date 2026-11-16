# Generated from Makefile.PL using makefilepl2cpanfile

requires 'Carp';
requires 'Exporter';
requires 'List::Util';
requires 'IPC::System::Simple';   # needed by "use autodie qw(:all)"
requires 'Readonly';
requires 'autodie';
recommends 'Sub::Private', '0.09';

on 'test' => sub {
	requires 'Config';
	requires 'Cwd';
	requires 'Encode';
	requires 'Errno';
	requires 'File::Find';
	requires 'File::Path';
	requires 'File::Spec';
	requires 'File::Temp';
	requires 'FindBin';
	requires 'IO::File';
	requires 'JSON::PP';
	requires 'POSIX';
	requires 'Scalar::Util';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::More';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Which';
	requires 'Test::Without::Module';
	requires 'Time::HiRes';
	recommends 'Test::Returns';    # needs Perl 5.26+; t/lib/ReturnsOk.pm falls back without it
	recommends 'IPC::Run';    # extended/fuzz tests only
	recommends 'IPC::Run3';    # extended/fuzz tests only
	recommends 'Test::Mockingbird::TimeTravel';    # extended/fuzz tests only
	recommends 'YAML::XS';    # extended/fuzz tests only
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
