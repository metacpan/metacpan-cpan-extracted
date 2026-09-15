# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Carp';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.31';
requires 'Readonly';
requires 'autodie';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'IPC::System::Simple';
	requires 'Log::Abstraction';
	requires 'Scalar::Util';
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::Needs';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
