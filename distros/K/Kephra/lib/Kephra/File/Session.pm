package Kephra::File::Session;
our $VERSION = '0.17';

use strict;
use warnings;

# intern API
sub _config      { Kephra::API::settings()->{file}{session} }
sub _dialog_l18n { Kephra::Config::Localisation::strings()->{dialog} }
sub _saved_properties {[ qw(
	syntaxmode EOL codepage readonly tab_size tab_use
	cursor_pos edit_pos marked_lines folded_lines
	file_path config_file
)]}

sub _forget_gone_files  {
	my @true_files = ();
	my $node       = shift;
	$node = $$node if ref $node eq 'REF' and ref $$node eq 'ARRAY';
	if ( ref $node eq 'ARRAY' ) {
		my @files = @{$node};
		for ( 0 .. $#files ) {
			if ( defined $files[$_]{file_path} and -e $files[$_]{file_path} ) {
				my %file_properties = %{ $files[$_] };
				push( @true_files, \%file_properties );
			}
		}
	}
	return \@true_files;
}

sub _remember_directory {
	my ( $filename, $dir, @dirs ) = shift;
	if ( length($filename) > 0 ) {
		@dirs = split( /\\/, $filename ) if $filename =~ /\\/ ;
		@dirs = split( /\//, $filename ) if $filename =~ /\// ;
		$dir .= "$dirs[$_]/" for 0 .. $#dirs - 1;
		_config()->{dialog_dir} = $dir if $dir;
	}
}
sub _add {
	my $session_data = shift; # session data
	return unless %$session_data
			and $session_data->{document}
			and $session_data->{document}[0];

	my @load_files = @{Kephra::Config::Tree::_convert_node_2_AoH
			( \$session_data->{document} )};
	@load_files = @{ _forget_gone_files( \@load_files ) };
	my $start_nr    =  Kephra::Document::Data::current_nr();
	my $prev_doc_nr = Kephra::Document::Data::previous_nr();
	my $loaded = Kephra::Document::Data::get_value('loaded');
	Kephra::Document::Data::update_attributes($start_nr);
	$start_nr = $session_data->{current_nr}
		if $session_data->{current_nr}
		and not $loaded and Kephra::App::EditPanel::_ref()->GetText eq '';

	# open remembered files with all properties
	Kephra::Document::restore( $_ ) for @load_files;
	my $buffer = Kephra::Document::Data::get_value('buffer');

	# selecting starting doc nr
	$start_nr = 0 if (not defined $start_nr) or ($start_nr < 0 );
	$start_nr = $buffer - 1 if $start_nr >= $buffer;

	# activate the starting document & some afterwork
	Kephra::Document::Change::to_number($start_nr);
	Kephra::Document::Data::set_previous_nr($prev_doc_nr);
	Kephra::App::Window::refresh_title();
}
#
# extern API
#
sub restore   {
	my $file = shift;
	return unless -e $file;
	Kephra::File::close_all();
	add($file);
}

sub restore_from { # 
	my $file = Kephra::Dialog::get_file_open(
			_dialog_l18n()->{file}{open_session},
			Kephra::Config::filepath( _config->{directory}
		), $Kephra::temp{file}{filterstring}{config}
	);
	restore($file);
}

sub add       {
	my $file = shift;
	my $restore = shift;
	if (-r $file) {
		my $session_def = Kephra::Config::File::load($file);
		if (ref $session_def eq 'HASH'){
			_add($session_def);
		} else {
			Kephra::Dialog::warning_box($file, _dialog_l18n()->{error}{config_parse});
		}
	} else {
		Kephra::Dialog::warning_box($file, _dialog_l18n()->{error}{file_read});
	}
}

sub add_from  {
	my $file = Kephra::Dialog::get_file_open(
		_dialog_l18n()->{file}{add_session},
		Kephra::Config::filepath( _config->{directory} ),
		$Kephra::temp{file}{filterstring}{config}
	);
	add($file);
}

sub save      {
	my $file = shift;
	return unless $file;

	Kephra::Config::Global::update();
	my $doc2vis = \&Kephra::App::TabBar::_doc2vis_pos;
	my $config = _config();
	my %temp_config = %{ Kephra::Config::File::load($file) } if -r $file;
	$temp_config{current_nr} = $doc2vis->(Kephra::Document::Data::current_nr());
	$temp_config{document} = [];
	my @doc_list = @{ Kephra::Document::Data::_attributes() };
	for my $nr (0 .. $#doc_list) {
		my $vis_pos = $doc2vis->($nr);
		$temp_config{document}[$vis_pos]{$_} = $doc_list[$nr]{$_}
			for @{ _saved_properties() };
	}
	@{ $temp_config{document} } = @{ _forget_gone_files( \$temp_config{document} ) };
	Kephra::Config::File::store( $file, \%temp_config );
}

sub save_as   {
	my $file_name = Kephra::Dialog::get_file_save(
		_dialog_l18n()->{file}{save_session},
		Kephra::Config::filepath( _config->{directory} ),
		$Kephra::temp{file}{filterstring}{config}
	);
	if ( length($file_name) > 0 ) {
		save( $file_name, "files" );
		_remember_directory($file_name);
	}
}
# default session handling
sub do_autosave { # answers if autosave is turned on by config settings
	my $config = _config()->{auto}{save};
	return 1 if defined $config and $config and not $config eq 'not';
	return 0;
}
sub autoload {    # restore session that was opened while last app shut down
	if ( do_autosave() ) {
		my $config = _config();
		my $session_file = Kephra::Config::filepath
			( $config->{directory}, $config->{auto}{file} );
		restore($session_file);
	} else { Kephra::Document::reset() }
}
sub autosave {
	my $config = _config();
	my $file = Kephra::Config::filepath($config->{directory}, $config->{auto}{file});
	save( $file ) if do_autosave();
}
# backup session handling
sub load_backup {
	my $config = _config();
	restore( Kephra::Config::filepath( $config->{directory}, $config->{backup} ) );
}

sub save_backup {
	my $config = _config();
	save( Kephra::Config::filepath( $config->{directory}, $config->{backup} ) );
}
# other session formats
sub import_scite {
	my $err_msg = _dialog_l18n()->{error};
	my $file = Kephra::Dialog::get_file_open (
		_dialog_l18n()->{file}{open_session},
		$Kephra::temp{path}{config},
		$Kephra::temp{file}{filterstring}{scite}
	);
	if ( -r $file ) {
		if ( open my $FH, '<', $file ) {
			my @load_files;
			my ( $start_file_nr, $file_nr );
			while (<$FH>) {
				m/<pos=(-?)(\d+)> (.+)/;
				if ( -e $3 ) {
					$start_file_nr = $file_nr if $1;
					$load_files[$file_nr]{cursor_pos} = $2;
					$load_files[$file_nr++]{file_path}    = $3;
				}
			}
			if (@load_files) {
				&Kephra::File::close_all;
				for (@load_files) {
					Kephra::Document::add( ${$_}{file_path} );
					Kephra::Edit::_goto_pos( ${$_}{cursor_pos} );
				}
				Kephra::Document::Change::to_number($start_file_nr);
				$Kephra::document{previous_nr} = $start_file_nr;
			} else {
				Kephra::Dialog::warning_box($file, $err_msg->{config_parse});
			}
		} else {
			Kephra::Dialog::warning_box 
				($err_msg->{file_read}." $file", $err_msg->{file});
		}
	}
}

sub export_scite {
	my $win = Kephra::App::Window::_ref();
	my $file = Kephra::Dialog::get_file_save(
		_dialog_l18n()->{file}{save_session},
		$Kephra::temp{path}{config},
		$Kephra::temp{file}{filterstring}{scite}
	);
	if ( length($file) > 0 ) {
		if ( open my $FH, '>', $file ) {
			my $current = Kephra::Document::Data::current_nr();
			my $output;
			for ( @{ Kephra::Document::Data::all_nr() } ) {
				my %file_attr = %{ Kephra::Document::Data::_hash($_) };
				if ( -e $file_attr{file_path} ) {
					$output .= "<pos=";
					$output .= "-" if $_ == $current;
					$output .= "$file_attr{cursor_pos}> $file_attr{file_path}\n";
				}
			}
			print $FH $output;
		} else {
			my $err_msg = _dialog_l18n()->{error};
			Kephra::Dialog::warning_box
				($err_msg->{file_write}." $file", $err_msg->{file} );
		}
	}
}

1;
