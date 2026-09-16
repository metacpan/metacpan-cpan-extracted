# Generated from Makefile.PL using makefilepl2cpanfile

requires 'JSON::MaybeXS';   # Required for encoding data to JSON
requires 'Object::Configure', '0.24';
requires 'Params::Get';
requires 'Scalar::Util';
recommends 'Test::HTML::T5';
recommends 'Params::Validate::Strict';  # Schema notation used in API SPECIFICATION POD sections

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'IPC::System::Simple';
	requires 'Readonly';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.13';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns';
	requires 'Test::Warnings';
	requires 'Test::Without::Module';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
