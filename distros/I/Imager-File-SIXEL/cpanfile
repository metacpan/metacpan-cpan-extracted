# Prerequisites of Imager::File::SIXEL, for cpanm --installdeps . and CI.
# Makefile.PL declares the same prerequisites for the CPAN toolchain;
# keep both in step.

requires 'perl', '5.024';
requires 'Imager', '1.013';
requires 'Scalar::Util';
requires 'XSLoader';

on configure => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
	requires 'Imager', '1.013';
};

on test => sub {
	requires 'Test2::V0', '0.000060';
};

on develop => sub {
	requires 'Test::Pod', '1.00';
	requires 'CPAN::Uploader';
	requires 'Pod::Markdown';
};
