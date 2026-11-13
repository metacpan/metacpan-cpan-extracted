# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.10.0';

requires 'CHI';
requires 'Carp';
requires 'JSON::MaybeXS';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Object::Configure';
requires 'Params::Get', '0.13';
requires 'Return::Set';
requires 'Scalar::Util';
requires 'Time::HiRes';
requires 'URI';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'HTTP::Response';
	requires 'parent';
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::RequiresInternet';
	requires 'Test::URI';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::CheckManifest', '0.9';
	requires 'Test::Carp';
	requires 'Test::Distribution';
	requires 'Test::EOF';
	requires 'Test::EOL';
	requires 'Test::Module::Used';
	requires 'Test::Portability::Files';
	requires 'Test::Pod::LinkCheck';
	requires 'Test::Pod::No404s';
	requires 'Test::Pod::Snippets';
	requires 'Test::Pod::Spelling::CommonMistakes';
	requires 'Test::Spelling';
	requires 'Test::Spelling::Comment', '0.002';
	requires 'Test::Strict';
	requires 'Test::Synopsis';
	requires 'Test::Vars';
	requires 'warnings::unused', '0.04';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
