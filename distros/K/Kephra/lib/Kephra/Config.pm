package Kephra::Config;
our $VERSION = '0.35';

use strict;
use warnings;

use Cwd();
use File::Spec ();
#
# Files and Dirs
#
my $dir;
sub _dir { if (defined $_[0]) {$dir = $_[0]} else {$dir} }

# Generate a path to a configuration file
sub filepath { File::Spec->catfile( $dir, @_ ) if $_[0] }
sub existing_filepath {
	my $path = filepath( @_ );
	unless ( -f $path ) {
		warn("The config file '$path' does not exist");
	}
	return $path;
}

sub path_from_node {
	my $node = shift;
	return unless defined $node and ref $node eq 'HASH';
	if (exists $node->{file}){
		if (exists $node->{directory}){
			return filepath($node->{directory}, $node->{file});
		} else {
			return filepath($node->{file});
		}
	} else { warn "Wrong node to build config path from." }
}

sub dirpath { File::Spec->catdir( $dir, @_ ) }
sub existing_dirpath {
	my $path = dirpath( @_ );
	unless ( -d $path ) {
		warn("The config directory '$path' does not exist");
	}
	return $path;
}

sub standartize_path_slashes { File::Spec->canonpath( shift ) }
sub path_matches {
	my $given = shift;
	return unless defined $given and $given and @_;
	for my $path (@_) {
		return 1 if defined $path 
		         and index (standartize_path_slashes($path), $given) > -1;
	}
	return 0;
}

sub open_file          { open_file_absolute( filepath(@_) ) }
sub open_file_absolute {
	Kephra::Document::add( $_[0] );
	Kephra::Document::Data::set_attribute('config_file',1);
	Kephra::App::TabBar::refresh_current_label();
}
#
# Wx GUI Stuff
#
# Create a Wx::Colour from a config string
# Either hex "0066FF" or decimal "0,128,255" is allowed.
sub color {
	my $string = shift;
	return Kephra::App::warn("Color string is not defined") unless defined $string;

	# Handle hex format
	$string = lc $string;
	if ( $string =~ /^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i ) {
		return Wx::Colour->new( hex $1, hex $2, hex $3 );
	}

	# Handle comma-seperated
	if ( $string =~ /^(\d+),(\d+),(\d+)$/ ) {
		return Wx::Colour->new( $1 + 0, $2 + 0, $3 + 0 );
	}

	# Unknown
	die "Unknown color string '$string'";
}

# Create an icon bitmap Wx::Bitmap for a named icon
sub icon_bitmap {
	# Find the path from the name
	my $name = shift;
	unless ( defined $name ) {
		warn "Did not provide an icon name to icon_bitmap";
		return;
	}
	$name .= '.xpm' unless $name =~ /\.xpm$/ ;

	my $path = filepath( Kephra::API::settings()->{app}{iconset_path}, $name );
	return Wx::Bitmap->new(16,16) unless -e $path;

	my $bitmap = Wx::Bitmap->new( $path, &Wx::wxBITMAP_TYPE_ANY );
	unless ( $bitmap ) {
		warn "Failed to create bit map from $path";
		return;
	}
	return $bitmap;
}


sub set_xp_style {
	my $xp_def_file = "$^X.manifest";
	if ( $^O eq 'MSWin32' ) {
		if (    ( Kephra::API::settings()->{app}{xp_style} eq '1' )
			and ( !-r $xp_def_file ) ) {
			Kephra::Config::Default::drop_xp_style_file($xp_def_file);
		}
		if (    ( Kephra::API::settings()->{app}{xp_style} eq '0' )
			and ( -r $xp_def_file ) ) {
			unlink $xp_def_file;
		}
	}
}

#
# misc helper stuff
#
sub build_fileendings2syntaxstyle_map {
	foreach ( keys %{ Kephra::API::settings()->{file}{endings} } ) {
		my $language_id = $_;
		my @fileendings
			= split( /\s+/, Kephra::API::settings()->{file}{endings}{$language_id} );
		foreach ( @fileendings ) {
			$Kephra::temp{file}{end2langmap}{$_} = $language_id;
		}
	}
}

sub build_fileendings_filterstring {
	my $l18n  = Kephra::Config::Localisation::strings()->{dialog};
	my $files = $l18n->{file}{files};
	my $all   = $l18n->{general}{all} . " $files ";
	$all .= $^O =~ /win/i
		? "(*.*)|*.*"
		: "(*)|*";
	my $tfile = $Kephra::temp{file};
	$tfile->{filterstring}{all} = $all;
	my $conf = Kephra::API::settings()->{file};
	foreach ( keys %{$conf->{group}} ) {
		my ( $filter_id, $file_filter ) = ( $_, '' );
		my $filter_name = ucfirst($filter_id);
		my @language_ids = split( /\s+/, $conf->{group}{$filter_id} );
		foreach ( @language_ids ) {
			my @fileendings = split( /\s+/, $conf->{endings}{$_} );
			foreach (@fileendings) { $file_filter .= "*.$_;"; }
		}
		chop($file_filter);
		$tfile->{filterstring}{all} .= "|$filter_name $files ($file_filter)|$file_filter";
	}
	$tfile->{filterstring}{config} = "Config $files (*.conf;*.yaml)|*.conf;*.yaml|$all";
	$tfile->{filterstring}{scite}  = "Scite $files (*.ses)|*.ses|$all";
}

sub _map2hash {
	my ( $style, $types_str ) = @_;
	my $stylemap = {};                        # holds the style map
	my @types = split( /\s+/, $types_str );
	foreach (@types) { $$stylemap{$_} = $style; }
	return ($stylemap);
}

sub _lc_utf {
	my $uc = shift;
	my $lc = "";
	for ( 0 .. length($uc) - 1 ) {
		$lc .= lcfirst( substr( $uc, $_, 1 ) );
	}
	$lc;
}
#pce:dialog::msg_box(undef,$mode,''); #Wx::wxUNICODE()

1;

=head1 NAME

Kephra::Config - low level config stuff and basics

=head1 DESCRIPTION


=cut