package Kephra::Document::Property;
our $VERSION = '0.04';

use strict;
use warnings;
# some internal shortcut helper
sub _ep_ref     { Kephra::Document::Data::_ep($_[0]) }
sub _doc_nr     { Kephra::Document::Data::valid_or_current_doc_nr($_[0]) }
sub _is_current { $_[0] == Kephra::Document::Data::current_nr() }
sub _get_attr   { Kephra::Document::Data::get_attribute(@_) }
sub _set_attr   { Kephra::Document::Data::set_attribute(@_) }
#
# general API for single and multiple values (getter/setter)
#
sub get {
	my $property = shift;
	my $doc_nr = _doc_nr(shift);
	return if $doc_nr < 0;
	if    (not ref $property)        { _get_attr($property, $doc_nr) }
	elsif (ref $property eq 'ARRAY') {
		my @result;
		push @result, _get_attr($_, $doc_nr) for @$property;
		\@result;
	}
}
sub _set{
	my ($key, $v) = @_;
	return unless defined $v;
	return set_codepage($v)  if $key eq 'codepage';
	return set_EOL_mode($v)  if $key eq 'EOL';
	return set_readonly($v)  if $key eq 'readonly';
	return set_syntaxmode($v)if $key eq 'syntaxmode';
	return set_tab_size($v)  if $key eq 'tab_size';
	return set_tab_mode($v)  if $key eq 'tab_use';
}
sub set {
	if (not ref $_[0] and defined $_[1]){_set(@_)}
	elsif ( ref $_[0] eq 'HASH')        {_set($_, $_[0]->{$_}) for keys %{$_[0]}}
}
sub get_file { _get_attr('file_path') }
sub set_file {
	my ($file, $nr) = @_;
	$nr = _doc_nr($nr);
	return if $nr < 0;
	Kephra::Document::Data::set_file_path($file, $nr);
	Kephra::App::TabBar::refresh_label($nr);
	Kephra::App::Window::refresh_title() if _is_current($nr);
}
#
# property specific API
#
#
# syntaxmode
sub get_syntaxmode { _get_attr('syntaxmode') }
sub set_syntaxmode { Kephra::Document::SyntaxMode::set(@_) }
#
#
sub get_codepage { _get_attr('codepage', $_[0]) }
sub set_codepage {
	my ($new_value, $doc_nr) = @_;
	$doc_nr = _doc_nr($doc_nr);
	return if $doc_nr < 0 or not defined $new_value;
	my $old_value = get_codepage($doc_nr);
	my $ep = _ep_ref($doc_nr);
	if    ($old_value eq 'ascii' and $new_value eq 'utf8'){
		#unless (Encode::is_utf8($ep->GetText())) {
			Kephra::Document::Data::update_attributes($doc_nr);
			eval {
				#Encode::encode('ascii');
				$ep->SetText( Encode::decode('utf8', $ep->GetText()) );
			};
			#print "$@\n";
			Kephra::Document::Data::evaluate_attributes($doc_nr);
		#}
		#print Encode::is_utf8($ep->GetText())."\n";
	}
	elsif ($old_value eq 'utf8' and $new_value eq 'ascii') {
		Kephra::Document::Data::update_attributes($doc_nr);
		$ep->SetText( Encode::encode('utf8', $ep->GetText()) );
		Kephra::Document::Data::evaluate_attributes($doc_nr);
	}
#print "ask auto $mode\n";
	#$ep->SetCodePage( &Wx::wxSTC_CP_UTF8 );
	_set_attr('codepage', $new_value, $doc_nr);
	Kephra::App::StatusBar::codepage_info($new_value);
}
sub switch_codepage {
	set_codepage( get_codepage( _doc_nr() ) eq 'utf8' ? 'ascii' : 'utf8' );
}
#
# tab size
sub get_tab_size { _get_attr('tab_size', $_[0]) }
sub set_tab_size {
	my ($size, $nr) = @_;
	$nr = _doc_nr($nr);
	return if not $size or $nr < 0;
	my $ep = _ep_ref();
	$ep->SetTabWidth($size);
	$ep->SetIndent($size);
	$ep->SetHighlightGuide($size);
	_set_attr('tab_size', $size, $nr);
}
#
# tab use
sub get_tab_mode { _get_attr('tab_use', $_[0]) }
sub set_tab_mode {
	my $mode = shift;
	my $nr = _doc_nr(shift);
	return if $nr < 0;
	my $ep = _ep_ref();
	if ($mode eq 'auto') {
		if ($ep->GetTextLength){
			my $line;
			for my $lnr (0 .. $ep->GetLineCount()-1){
				$line = $ep->GetLine($lnr);
				if ($line =~ /^( |\t)/) {
					$mode = $1 eq ' ' ? 0 : 1;
					last;
				}
			}
		}
		else {
			$mode = Kephra::File::_config()->{defaultsettings}{new}{tab_use};
		}
	}
	$ep->SetUseTabs($mode);
	_set_attr('tab_use', $mode, $nr);
	Kephra::App::StatusBar::tab_info() if _is_current($nr);
}
sub set_tabs_hard  { set_tab_mode(1) }
sub set_tabs_soft  { set_tab_mode(0) }
sub switch_tab_mode{ get_tab_mode() ? set_tab_mode(0) : set_tab_mode(1) }
#
# EOL
sub EOL_length   { _get_attr('EOL_length') }
sub get_EOL_mode { _get_attr('EOL') }
sub set_EOL_mode {
	my $mode = shift;
	return unless defined $mode;
	if ($mode eq 'OS') {
		if    (&Wx::wxMSW) {$mode = 'cr+lf'}
		elsif (&Wx::wxMAC) {$mode = 'cr'   }
		else               {$mode = 'lf'   }
	}
	$mode = detect_EOL_mode() if $mode eq 'auto';
	my $ep = _ep_ref();
	my $eoll = 1;
	if ( $mode eq 'cr+lf'or $mode eq 'win') {$ep->SetEOLMode(&Wx::wxSTC_EOL_CRLF); 
		$eoll = 2;
	}
	elsif ( $mode eq 'cr'or $mode eq 'mac') {$ep->SetEOLMode(&Wx::wxSTC_EOL_CR) }
	else                                    {$ep->SetEOLMode(&Wx::wxSTC_EOL_LF) } 
	_set_attr('EOL',        $mode);
	_set_attr('EOL_length', $eoll);
	Kephra::App::StatusBar::EOL_info($mode);
}

sub convert_EOL {
	my $mode  = shift || get_EOL_mode();
	my $doc_nr = _doc_nr(shift);
	my $ep = _ep_ref($doc_nr);
	$mode = Kephra::File::_config()->{defaultsettings}{EOL_open} unless $mode;
	$mode = detect_EOL_mode() if $mode eq 'auto';
	Kephra::EventTable::freeze_group('edit');
	if ($mode eq 'cr+lf' or $mode eq 'win')  {$ep->ConvertEOLs(&Wx::wxSTC_EOL_CRLF)}
	elsif ($mode eq 'cr' or $mode eq 'mac' ) {$ep->ConvertEOLs(&Wx::wxSTC_EOL_CR)}
	else                                     {$ep->ConvertEOLs(&Wx::wxSTC_EOL_LF)}
	Kephra::EventTable::thaw_group('edit');
	set_EOL_mode($mode);
}

sub detect_EOL_mode {
	my $ep = _ep_ref();
	my $end_pos   = $ep->PositionFromLine(1);
	my $begin_pos = $end_pos - 3;
	$begin_pos = 0 if $begin_pos < 0;
	my $text = $ep->GetTextRange( $begin_pos, $end_pos );

	if ( length($text) < 1 ) { return 'auto' }
	else {
#print "win \n" if $text =~ /\r\n/;
		#return 'cr+lf' if $text =~ /\r\n/;
		#return 'cr'    if $text =~ /\r/;
		#return 'lf'    if $text =~ /\n/;
		return 'auto';
	}
}
#
# write protection
sub get_readonly { _get_attr('readonly') }
sub set_readonly {
	my $status = shift;
	my $ep     = _ep_ref();
	if (not $status or $status eq 'off' ) {
			$ep->SetReadOnly(0);
			$status = 'off';
	} elsif ( $status eq 'on' or $status eq '1' ) {
		$ep->SetReadOnly(1);
		$status = 'on';
	} elsif ( $status eq 'protect' or $status eq '2' ) {
		my $file = Kephra::Document::Data::get_file_path();
		if ( $file and not -w $file ) {$ep->SetReadOnly(1)}
		else                          {$ep->SetReadOnly(0)}
		$status = 'protect';
	}
	_set_attr('readonly', $status);
	$status = $ep->GetReadOnly ? 1 : 0;
	_set_attr('editable', $status);
	Kephra::App::TabBar::refresh_current_label()
		if Kephra::App::TabBar::_config()->{info_symbol};
}
sub set_readonly_on      { set_readonly('on') }
sub set_readonly_off     { set_readonly('off') }
sub set_readonly_protect { set_readonly('protect') }

1;
__END__

=head1 NAME

Kephra::Document::Property - external API for document handling

=head1 DESCRIPTION

=over 4

=item syntaxmode

=item codepage

=item readonly

=item tab size and usage

=item end of line marker

=back


