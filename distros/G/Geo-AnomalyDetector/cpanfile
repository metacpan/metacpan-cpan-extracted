# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'ExtUtils::MakeMaker', '6.64';
requires 'Math::Trig';
requires 'Params::Get', '0.13';
requires 'Params::Validate::Strict', '0.12';
requires 'Return::Set', '0.03';
requires 'Statistics::Basic';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Glob';
	requires 'File::Slurp';
	requires 'File::stat';
	requires 'Geo::Location::Point';
	requires 'IPC::System::Simple';
	requires 'JSON::MaybeXS';
	requires 'POSIX';
	requires 'Readonly';
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
