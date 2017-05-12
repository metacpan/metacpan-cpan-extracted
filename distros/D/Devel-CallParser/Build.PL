{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	sub compile_c {
		my($self, $file, %args) = @_;
		my $cc0_h =
			$self->localize_file_path("lib/Devel/callchecker0.h");
		unless(-f $cc0_h) {
			require Devel::CallChecker;
			Devel::CallChecker->VERSION(0.001);
			my $content = &Devel::CallChecker::callchecker0_h();
			$self->add_to_cleanup($cc0_h);
			require IO::File;
			my $fh = IO::File->new($cc0_h, "w") or die $!;
			$fh->printflush($content) or die $!;
			$fh->close or die $!;
		}
		return $self->SUPER::compile_c($file, %args);
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
			if($args{dl_name} eq "Devel::CallParser") {
				$args{dl_func_list} = [
					@{$args{dl_func_list}||[]},
					qw(
						C8K61oRQKxigiqmUlVdk_gcp0
						C8K61oRQKxigiqmUlVdk_scp0
					),
					("$]" < 5.013008 ? () : qw(
						C8K61oRQKxigiqmUlVdk_pac0
						C8K61oRQKxigiqmUlVdk_paz0
						C8K61oRQKxigiqmUlVdk_pau0
						C8K61oRQKxigiqmUlVdk_pal0
						C8K61oRQKxigiqmUlVdk_pab0
						C8K61oRQKxigiqmUlVdk_pap0
						C8K61oRQKxigiqmUlVdk_pan0
						C8K61oRQKxigiqmUlVdk_gcp1
						C8K61oRQKxigiqmUlVdk_scp1
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
		my $orig_cb_link = $cb->can("link");
		local *{"${cbclass}::link"} = sub {
			my($self, %args) = @_;
			if($args{module_name} eq "Devel::CallParser") {
				require Devel::CallChecker;
				Devel::CallChecker->VERSION(0.002);
				$args{objects} = [
				    @{$args{objects}},
				    Devel::CallChecker::callchecker_linkable(),
				];
			}
			@_ = ($self, %args);
			goto &$orig_cb_link;
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
	module_name => "Devel::CallParser",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Devel::CallChecker" => "0.002",
		"DynaLoader" => 0,
		"ExtUtils::CBuilder" => "0.15",
		"ExtUtils::ParseXS" => 0,
		"File::Spec" => 0,
		"IO::File" => "1.03",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Devel::CallChecker" => "0.002",
		"DynaLoader" => 0,
		"DynaLoader::Functions" => "0.001",
		"Exporter" => 0,
		"parent" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	conflicts => {
		"Data::Alias" => "< 1.13",
		"Devel::Declare" => "< 0.006004",
		"indirect" => "< 0.27",
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
