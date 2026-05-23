# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Carp';
requires 'IPC::System::Simple';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.31';
requires 'Readonly';
requires 'Readonly::Values::Months';
requires 'autodie';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns';
	requires 'Test::Which';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
