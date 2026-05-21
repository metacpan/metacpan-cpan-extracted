# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'Carp';
requires 'I18N::LangTags::Detect';
requires 'Lingua::EN::ABC';
requires 'Params::Get';
requires 'Params::Validate::Strict';
requires 'Readonly';
requires 'Return::Set';
requires 'strict';
requires 'warnings';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird', '0.10';
	requires 'Test::Most';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
