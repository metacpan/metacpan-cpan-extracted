# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'IO::Socket::INET';
requires 'MIME::Base64';
requires 'MIME::QuotedPrint';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Params::Validate::Strict';
requires 'Readonly::Values::Months';
requires 'Socket';

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
	requires 'Test::Most';
};
on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
