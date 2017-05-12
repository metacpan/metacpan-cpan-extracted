package t::LoadXS;

use warnings;
use strict;

use DynaLoader ();
use ExtUtils::CBuilder ();
use ExtUtils::ParseXS ();
use File::Spec ();

our @todelete;
END { unlink @todelete; }

sub load_xs($$$) {
	my($basename, $dir, $extralibs) = @_;
	my $xs_file = File::Spec->catdir("t", "$basename.xs");
	my $c_file = File::Spec->catdir("t", "$basename.c");
	ExtUtils::ParseXS::process_file(
		filename => $xs_file,
		output => $c_file,
	);
	push @todelete, $c_file;
	my $cb = ExtUtils::CBuilder->new(quiet => 1);
	my $o_file = $cb->compile(source => $c_file);
	push @todelete, $o_file;
	my($so_file, @so_tmps) = $cb->link(objects => [ $o_file, @$extralibs ],
						module_name => "t::$basename");
	push @todelete, $so_file, @so_tmps;
	my $boot_symbol = "boot_t__$basename";
	@DynaLoader::dl_require_symbols = ($boot_symbol);
	my $so_handle = DynaLoader::dl_load_file($so_file, 0);
	defined $so_handle or die(DynaLoader::dl_error());
	my $boot_func = DynaLoader::dl_find_symbol($so_handle, $boot_symbol);
	defined $boot_func or die "symbol $boot_symbol not found in $so_file";
	my $boot_perlname = "t::${basename}::bootstrap";
	DynaLoader::dl_install_xsub($boot_perlname, $boot_func, $so_file)->();
}

1;
