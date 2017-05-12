package Kephra::Menu;
our $VERSION = '0.18';

use strict;
use warnings;

my %menu;
sub _all { \%menu }
sub _ref {
	if    ( is($_[1]) )                { $menu{$_[0]}{ref} = $_[1] }
	elsif ( exists $menu{$_[0]}{ref} ) { $menu{$_[0]}{ref} }
}
sub _data        { $menu{$_[0]} if stored($_[0])  }
sub is           { 1 if ref $_[0] eq 'Wx::Menu'   }
sub stored       { 1 if ref $menu{$_[0]} eq 'HASH'}
sub set_absolete { $menu{$_[0]}{absolete} = 1     }
sub not_absolete { $menu{$_[0]}{absolete} = 0     }
sub is_absolete  { $menu{$_[0]}{absolete}         }
sub set_update   { $menu{$_[0]}{update} =  $_[1] if ref $_[1] eq 'CODE' }
sub get_update   { $menu{$_[0]}{update} }
sub no_update    { delete $menu{$_[0]}{update} if stored($_[0]) }
sub add_onopen_check {
	return until ref $_[2] eq 'CODE';
	$menu{ $_[0] }{onopen}{ $_[1] } = $_[2];
}
sub del_onopen_check {
	return until $_[1];
	delete $menu{$_[0]}{onopen}{$_[1]} if exists $menu{$_[0]}{onopen}{$_[1]};
}


sub ready          { # make menu ready for display
	my $id = shift;
	if ( stored($id) ){
		my $menu = _data($id);
		if ($menu->{absolete} and $menu->{update}) {
			 $menu->{absolete} = 0 if $menu->{update}() }
		if (ref $menu->{onopen} eq 'HASH')
			{ $_->() for values %{$menu->{onopen}} }
		_ref($id);
	}
}


sub create_dynamic { # create on runtime changeable menus
	my ( $menu_id, $menu_name ) = @_ ;

	if ($menu_name eq '&insert_templates') {

		set_absolete($menu_id);
		set_update($menu_id, sub {
			my $cfg = Kephra::API::settings()->{file}{templates}; 
			my $file = Kephra::Config::filepath($cfg->{directory}, $cfg->{file});
			my $tmp = Kephra::Config::File::load( $file );
			my @menu_data;
			if (exists $tmp->{template}){
				$tmp = Kephra::Config::Tree::_convert_node_2_AoH(\$tmp->{template});
				my $untitled = Kephra::Config::Localisation::strings()->{app}{general}{untitled};
				my $filepath = Kephra::Document::Data::get_file_path() || "<$untitled>";
				my $filename = Kephra::Document::Data::file_name() || "<$untitled>";
				my $firstname = Kephra::Document::Data::first_name() || "<$untitled>";
				for my $template ( @{$tmp} ) {
					my %item;
					$item{type} = 'item';
					$item{label}= $template->{name};
					$item{call} = sub {
						my $content = $template->{content};
						$content =~ s/\[\$\$firstname\]/$firstname/g;
						$content =~ s/\[\$\$filename\]/$filename/g;
						$content =~ s/\[\$\$filepath\]/$filepath/g;
						Kephra::Edit::insert_text($content);
					};
					$item{help} = $template->{description};
					push @menu_data, \%item; 
					eval_data($menu_id, \@menu_data);
				}
				return 1;
			}
		});

	} elsif ($menu_name eq '&file_history'){

		set_absolete($menu_id);
		set_update($menu_id, sub {
			my @menu_data = @{assemble_data_from_def
				( ['item file-session-history-open-all', undef] )};
			my $history = Kephra::File::History::get();
			if (ref $history eq 'ARRAY') {
				my $nr = 0;
				for ( @$history ) {
					my $file = $_->{file_path};
					push @menu_data, {
						type => 'item',
						label => ( File::Spec->splitpath( $file ) )[2],
						help => $file,
						call => eval 'sub {Kephra::File::History::open( '.$nr++.' )}',
					};
				}
			}
			eval_data($menu_id, \@menu_data);
			return Kephra::File::History::had_init() ? 1 : 0;
			1; # it was successful
		});

		Kephra::EventTable::add_call (
			'document.list', 'menu_'.$menu_id, sub {
				set_absolete( $menu_id ) if Kephra::File::History::update(); 
			}
		);
	} 
	elsif ($menu_name eq '&document_change') {

		set_update( $menu_id, sub {
			return unless exists $Kephra::temp{document}{buffer};
			my $filenames = Kephra::Document::Data::all_file_names();
			my $pathes = Kephra::Document::Data::all_file_pathes();
			my $untitled = Kephra::Config::Localisation::strings()->{app}{general}{untitled};
			my $space = ' ';
			my @menu_data;
			for my $nr (0 .. @$filenames-1){
				my $item = \%{$menu_data[$nr]};
				$space = '' if $nr == 9;
				$item->{type} = 'radioitem';
				$item->{label} = $filenames->[$nr] 
					? $space.($nr+1)." - $filenames->[$nr] \t - $pathes->[$nr]"
					: $space.($nr+1)." - <$untitled> \t -";
				$item->{call} = eval 'sub {Kephra::Document::Change::to_nr('.$nr.')}';
			}
		});

		#add_onopen_check( $menu_id, 'select', sub {
		#	my $menu = _ref($menu_id);
		#	$menu->FindItemByPosition
		#		( Kephra::Document::Data::current_nr() )->Check(1) if $menu;
		#});
		#Kephra::EventTable::add_call (
		#	'document.list', 'menu_'.$menu_id, sub { set_absolete($menu_id) }
		#);
	}
}


sub create_static  { # create solid, not on runtime changeable menus
	my ($menu_id, $menu_def) = @_;
	return unless ref $menu_def eq 'ARRAY';
	not_absolete($menu_id);
	eval_data($menu_id, assemble_data_from_def($menu_def));
}

sub create_menubar {
	#my $menubar    = Wx::MenuBar->new();
	#my $m18n = Kephra::Config::Localisation::strings()->{app}{menu};
	#my ($pos, $menu_name);
	#for my $menu_def ( @$menubar_def ){
		#for my $menu_id (keys %$menu_def){
			# removing the menu command if there is one
			#$pos = index $menu_id, ' ';
			#if ($pos > -1){
				#if ('menu' eq substr $menu_id, 0, $pos ){
					#$menu_name = substr ($menu_id, $pos+1);
				# ignoring menu structure when command other that menu or blank
				#} else { next }
			#} else { 
				#$menu_name = $menu_id;
			#}
			#$menubar->Append(
				#Kephra::Menu::create_static( $menu_name, $menu_def->{$menu_id}),
				#$m18n->{label}{$menu_name}
			#);
		#}
	#}
}

# create menu data structures (MDS) from menu skeleton definitions (command list)
sub assemble_data_from_def {
	my $menu_def = shift;
	return unless ref $menu_def eq 'ARRAY';

	my $menu_l18n = Kephra::Config::Localisation::strings()->{app}{menu};
	my ($cmd_name, $cmd_data, $type_name, $pos, $sub_id);
	my @mds = (); # menu data structure
	for my $item_def (@$menu_def){
		my %item;
		# creating separator
		if (not defined $item_def){
			$item{type} = ''
		# sorting commented lines out
		} elsif (substr($item_def, -1) eq '#'){
			next;
		# creating separator
		} elsif ($item_def eq '' or $item_def eq 'separator') {
			$item{type} = ''
		# eval a sublist
		} elsif (ref $item_def eq 'HASH'){
			$sub_id = $_ for keys %$item_def;
			$pos = index $sub_id, ' ';
			# make submenu if keyname is without command
			if ($pos == -1){
				$item{type} = 'menu';
				$item{id} = $sub_id;
				$item{label} = $menu_l18n->{label}{$sub_id};
				$item{help} = $menu_l18n->{help}{$sub_id} || '';
				$item{data} = assemble_data_from_def($item_def->{$sub_id}); 
			} else {
				my @id_parts = split / /, $sub_id;
				$item{type} = $id_parts[0];
				# make submenu when finding the menu command
				if ($item{type} eq 'menu'){
					$item{id}   = $id_parts[1];
					$item{label}= $menu_l18n->{label}{$id_parts[1]};
					$item{help} = $menu_l18n->{help}{$id_parts[1]} || '';
					$item{data} = assemble_data_from_def($item_def->{$sub_id}); 
					$item{icon} = $id_parts[2] if $id_parts[2];
				}
			}
		# menu items
		} else {
			$pos = index $item_def, ' ';
			next if $pos == -1;
			$item{type} = substr $item_def, 0, $pos;
			$cmd_name = substr $item_def, $pos+1;
			if ($item{type} eq 'menu'){
				$item{id} = $cmd_name;
				$item{label} = $menu_l18n->{label}{$cmd_name};
			} else {
				$cmd_data = Kephra::CommandList::get_cmd_properties( $cmd_name );
				# skipping when command call is missing
				next unless ref $cmd_data and exists $cmd_data->{call};
				for ('call','enable','state','label','help','icon'){
					$item{$_} = $cmd_data->{$_} if $cmd_data->{$_};
				}
				$item{label} .= "\t  " . $cmd_data->{key} . "`" if $cmd_data->{key};
			}
		}
		push @mds, \%item;
	}
	return \@mds;
}

sub eval_data { # eval menu data structures (MDS) to wxMenus
	my $menu_id = shift;
	return unless defined $menu_id;
	#emty the old or create new menu under the given ID
	my $menu = _ref($menu_id);
	if (defined $menu and $menu) { $menu->Delete( $_ ) for $menu->GetMenuItems } 
	else                         { $menu = Wx::Menu->new() }

	my $menu_data = shift;
	unless (ref $menu_data eq 'ARRAY') {
		_ref($menu_id, $menu); 
		return $menu;
	}

	my $win = Kephra::App::Window::_ref();
	my $kind;
	my $item_id = defined $menu{$menu_id}{item_id}
		? $menu{$menu_id}{item_id}
		: $Kephra::app{GUI}{masterID}++ * 100;
	$menu{$menu_id}{item_id} = $item_id;

	for my $item_data (@$menu_data){
		if (not $item_data->{type} or $item_data->{type} eq 'separator'){
			$menu->AppendSeparator;
		}
		elsif ($item_data->{type} eq 'menu'){
			my $submenu = ref $item_data->{data} eq 'ARRAY'
				? eval_data( $item_data->{id}, $item_data->{data} )
				: ready( $item_data->{id} );
			$item_data->{help} = '' unless defined $item_data->{help};
			my @params = ( $menu, $item_id++, $item_data->{label},$item_data->{help},
				&Wx::wxITEM_NORMAL
			);
			push @params, $submenu if is ($submenu);
			my $menu_item = Wx::MenuItem->new( @params );
			if (defined $item_data->{icon}) {
				my $bmp = Kephra::CommandList::get_cmd_property
					( $item_data->{icon}, 'icon' );
				$menu_item->SetBitmap( $bmp )
					if ref $bmp eq 'Wx::Bitmap' and not Wx::wxMAC();
			}
			#Wx::Event::EVT_MENU_HIGHLIGHT($win, $item_id-1, sub {
			#	Kephra::App::StatusBar::info_msg( $item_data->{help} )
			#});
			$menu->Append($menu_item);
		} 
		else { # create normal items
			if    ($item_data->{type} eq 'checkitem'){$kind = &Wx::wxITEM_CHECK}
			elsif ($item_data->{type} eq 'radioitem'){$kind = &Wx::wxITEM_RADIO}
			elsif ($item_data->{type} eq 'item')     {$kind = &Wx::wxITEM_NORMAL}
			else                                     { next; }

			my $menu_item = Wx::MenuItem->new
				($menu, $item_id, $item_data->{label}||'', '', $kind);
			if ($item_data->{type} eq 'item') {
				if (ref $item_data->{icon} eq 'Wx::Bitmap') {
					$menu_item->SetBitmap( $item_data->{icon} ) unless Wx::wxMAC();
				}
				else {
					# insert fake empty icons
					# $menu_item->SetBitmap($Kephra::temp{icon}{empty}) 
				}
			}

			add_onopen_check( $menu_id, 'enable_'.$item_id, sub {
				$menu_item->Enable( $item_data->{enable}() );
			} ) if ref $item_data->{enable} eq 'CODE';
			add_onopen_check( $menu_id, 'check_'.$item_id, sub {
				$menu_item->Check( $item_data->{state}() )
			} ) if ref $item_data->{state} eq 'CODE';

			Wx::Event::EVT_MENU          ($win, $menu_item, $item_data->{call} );
			Wx::Event::EVT_MENU_HIGHLIGHT($win, $menu_item, sub {
				Kephra::App::StatusBar::info_msg( $item_data->{help} )
			}) if $item_data->{help} ;
			$menu->Append( $menu_item );
			$item_id++; 
		}
	1; # sucess
	}

	Kephra::EventTable::add_call('menu.open', 'menu_'.$menu, sub {ready($menu_id)});
	_ref($menu_id, $menu);
	return $menu;
}

sub destroy {
	my $menu_ID = shift;
	my $menu = _ref( $menu_ID );
	return unless $menu;
	$menu->Destroy;
	Kephra::EventTable::del_own_subscriptions( $menu_ID );
}

1;

