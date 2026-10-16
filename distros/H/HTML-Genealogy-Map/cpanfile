# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Date::Cmp';
requires 'Gedcom';
requires 'HTML::GoogleMaps::V3';
requires 'HTML::OSM';
requires 'Object::Configure', '0.15';
requires 'Params::Get', '0.13';
requires 'Params::Validate::Strict', '0.16';
requires 'Scalar::Util';
requires 'autodie';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'Class::Simple';
	requires 'Data::Random';
	requires 'FindBin';
	requires 'Geo::Coder::Free';
	requires 'Geo::Location::Point';
	requires 'IPC::Run3';
	requires 'IPC::System::Simple';
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Returns';
	requires 'Test::Which';
	requires 'Time::HiRes';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
