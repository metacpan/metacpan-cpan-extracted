# Generated from Makefile.PL using makefilepl2cpanfile

requires 'JSON::MaybeXS';   # Required for encoding data to JSON
requires 'Object::Configure', '0.24';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.39';
requires 'Scalar::Util';
recommends 'Test::HTML::T5';

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
