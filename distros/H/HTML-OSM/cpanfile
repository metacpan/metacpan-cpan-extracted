# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'B';
requires 'CHI';
requires 'Carp';
requires 'IPC::System::Simple';   # autodie qw(:all) loads it at import time
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'Object::Configure', '0.15';
requires 'POSIX';
requires 'Params::Get', '0.13';
requires 'Params::Validate::Strict', '0.28';
requires 'Readonly';
requires 'Scalar::Util';
requires 'Time::HiRes';
requires 'URI::Escape';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'File::Temp';
	requires 'HTTP::Response';
	requires 'Test::Compile';
	requires 'Test::DescribeMe';
	requires 'Test::HTTPStatus';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::RequiresInternet';
	requires 'Test::Returns';
	requires 'Test::Which';
	requires 'Test::Without::Module';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
