# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Carp';
requires 'HTML::Entities';
requires 'I18N::LangTags::Detect';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Readonly';
requires 'Scalar::Util';
requires 'Sub::Private';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'IPC::System::Simple';
	requires 'Test::Carp';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Returns';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::CPAN::Changes';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
