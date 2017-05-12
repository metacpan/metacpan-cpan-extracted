package Kephra::App::EditPanel::Margin;
our $VERSION = '0.13';

use strict;
use warnings;

my $mouse_y_pos;
sub _ep_ref {
	Kephra::App::EditPanel::is($_[0]) ? $_[0] : Kephra::App::EditPanel::_ref()   
}
sub _all_ref       { Kephra::Document::Data::get_all_ep() }
sub _edit_config   { Kephra::App::EditPanel::_config() }
sub _config        { _edit_config()->{margin}}
sub _line_config   { _config()->{linenumber}}
sub _fold_config   { _config()->{fold}      }
sub _marker_config { _config()->{marker}    }
sub width {
	my $ep = _ep_ref(shift);
	my $width;
	$width += $ep->GetMarginWidth($_) for 0..2;
	$width
}
sub in_nr {
	my $x = shift;
	my $ep = _ep_ref(shift);
	my $border;
	for my $margin (0..2){
		$border += $ep->GetMarginWidth($margin);
		return $margin if $x <= $border;
	}
	return -1;
}

sub apply_settings_here {# eval view settings for the margin of this edit panel obj
	my $ep = _ep_ref(shift);
	# defining the 3 margins
	$ep->SetMarginType( 0, &Wx::wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginType( 1, &Wx::wxSTC_MARGIN_NUMBER );
	$ep->SetMarginType( 2, &Wx::wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginMask( 0, 0x01FFFFFF );
	$ep->SetMarginMask( 1, 0 );
	$ep->SetMarginMask( 2, &Wx::wxSTC_MASK_FOLDERS );
	$ep->SetMarginSensitive( 0, 1 );
	$ep->SetMarginSensitive( 1, 1 );
	$ep->SetMarginSensitive( 2, 1 );

	# setting folding markers
	my $color     = \&Kephra::Config::color;
	my $f = &$color( _fold_config()->{fore_color} );
	my $b = &$color( _fold_config()->{back_color} );
	if (_fold_config()->{style} eq 'arrows') {
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDER,       &Wx::wxSTC_MARK_ARROW,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEREND,    &Wx::wxSTC_MARK_ARROW,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPEN,   &Wx::wxSTC_MARK_ARROWDOWN,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPENMID,&Wx::wxSTC_MARK_ARROWDOWN,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERMIDTAIL,&Wx::wxSTC_MARK_EMPTY,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERTAIL,   &Wx::wxSTC_MARK_EMPTY,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERSUB,    &Wx::wxSTC_MARK_EMPTY,    $b,$f);
	}
	else {
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDER,       &Wx::wxSTC_MARK_BOXPLUS,  $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEREND,    &Wx::wxSTC_MARK_BOXPLUSCONNECTED,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPEN,   &Wx::wxSTC_MARK_BOXMINUS, $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPENMID,&Wx::wxSTC_MARK_BOXMINUSCONNECTED,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERMIDTAIL,&Wx::wxSTC_MARK_TCORNER,  $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERTAIL,   &Wx::wxSTC_MARK_LCORNER,  $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERSUB,    &Wx::wxSTC_MARK_VLINE,    $b,$f);
	}
	$ep->SetFoldFlags(16) if _fold_config()->{flag_line};

	show_marker_here($ep);
	Kephra::Document::Data::set_attribute('margin_linemax', 0);
	#apply_line_number_width_here($ep);
	apply_line_number_color_here($ep);
	show_fold_here($ep);
	apply_text_width_here($ep);
}
sub refresh_changeable_settings {
	my $ep = _ep_ref(shift);
	apply_line_number_color_here($ep);
	apply_fold_flag_color_here($ep);
}
sub get_contextmenu_visibility    { _edit_config()->{contextmenu}{margin} }
sub switch_contextmenu_visibility { _edit_config()->{contextmenu}{margin} ^= 1 }
#
# deciding what to do when clicked on edit panel margin
#
sub on_left_click {
	my ($ep, $event, $nr) = @_;
	if      ($nr  < 2)  {Kephra::Edit::Marker::toggle_marker_here(@_) }
	elsif   ($nr == 2) {Kephra::App::EditPanel::Fold::toggle_here(@_) }
}
sub on_middle_click {
	my ($ep, $event, $nr) = @_;
	Kephra::Edit::Marker::toggle_bookmark_here(@_)                if $nr <  2;
	Kephra::App::EditPanel::Fold::toggle_recursively($ep, $event) if $nr == 2;
}
sub on_right_click {
	my ($ep, $event, $nr) = @_;
	my ($x, $y) = ($event->GetX, $event->GetY);
	if ($nr > -1 and $nr < 2 and get_contextmenu_visibility() ){
		$mouse_y_pos = $event->GetY;
		$ep->PopupMenu( 
			Kephra::App::ContextMenu::get 
				(_edit_config()->{contextmenu}{ID_margin} ), $x, $y);
		undef $mouse_y_pos;
	}
	elsif ($nr == 2) {
		$event->LeftIsDown
			? Kephra::App::EditPanel::Fold::toggle_all()
			: Kephra::App::EditPanel::Fold::toggle_level($ep, $event);
	}
}

sub clicked_on_line {
	my $event = shift;
	return -1 unless defined $mouse_y_pos or ref $event eq 'Wx::MouseEvent';
	my $ep = _ep_ref();
	my $x = width($ep) + 5;
	# $mouse_y_pos is saved position where context menu poped so we can fold there
	my $y = defined $mouse_y_pos ? $mouse_y_pos : $event->GetY;
	my $max_y = $ep->GetSize->GetHeight;
	my $pos = $ep->PositionFromPointClose($x, $y);
	while ($pos < 0 and $y+10 < $max_y) {
		$pos = $ep->PositionFromPointClose($x, $y += 10);
	}
	return $ep->LineFromPosition($pos);
}
#
# line number margin
#
sub line_number_visible{ _line_config->{visible} }
sub switch_line_number {
	_line_config->{visible} ^= 1;
	apply_line_number_width()
}
sub apply_line_number_width { apply_line_number_width_here($_) for @{_all_ref()} }
sub apply_line_number_width_here {
	my $ep = _ep_ref(shift);
	my $doc_nr = shift;
	$doc_nr = Kephra::Document::Data::nr_from_ep($ep) unless defined $doc_nr;
	my $config = _line_config();
	my $char_width = Kephra::Document::Data::get_attribute('line_nr_margin_width', $doc_nr);
	if (not defined $char_width or not $char_width) {
		$char_width = needed_line_number_width($ep);
		Kephra::Document::Data::set_attribute
			('line_nr_margin_width', $char_width, $doc_nr);
	}
	my $px_width = $config->{visible}
		? $char_width * _edit_config()->{font}{size}
		: 0;
	$ep->SetMarginWidth( 1, $px_width );
	if ($config->{autosize} and $config->{visible}) {
		Kephra::EventTable::add_call ('document.text.change',
			'autosize_line_number', \&line_number_autosize_update);
	} else {
		Kephra::EventTable::del_call
			('document.text.change', 'autosize_line_number');
	}
}
sub set_line_number_width_here {
	my $width = shift;
	my $doc_nr = shift or Kephra::Document::Data::current_nr();
	my $config = _line_config();
	Kephra::Document::Data::set_attribute('line_nr_margin_width', $width, $doc_nr);
	Kephra::Document::Data::set_attribute('margin_linemax', 10 ** $width - 1, $doc_nr);
	apply_line_number_width_here( Kephra::Document::Data::_ep($doc_nr) );
}
sub needed_line_number_width { 
	my $width = length _ep_ref(shift)->GetLineCount;
	my $min = _line_config()->{min_width};
	$width = $min if defined $min and $min and $min > $width;
	return $width;
}
sub autosize_line_number {
	my $ep = _ep_ref(shift);
	my $doc_nr = shift;
	$doc_nr = Kephra::Document::Data::nr_from_ep($ep) unless defined $doc_nr;
	my $config = _line_config();
	return unless _line_config()->{autosize};
	my $need = needed_line_number_width($ep);
	my $is = Kephra::Document::Data::get_attribute('line_nr_margin_width', $doc_nr);
	set_line_number_width_here($need, $doc_nr) if not defined $is or $need > $is;
}

sub line_number_autosize_update {
	my $line_max = Kephra::Document::Data::get_attribute('margin_linemax');
	my $ep = _ep_ref();
	autosize_line_number($ep) if $ep->GetLineCount > $line_max;
}

sub apply_line_number_color { apply_line_number_color_here($_) for @{_all_ref()} }
sub apply_line_number_color_here {
	my $ep     = _ep_ref(shift);
	my $config = _line_config();
	my $color  = \&Kephra::Config::color;
	$ep->StyleSetForeground(&Wx::wxSTC_STYLE_LINENUMBER,&$color($config->{fore_color}));
	$ep->StyleSetBackground(&Wx::wxSTC_STYLE_LINENUMBER,&$color($config->{back_color}));
}


#
# marker margin
#
sub marker_visible { _marker_config->{visible} }
sub show_marker { show_marker_here($_) for @{_all_ref()} }
sub show_marker_here {
	my $ep = _ep_ref(shift);
	marker_visible()
		? $ep->SetMarginWidth(0, 16)
		: $ep->SetMarginWidth(0,  0);
}
sub switch_marker {
	_marker_config->{visible} ^= 1;
	show_marker();
}


#
# fold margin
#
sub fold_visible { _fold_config()->{visible} }
sub show_fold    { show_fold_here($_) for @{_all_ref()} }
sub show_fold_here {
	my $ep  = _ep_ref(shift);
	my $visible = fold_visible();
	my $width = $visible ? 16 : 0;
	$ep->SetProperty('fold' => $visible);
	$ep->SetMarginWidth( 2, $width );
	Kephra::App::EditPanel::Fold::unfold_all() unless $visible;
}
sub switch_fold  {
	_fold_config()->{visible} ^= 1;
	show_fold();
}
sub apply_fold_flag_color { apply_text_width_here($_) for @{_all_ref()}; }
sub apply_fold_flag_color_here {
	my $ep  = _ep_ref(shift);
	my $color = Kephra::Config::color( _fold_config()->{fore_color} );
	$ep->StyleSetForeground(&Wx::wxSTC_STYLE_DEFAULT, $color);
}

#
# extra text margin
#
sub get_text_width { _config->{text} }
sub set_text_width {
	_config->{text} = shift;
	apply_text_width();
}
sub apply_text_width { apply_text_width_here($_) for @{_all_ref()} }
sub apply_text_width_here {
	my $ep = _ep_ref(shift);
	my $width = get_text_width();
	$ep->SetMargins( $width, $width );
}

1;
#wxSTC_MARK_MINUS wxSTC_MARK_PLUS wxSTC_MARK_CIRCLE wxSTC_MARK_SHORTARROW
#wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED

=head1 NAME

Kephra::App::EditPanel::Margin - managing margin visuals for marker, linenumber, folding & extra space

=head1 DESCRIPTION

=cut