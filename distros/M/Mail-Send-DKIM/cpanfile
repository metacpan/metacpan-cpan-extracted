# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.026';

requires 'autodie';
requires 'Carp';
requires 'Errno';
requires 'File::Basename';
requires 'File::Spec';
requires 'FindBin';
requires 'Getopt::Long';
requires 'IO::Compress::Gzip';
requires 'IO::Compress::Zip';
requires 'IO::Uncompress::Gunzip';
requires 'IO::Uncompress::Unzip';
requires 'IPC::System::Simple';   # autodie's :system
requires 'Mail::Address';
requires 'Mail::DKIM';
requires 'Mail::DKIM::Signer';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.43';
requires 'Pod::Usage';
requires 'POSIX';
requires 'Readonly';
requires 'Scalar::Util';
requires 'Sub::Private', '0.09';   # the { mode => 'enforce' } import
requires 'Sub::Protected', '0.03';
requires 'Sys::Hostname';
requires 'Sys::Syslog';
requires 'XML::PP';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'Config';
	requires 'Cwd';
	requires 'File::Copy';
	requires 'File::Find';
	requires 'File::Path';
	requires 'File::Temp';
	requires 'Net::DNS';
	requires 'Pod::Github';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird', '0.14';
	requires 'Test::Most';
	requires 'Test::Needs', '0.002010';
	requires 'Test::Returns', '0.05';
	requires 'Time::HiRes';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
