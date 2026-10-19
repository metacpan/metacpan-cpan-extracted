# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008003';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # First to understand TEST_REQUIRES
};

on 'test' => sub {
	requires 'Errno';
	requires 'POSIX';
	requires 'Scalar::Util';
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
