#! perl

use strict;
use warnings;

use Test::More;
use ExtUtils::HasCompiler ':all';
use File::Temp 'tempfile';

if (eval { require ExtUtils::CBuilder}) {
	plan tests => 1;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $can_compile = can_compile_loadable_object();
	is($can_compile, have_compiler(ExtUtils::CBuilder->new), 'Have a C compiler if CBuilder agrees') or diag(@warnings);
	note(($can_compile ? 'Can' : "Can't") , ' compile');
}
else {
	plan skip_all => 'Can\'t compare to CBuilder without CBuilder';
}

sub have_compiler {
	my $builder = shift;

	my ($FH, $tmpfile) = tempfile( 'compilet-XXXXX', SUFFIX => '.c');
	binmode $FH;
	print $FH "int boot_compilet() { return 1; }\n";
	close $FH;

	my ($obj_file, $lib_file, @other_files);
	eval {
		local $^W = 0;
		local $builder->{quiet} = 1;
		$obj_file = $builder->compile(source => $tmpfile);
		($lib_file, @other_files) = $builder->link(objects => $obj_file, module_name => 'compilet');
		my $handle = DynaLoader::dl_load_file(File::Spec->rel2abs($lib_file));
		die "Couldn't load result" if not defined $handle;
	};
	my $result = $@ ? () : 1;
	warn $@ if $@;

	foreach (grep defined, $tmpfile, $obj_file, $lib_file, @other_files) {
		1 while unlink;
	}

	return $result;
}

