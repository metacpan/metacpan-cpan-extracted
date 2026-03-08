use 5.014;
use warnings;

load_extension('Dist::Build::Core');
script_dir('script');
auto_PL();

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
