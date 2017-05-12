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
		my $cp1_h =
			$self->localize_file_path("lib/Memoize/callparser1.h");
		unless(-f $cp1_h) {
			require Devel::CallParser;
			Devel::CallParser->VERSION(0.000);
			my $content = &Devel::CallParser::callparser1_h();
			$self->add_to_cleanup($cp1_h);
			require IO::File;
			my $fh = IO::File->new($cp1_h, "w") or die $!;
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
		my $orig_cb_link = $cb->can("link");
		local *{"${cbclass}::link"} = sub {
			my($self, %args) = @_;
			if($args{module_name} eq "Memoize::Lift") {
				require Devel::CallParser;
				Devel::CallParser->VERSION(0.001);
				$args{objects} = [
				    @{$args{objects}},
				    Devel::CallParser::callparser_linkable(),
				];
			}
			@_ = ($self, %args);
			goto &$orig_cb_link;
		};
		$self->SUPER::link_c($spec);
	}
})->new(
	module_name => "Memoize::Lift",
	dist_version => "0.000",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.013008",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Devel::CallParser" => "0.001",
		"ExtUtils::CBuilder" => "0.15",
		"IO::File" => "1.03",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.013008",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Devel::CallParser" => "0.001",
		"Exporter" => 0,
		"XSLoader" => 0,
		"parent" => 0,
		"perl" => "5.013008",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
