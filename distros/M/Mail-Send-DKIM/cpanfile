# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.016';

requires 'IO::Compress::Gzip';
requires 'IO::Compress::Zip';
requires 'IO::Uncompress::Gunzip';
requires 'IO::Uncompress::Unzip';
requires 'Mail::DKIM';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Readonly';
requires 'Sys::Syslog';
requires 'XML::PP';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'File::Temp';
	requires 'Net::DNS';
	requires 'Pod::Github';
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Time::HiRes';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
