# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.10.0';

requires 'Exporter';
requires 'HTML::Entities';
requires 'Params::Get', '0.13';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Glob';
	requires 'File::Slurp';
	requires 'File::stat';
	requires 'IPC::System::Simple';
	requires 'POSIX';
	requires 'Readonly';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns';
	requires 'Time::HiRes';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
