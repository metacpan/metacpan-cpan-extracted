{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	sub probed_info {
		my($self) = @_;
		my $feat_file = $self->localize_file_path("lib/Hash/features");
		my $probe_file = $self->localize_file_path(
				"lib/Hash/features.probe");
		unless($self->up_to_date($probe_file, $feat_file)) {
			require IO::File;
			require Data::Dumper;
			my $probe = do($probe_file) or
				die $@ || "can't read $probe_file: $!";
			my $feat_defs = $probe->($self);
			$self->add_to_cleanup($feat_file);
			my $feat_fh = IO::File->new($feat_file, "w")
				or die "can't write $feat_file: $!";
			local $Data::Dumper::Terse = 1;
			$feat_fh->printflush(Data::Dumper::Dumper($feat_defs))
				or die "can't write $feat_file: $!";
		}
		my $probed_info = do($feat_file) or
			die $@ || "can't read $feat_file: $!";
		return ($probed_info, $feat_file);
	}
	sub compile_c {
		my($self, $file, %args) = @_;
		my $cc0_h =
			$self->localize_file_path("lib/Hash/callchecker0.h");
		unless(-f $cc0_h) {
			my $content = eval {
				local $SIG{__DIE__};
				require Devel::CallChecker;
				Devel::CallChecker->VERSION(0.003);
				&Devel::CallChecker::callchecker0_h();
			} || "";
			$self->add_to_cleanup($cc0_h);
			require IO::File;
			my $fh = IO::File->new($cc0_h, "w") or die $!;
			$fh->printflush($content) or die $!;
			$fh->close or die $!;
		}
		unless($args{no_feature_defs}) {
			my($probed, $probed_file) = $self->probed_info;
			$args{defines} = {
				%{$args{defines} || {}},
				%{$probed->{defs}},
				QWITH_TALLY => 1,
			};
			$obj_file = $self->cbuilder->object_file($file);
			unless($self->up_to_date($probed_file, $obj_file)) {
				unlink $obj_file;
			}
		}
		return $self->SUPER::compile_c($file, %args);
	}
	sub link_c {
		no strict "refs";
		my($self, $spec) = @_;
		my($probed, $probed_file) = $self->probed_info;
		unless($self->up_to_date($probed_file, $spec->{lib_file})) {
			unlink $spec->{lib_file};
		}
		my $cb = $self->cbuilder;
		my $cbclass = ref($cb);
		my $orig_cb_link = $cb->can("link");
		local *{"${cbclass}::link"} = sub {
			my($self, %args) = @_;
			if($args{module_name} eq "Hash::SharedMem") {
				my $cc_linkables = eval {
				    local $SIG{__DIE__};
				    require Devel::CallChecker;
				    Devel::CallChecker->VERSION(0.003);
				    [&Devel::CallChecker::callchecker_linkable];
				} || [];
				$args{objects} = [
					@{$args{objects}},
					@$cc_linkables,
				];
			}
			$args{extra_linker_flags} = [
				@{$args{extra_linker_flags} || []},
				@{$probed->{libs}},
			];
			@_ = ($self, %args);
			goto &$orig_cb_link;
		};
		$self->SUPER::link_c($spec);
	}
})->new(
	module_name => "Hash::SharedMem",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Data::Dumper" => 0,
		"Errno" => "1.00",
		"ExtUtils::CBuilder" => "0.15",
		"File::Temp" => "0.22",
		"IO::File" => 0,
		"Module::Build" => 0,
		"POSIX" => 0,
		"Scalar::String" => 0,
		"Test::Builder" => "0.03",
		"Test::More" => "0.40",
		"if" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"utf8" => 0,
		"warnings" => 0,
	},
	build_recommends => {
		"Devel::CallChecker" => "0.003",
	},
	requires => {
		"Exporter" => 0,
		"XSLoader" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	recommends => {
		"Devel::CallChecker" => "0.003",
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
