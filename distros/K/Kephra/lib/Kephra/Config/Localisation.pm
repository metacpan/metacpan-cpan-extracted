package Kephra::Config::Localisation;
our $VERSION = '0.08';

use strict;
use warnings;

use File::Find();
use YAML::Tiny();

# handling config files under config/localisation
my %strings;
sub _set_strings { %strings = %{$_[0]} if ref $_[0] eq 'HASH' }
sub strings   { \%strings }
sub _config   { Kephra::API::settings()->{app}{localisation} }
sub _sub_dir  { _config->{directory} if _config->{directory} }

my %index;
sub _index    { if (ref $_[0] eq 'HASH') {%index = %{$_[0]}} else { \%index } }
my $language;
sub language  { $language }

sub file     { Kephra::Config::filepath(  _sub_dir(), _config()->{file} ) }
sub set_file_name { file_name($_[0]) if defined $_[0]}
sub file_name {
	if (defined $_[0]) { _config()->{file} = $_[0] } else { _config()->{file} }
}
sub set_lang_by_file { $language = $index{ _config()->{file} }{language} }

#
sub load {
	my $file = file();
	# can only be conf because yaml tine doesnt support utf, 1 activates utf
	my $l = Kephra::Config::File::load_conf( $file, 1 ) if defined $file;
	$l = Kephra::Config::Default::localisation() unless $l and %$l;
	%strings = %$l;
	set_lang_by_file();
}


sub change_to {
	my ($lang_file) = shift;
	return unless $lang_file;
	set_documentation_lang( _index()->{$lang_file}{iso_code} );
	set_file_name( $lang_file );
	Kephra::Config::Global::reload_tree();
}

# open localisation file in the editor
sub open_file {
	my $lang_file = shift;
	$lang_file eq file_name()
		? Kephra::Config::open_file( _sub_dir(), $lang_file )
		: Kephra::Document::add( Kephra::Config::filepath(_sub_dir(), $lang_file) );
}

# create menus for l18n selection nd opening l18n files
sub create_menus {
	my $l18n_index = _index();
	return unless ref $l18n_index eq 'HASH';

	my $l18n = strings()->{commandlist}{help}{config};
	my ($al_cmd,  $fl_cmd) = ('config-app-lang', 'config-file-localisation');
	my ($al_help, $fl_help) = Kephra::CommandList::get_property_list
			('help', $al_cmd, $fl_cmd);
	my (@config_app_lang, @config_localisation);
	for my $lang_file (sort keys %$l18n_index) {
		my $lang_data = $l18n_index->{$lang_file};
		my $lang = ucfirst $lang_data->{language};
		my $lang_code = $lang_data->{iso_code} || '';
		my $al_lang_cmd = "$al_cmd-$lang_code";
		my $fl_lang_cmd = "$fl_cmd-$lang_code";
		Kephra::CommandList::new_cmd( $al_lang_cmd, {
			call  => 'Kephra::Config::Localisation::change_to('."'".$lang_file."')",
			state => 'Kephra::Config::Localisation::file_name() eq '."'".$lang_file."'",
			label => $lang, 
			help  => "$al_help $lang",
		});
		Kephra::CommandList::new_cmd( $fl_lang_cmd, {
			call  => 'Kephra::Config::Localisation::open_file('."'".$lang_file."')",
			label => $lang,
			help  => "$fl_help $lang",
		});
		push @config_app_lang, 'item '.$al_lang_cmd;
		push @config_localisation, 'item '.$fl_lang_cmd;
	}
	Kephra::Menu::create_static('config_localisation',\@config_localisation);
	Kephra::Menu::create_static('config_app_lang',    \@config_app_lang);
}

sub refresh_index {
	my $use_cache = Kephra::Config::Interface::_config()->{cache}{use};
	my $index_file = Kephra::Config::filepath
		(Kephra::Config::Interface::_cache_sub_dir(), 'index_l18n.yml');
	my $l18n_dir = Kephra::Config::dirpath( _sub_dir() );

	my %old_index = %{ YAML::Tiny::LoadFile( $index_file ) } if -e $index_file;
	my %new_index;

	my ($FH, $file_name, $age);
	my $getmetaheader = qr|<about>[\r\n]+(.*)[\r\n]+</about>|s;
	my $lines = qr/[\r\n]+/;
	my $seperatekv = qr/\s*(\S+)\s*=\s*(.+)\s*/;
	#$File::Find::prune = 0;
	File::Find::find( sub {
		return if -d $_; 
		$file_name = $_;
		$age = Kephra::File::IO::get_age($file_name);
		# if file is known and not refreshed just copy loaded <about> data
		if (exists $old_index{$file_name} and $age == $old_index{$file_name}{age}) {
			$new_index{$file_name} = $old_index{$file_name};
			return;
		}
		open $FH, "<", $file_name ; #:encoding(UTF-8)
		binmode($FH, ":raw");       #:crlf
		my ($chunk, $header, %filedata) = ('','');
		 #read just the meta data header
		do {
			return if eof $FH;  # abort because no complete about header found
			read $FH, $chunk, 1000;
			$header .= $chunk;
		} until $header =~ /$getmetaheader/;
		# split to lines, delete spaces and extract keys and valuse
		for (split /$lines/, $1){
			/$seperatekv/;
			$filedata{$1} = $2;
		}
		$filedata{'age'} = $age;
		# filter out local backup files of l18n files  - not save for any file ending
		return if $filedata{language}.'.conf' ne $file_name;
		$new_index{$file_name} = \%filedata
			if defined $filedata{'purpose'}
			and $filedata{'purpose'} eq 'global localisation'
			# if its an stable enduser version the l18n strings has to be updated
			and (not defined $Kephra::PATCHLEVEL or $filedata{'version'} eq $Kephra::VERSION);
	}, $l18n_dir);

	YAML::Tiny::DumpFile($index_file, \%new_index);
	_index(\%new_index);
	\%new_index;
}


sub set_documentation_lang {
	my $lang = shift;
	return until $lang;
	$lang = $lang eq 'de' ? 'deutsch' : 'english';
	Kephra::Config::Global::merge_subfile_into_settings (
		Kephra::Config::filepath('documentation', $lang.'.conf')
	);
}

1;

