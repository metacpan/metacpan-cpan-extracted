# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'IO::Socket::INET';
requires 'IPC::System::Simple';
requires 'MIME::Base64';
requires 'MIME::QuotedPrint';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.34';
requires 'Readonly::Values::Months';
requires 'Socket';
requires 'Sub::Private', '0.05';
requires 'Sub::Protected', '0.02';
requires 'Time::Piece';
requires 'autodie';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'FindBin';
	requires 'MIME::Base64';
	requires 'MIME::QuotedPrint';
	requires 'POSIX';
	requires 'Scalar::Util';
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
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
