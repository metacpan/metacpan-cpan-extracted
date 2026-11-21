# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.026';

requires 'Carp';
requires 'Scalar::Util';
requires 'autodie';
requires 'base';
requires 'version';
requires 'Email::Address::XS';
requires 'File::Basename';
requires 'File::HomeDir';
requires 'File::Spec';
requires 'Log::Dispatch';
requires 'Mail::Send::DKIM', '0.004.0';
requires 'Params::Get';
requires 'Params::Validate::Strict';
requires 'Readonly';
requires 'Sub::Private', '0.09';   # 0.09 for the enforce mode
requires 'Sub::Protected';

on 'test' => sub {
	requires 'Config';
	requires 'Errno';
	requires 'File::Path';
	requires 'File::Temp';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::More';
	requires 'Test::Most';
	requires 'Test::Returns';
	recommends 'Test::Pod', '1.00';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
