# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';
requires 'Carp';
requires 'Exporter';
requires 'File::Slurp';
requires 'POSIX';
requires 'Socket';
requires 'Sys::Hostname::FQDN';
requires 'Tie::Hash';

on 'test' => sub {
	requires 'File::Temp';
	requires 'FindBin';
	requires 'Test::More', '0.88';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod', '1.22';
	requires 'Test::Pod::Coverage', '1.08';
};
