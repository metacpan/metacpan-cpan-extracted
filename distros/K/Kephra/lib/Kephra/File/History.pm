package Kephra::File::History;
our $VERSION = '0.06';

use strict;
use warnings;

my @session = ();
my $menu_id = '&file_history';
my $refresh_needed;
my $loaded;
# internal Module API
sub _config { Kephra::API::settings()->{file}{session}{history} }
# external Appwide API
sub init {
	return if scalar @session;
	my $config = Kephra::File::Session::_config();
	return unless defined $config;

	my $subdir = $config->{directory};
	my $file = Kephra::Config::filepath( $subdir, _config()->{file} );
	my $config_tree = Kephra::Config::File::load($file);
	if (ref $config_tree->{document} eq 'ARRAY'){
		@session = @{$config_tree->{document}};
	}
	Kephra::EventTable::add_call ( 'document.close', __PACKAGE__, sub {
		Kephra::File::History::add( Kephra::Document::Data::current_nr() );
	}, __PACKAGE__ );

	$loaded = 1;
}
sub had_init {$loaded}

sub save {
	my $subdir = Kephra::File::Session::_config()->{directory};
	my $file = Kephra::Config::filepath( $subdir, _config()->{file} );
	my $config_tree;
	@{$config_tree->{document}} = @session;
	Kephra::Config::File::store( $file, $config_tree);
}

sub delete_gone {
	my $length = @session;
	my $file = Kephra::Document::Data::get_file_path();
	@session = grep { $_->{file_path} ne $file } @session;
	$refresh_needed = 1 if $length != @session;
}

sub get {
	delete_gone();
	\@session;
}

sub update {
	delete_gone();
	if ($refresh_needed){
		$refresh_needed = 0;
		return 1; 
	}
}

sub add {
	my $doc_nr = Kephra::Document::Data::validate_doc_nr(shift);
	return if $doc_nr < 0;
	my $attr = Kephra::Document::Data::_hash($doc_nr);
	return unless $attr->{'file_name'};
	my %saved_attr;
	$saved_attr{$_} = $attr->{$_} for @{ Kephra::File::Session::_saved_properties() };
	unshift @session, \%saved_attr;
	my $length  = _config->{length} || 0;
	pop @session while @session > $length;
	$refresh_needed = 1;
}

sub open {
	my $hist_nr = shift;
	return if $hist_nr < 0 or $hist_nr > $#session;
	my $doc_nr = Kephra::Document::Data::get_current_nr();
	my $new_nr = Kephra::Document::restore( splice @session, $hist_nr , 1 );
	Kephra::Document::Data::set_current_nr( $doc_nr );
	Kephra::Document::Change::to_number( $new_nr );
	$refresh_needed = 1;
	Kephra::EventTable::trigger('document.list');
}

sub open_all {
	my $new_nr;
	my $doc_nr = Kephra::Document::Data::get_current_nr();
	$new_nr = Kephra::Document::restore( $_ ) for @session;
	Kephra::Document::Data::set_current_nr( $doc_nr );
	Kephra::Document::Change::to_number( $new_nr );
	@session = ();
	$refresh_needed = 1;
	Kephra::EventTable::trigger('document.list');
}

1;
