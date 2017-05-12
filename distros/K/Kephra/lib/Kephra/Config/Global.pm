package Kephra::Config::Global;
our $VERSION = '0.29';

use strict;
use warnings;

# handling main config files under /config/global/
my %settings;
sub settings { \%settings }
sub _settings {
	my $conf = shift;
	%settings = %$conf  if ref $conf eq 'HASH';
	\%settings;
}

sub merge_hash_into_settings {
	my $conf = shift;
	return unless ref $conf eq 'HASH';
	_settings( Kephra::Config::Tree::update(  settings(), $conf ) );
}

sub merge_subfile_into_settings {
	my $file = shift;
	return unless $file;
	$file = Kephra::Config::filepath( _sub_dir(), 'sub', $file );
	return unless -r $file;
	merge_hash_into_settings( Kephra::Config::File::load($file) );
}


sub _sub_dir {'global'}
my ($auto_file, $current_file);
sub current_file{ $current_file = defined $_[0] ? $_[0] : $current_file }
sub auto_file   { $auto_file    = defined $_[0] ? $_[0] : $auto_file }

sub autoload {
	my $autosave = auto_file();
	current_file( $autosave );
	my $backup = $autosave . '~';
	#$main::logger->debug("autoload");

	for my $file ($autosave, $backup) {
		if ( -e $file ) {
			my $config_tree = Kephra::Config::File::load($file);
			%settings = %$config_tree if ref $config_tree eq 'HASH';
			if (exists $settings{about}{version} 
			and $settings{about}{version} ne $Kephra::VERSION){
				rename $file, $file . '.old';
				%settings = %{ Kephra::Config::Tree::update(
					Kephra::Config::Default::global_settings(),
					\%settings,
				) };
				$settings{about}{version} = $Kephra::VERSION;
			}

			last if %settings;
			rename $file, $file . '.failed';
		}
	}

	%settings
		? evaluate()
		: load_defaults();

	Kephra::File::History::init();

	# are settings loaded, hist init will produce one
	keys %settings;
}

sub autosave {
	#$main::logger->debug("save_autosaved");
	my $file_name = auto_file();
	rename $file_name, $file_name . '~';
	Kephra::Config::File::store( $file_name, \%settings  );
}


sub open_current_file {
	save_current();
	Kephra::Config::open_file_absolute( current_file() );
	#Kephra::File::reload_current();
}

sub load_backup_file { reload( auto_file() . '~' ) }

sub load_defaults {
	%settings = %{ Kephra::Config::Default::global_settings() };
	evaluate();
}

sub load_from {
	my $file_name = Kephra::Dialog::get_file_open(
		Kephra::Config::Localisation::strings()->{dialog}{config_file}{load},
		Kephra::Config::dirpath( _sub_dir() ),
		$Kephra::temp{file}{filterstring}{config}
	);
	reload($file_name) if -e $file_name;
	current_file($file_name);
}

sub update {
	Kephra::App::Window::save_positions();
	Kephra::Document::Data::update_attributes();
	Kephra::Edit::Search::save_search_data();
	Kephra::App::EditPanel::Fold::store();
	Kephra::App::Panel::Notepad::save();
	Kephra::App::Panel::Output::save();
}

sub evaluate {
	my $t0 = new Benchmark;
	Kephra::EventTable::del_all();
	Kephra::EventTable::stop_timer();

	my $t1 = new Benchmark;
print "  iface cnfg:", Benchmark::timestr( Benchmark::timediff( $t1, $t0 ) ), "\n"
		if $Kephra::BENCHMARK;

	# set interna to default
	$Kephra::app{GUI}{masterID}     = 20;
	$Kephra::temp{dialog}{control}  = 0;
	Kephra::Document::SyntaxMode::_ID('none');
	Kephra::Edit::Search::_refresh_search_flags();
	# delete unnecessary ecaping of vars
	Kephra::API::settings()->{app}{window}{title}=~ s/\\\$/\$/g;

	my $t2 = new Benchmark;
print "  prep. data:", Benchmark::timestr( Benchmark::timediff( $t2, $t1 ) ), "\n"
		if $Kephra::BENCHMARK;

	# loading interface data (localisation, menus and bar defs)
	Kephra::Config::Interface::load();

	my $t3 = new Benchmark;
print "  create gui:", Benchmark::timestr( Benchmark::timediff( $t3, $t2 ) ), "\n"
		if $Kephra::BENCHMARK;

	# main window components
	Kephra::App::Window::apply_settings();
	Kephra::App::ContextMenu::create_all();
	Kephra::App::MenuBar::create();
	Kephra::App::MainToolBar::show();
	Kephra::App::SearchBar::create();
	Kephra::App::TabBar::apply_settings();
	Kephra::App::StatusBar::create();

	Kephra::App::Panel::Notepad::create();
	Kephra::App::Panel::Output::create();

	Kephra::App::assemble_layout();
	Kephra::Config::Interface::del_temp_data();

	my $t4 = new Benchmark;
print "  apply sets:", Benchmark::timestr( Benchmark::timediff( $t4, $t3 ) ), "\n"
		if $Kephra::BENCHMARK;

	Kephra::App::ContextMenu::connect_all();
	Kephra::App::EditPanel::apply_settings_here();

	Kephra::Config::build_fileendings2syntaxstyle_map();
	Kephra::Config::build_fileendings_filterstring();
	Kephra::EventTable::start_timer();
	#todo:
	#Kephra::EventTable::thaw_all();
	#Kephra::App::clean_acc_table();

	return 1;
}


sub reload {
	my $configfile = shift || current_file();
	if ( -e $configfile ) {
		Kephra::Document::Data::update_attributes();
		my %test_hash = %{ Kephra::Config::File::load($configfile) };
		if (%test_hash) {
			%settings = %test_hash;
			reload_tree();
		} else {
			save();
			Kephra::File::reload_current();
		}
	} else {
		my $err_msg = Kephra::Config::Localisation::strings()->{dialog}{error};
		Kephra::Dialog::warning_box
			($err_msg->{file_find} . "\n $configfile", $err_msg->{config_read} );
	}
}

sub reload_tree {
	update();
	evaluate();
	Kephra::App::TabBar::refresh_all_label();
	Kephra::Document::Data::evaluate_attributes();
}

sub reload_current { reload( current_file() ) }

sub eval_config_file {
	my $file_path   = Kephra::Config::standartize_path_slashes( shift );
	my $config_path = Kephra::Config::dirpath();
	my $l_path = length $config_path;
	if ($config_path eq substr( $file_path, 0, $l_path)){
		$file_path = substr $file_path, $l_path+1;
	}
	my $conf = settings()->{app};
	my $match = \&Kephra::Config::path_matches;

	if ( &$match( $file_path, auto_file(),
	              $conf->{localisation_file}, $conf->{commandlist}{file} )) {
		return reload();
	}
	if ( &$match( $file_path, $conf->{menubar}{file} ) ) {
		return Kephra::App::MenuBar::create() 
	}
	if ( &$match( $file_path, $conf->{toolbar}{main}{file} ) ) {
		return Kephra::App::MainToolBar::create();
	} 
	if ( &$match( $file_path, $conf->{toolbar}{search}{file} ) ) {
		Kephra::App::SearchBar::create();
		Kephra::App::SearchBar::position();
		return;
	}
	# reload template menu wenn template file changed
	if ( &$match($file_path, Kephra::Config::path_from_node($settings{file}{templates})) ){
		return Kephra::Menu::set_absolete('insert_templates');
	}
	reload() if Kephra::Document::Data::get_attribute('config_file');
}

#
sub save {
	my $file_name = shift || current_file();
	update();
	Kephra::Config::File::store( $file_name, \%settings );
}

sub save_as {
	my $file_name = Kephra::Dialog::get_file_save(
		Kephra::Config::Localisation::strings()->{dialog}{config_file}{save},
		Kephra::Config::dirpath( _sub_dir() ),
		$Kephra::temp{file}{filterstring}{config}
	);
	save($file_name) if ( length($file_name) > 0 );
}

sub save_current { save( current_file() ) }
#
sub merge_with {
	my $filename = Kephra::Dialog::get_file_open( 
		Kephra::Config::Localisation::strings()->{dialog}{config_file}{load},
		Kephra::Config::dirpath( _sub_dir(), 'sub'),
		$Kephra::temp{file}{filterstring}{config}
	);
	load_subconfig($filename);
}

#
sub load_subconfig {
	my $file = shift;
	if ( -e $file ) {
		merge_hash_into_settings( Kephra::Config::File::load($file) );
		reload_tree();
	}
}

sub open_templates_file {
	my $config = $settings{file}{templates}; 
	Kephra::Config::open_file( $config->{directory}, $config->{file} );
}

1;

__END__

=head1 NAME

Kephra::Config::Global - loading and storing the config settings for the app

=head1 DESCRIPTION

=cut
