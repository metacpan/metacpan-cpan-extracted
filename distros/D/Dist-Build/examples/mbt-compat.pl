use 5.014;
use warnings;

create_subst(
	on => create_pattern(dir => 'lib', file => '*.PL'),
	subst => sub {
		my ($source) = @_;
		my $target = $source =~ s/\.PL\z//r;
		create_node(
			target       => $target,
			dependencies => [ $source ],
			actions      => [
				command(perl_path(), $source, $target),
			],
		);
	},
);

load_extension('Dist::Build::ShareDir');
dist_sharedir('share') if -d 'share';
if (-d 'module-share') {
	opendir my $dh, 'module-share';
	for my $name (grep !/^\./, readdir $dh) {
		my $dir_name = "module-share/$name";
		module_sharedir($dir_name, $name =~ s/-/::/gr) if -d $dir_name;
	}
}

load_extension('Dist::Build::XS');
auto_xs();
