{ use 5.006; }
use warnings;
use strict;

use Module::Build;

my $require_xs = "$]" < 5.007002 || ("$]" >= 5.009004 && "$]" < 5.010001);

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	unless(__PACKAGE__->can("have_c_compiler")) {
		*have_c_compiler = sub {
			my $cb = eval { $_[0]->cbuilder };
			return $cb && $cb->have_compiler;
		};
	}
	if($Module::Build::VERSION < 0.33) {
		# Older versions of Module::Build have a bug where if the
		# cbuilder object is used at Build.PL time (which it will
		# be for this distribution due to the logic in
		# ->find_xs_files) then that object can be dumped to the
		# build_params file, and then at Build time it will
		# attempt to use the dumped blessed object without loading
		# the ExtUtils::CBuilder class that is needed to make it
		# work.
		*write_config = sub {
			delete $_[0]->{properties}->{_cbuilder};
			return $_[0]->SUPER::write_config;
		};
	}
	sub find_xs_files {
		my($self) = @_;
		return {} unless $self->have_c_compiler;
		# On MSWin32, the XS version of the workaround can't work
		# properly, because it doesn't have access to the core
		# symbols to let SAVEHINTS() work.
		return {} if "$]" < 5.012 && $^O eq "MSWin32";
		return $self->SUPER::find_xs_files;
	}
	sub compile_c {
		my($self, $file, %args) = @_;
		if("$]" < 5.012) {
			# need PERL_CORE for working SAVEHINTS()
			$args{defines} = { %{$args{defines} || {}},
				PERL_CORE => 1,
			};
		}
		return $self->SUPER::compile_c($file, %args);
	}
})->new(
	module_name => "Lexical::SealRequireHints",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
		($require_xs ? (
			"ExtUtils::CBuilder" => "0.15",
		) : ()),
	},
	configure_recommends => {
		($require_xs ? () : (
			"ExtUtils::CBuilder" => "0.15",
		)),
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => "0.41",
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
		($require_xs ? (
			"ExtUtils::CBuilder" => "0.15",
		) : ()),
	},
	build_recommends => {
		($require_xs ? () : (
			"ExtUtils::CBuilder" => "0.15",
		)),
	},
	requires => {
		"perl" => "5.006",
		($require_xs ? (
			"XSLoader" => 0,
		) : ()),
	},
	recommends => {
		($require_xs ? () : (
			"XSLoader" => 0,
		)),
	},
	conflicts => {
		"B::Hooks::OP::Check" => "< 0.19",
	},
	needs_compiler => 0,
	dynamic_config => 1,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
