{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	sub link_c {
		no strict "refs";
		my($self, $spec) = @_;
		my $cb = $self->cbuilder;
		my $cbclass = ref($cb);
		my $orig_cb_prelink = $cb->can("prelink");
		local *{"${cbclass}::prelink"} = sub {
			use strict "refs";
			my($self, %args) = @_;
			if($args{dl_name} eq "Devel::CallChecker") {
				$args{dl_func_list} = [
					@{$args{dl_func_list}||[]},
					("$]" >= 5.013006 ? () : qw(
						xAd8NP3gxZglovQRL5Hn_roc0
						xAd8NP3gxZglovQRL5Hn_eal0
						xAd8NP3gxZglovQRL5Hn_eap0
						xAd8NP3gxZglovQRL5Hn_ean0
						xAd8NP3gxZglovQRL5Hn_gcc0
						xAd8NP3gxZglovQRL5Hn_scc0
					)),
				];
				$args{dl_funcs} ||= {};
				my $pname = $args{dl_name};
				unless(exists $args{dl_funcs}->{$pname}) {
					$args{dl_funcs} = {
						%{$args{dl_funcs}},
						$pname => [],
					};
				}
			}
			@_ = ($self, %args);
			goto &$orig_cb_prelink;
		};
		my($libfile, $impfile);
		if($^O eq "MSWin32") {
			my $dlext = $cb->{config}->{dlext};
			my $libext = $cb->{config}->{lib_ext};
			$libfile = $spec->{lib_file};
			($impfile = $libfile) =~ s/\.\Q$dlext\E\z/$libext/
				or die "can't generate import library name";
			unlink $libfile, $impfile
				unless $self->up_to_date($libfile, $impfile);
		}
		my $orig_cb_flk = $cb->can("format_linker_cmd");
		local *{"${cbclass}::format_linker_cmd"} = sub {
			use strict "refs";
			my($self, %spec) = @_;
			my @cmds = &$orig_cb_flk;
			my $cf = $self->{config};
			my $norm_libfile = $libfile;
			my $norm_impfile = $impfile;
			$self->normalize_filespecs(
				\$norm_libfile, \$norm_impfile);
			push @cmds, [
				$cf->{dlltool} || "dlltool",
				"--def", $spec{def_file},
				"--output-lib", $norm_impfile,
				"--dllname", $spec{basename}.".".$cf->{dlext},
				$spec{output},
			] if $spec{output} eq $norm_libfile;
			return @cmds;
		} if $cb->isa("ExtUtils::CBuilder::Platform::Windows::GCC");
		$self->SUPER::link_c($spec);
		if($^O eq "MSWin32") {
			die "failed to generate import library"
				unless -e $impfile;
			$self->add_to_cleanup($impfile);
		}
	}
})->new(
	module_name => "Devel::CallChecker",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"DynaLoader" => 0,
		"ExtUtils::CBuilder" => "0.15",
		"ExtUtils::ParseXS" => 0,
		"File::Spec" => 0,
		"IO::File" => "1.03",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"DynaLoader" => 0,
		"DynaLoader::Functions" => "0.001",
		"Exporter" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	conflicts => {
		"B::Hooks::OP::Check" => "< 0.19",
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
