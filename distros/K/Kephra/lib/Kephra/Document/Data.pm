package Kephra::Document::Data;
our $VERSION = '0.08';

use strict;
use warnings;

# global values
my %values;         # global doc values
sub values   { \%values }
sub get_value { $values{$_[0]} if defined $values{$_[0]} }
sub set_value { $values{$_[0]} = $_[1] if defined $_[1]  }
sub inc_value { $values{$_[0]}++ }
sub dec_value { $values{$_[0]}-- }
sub del_value { delete $values{$_[0]} if defined  $values{$_[0]}}

# values per dos
my @attributes;     # data per doc for all open docs
my $current_attr;   # data of current doc
my $current_nr = 0;
my $previous_nr = 0;

# global attr functions
sub _attributes     { \@attributes } 
sub _values         { \%values     }
sub _hash           { $attributes[$_[0]] }
sub _ep             {
	my $nr = valid_or_current_doc_nr($_[0]);
	return if $nr < 0;
	my $ep = $attributes[$nr]{ep_ref};
	$ep if Kephra::App::EditPanel::is($ep);
}

sub count           { @attributes  }
sub last_nr         { $#attributes } 
sub previous_nr     { $previous_nr }
sub current_nr      { $current_nr  }
sub next_nr         {
	my $inc = shift;
	return unless defined $inc and $inc;
	my $base = shift;
	$base = current_nr() unless defined $base;
	my $last_nr = last_nr();
	my $nr = $base + $inc;
	$nr += $last_nr+1 if $nr < 0;
	$nr -= $last_nr+1 if $nr > $last_nr;
	return validate_doc_nr($nr);
}
sub all_nr          { [0..last_nr()] }
sub get_previous_nr { $previous_nr }
sub set_previous_nr { $previous_nr = $_[0] if defined $_[0] }
sub get_current_nr  { $current_nr }
sub set_current_nr  { 
	$current_nr = $_[0] if defined $_[0] and validate_doc_nr($_[0]) > -1;
	$current_attr = $attributes[$current_nr];
	Kephra::App::EditPanel::_set_ref( _ep($current_nr) );
	my $fconf = Kephra::File::_config();
	$fconf->{current}{directory} = get_attribute('directory', $current_nr)
		if ref $fconf;
}
sub validate_doc_nr { 
	my $nr = shift;
	return -1 unless defined $nr;
	return -1 unless $nr eq int $nr;
	$nr = exists $attributes[$nr] ? $nr : -1;
}
sub valid_or_current_doc_nr {
	my $nr = validate_doc_nr(shift);
	$nr == -1 ? current_nr() : $nr;
}
sub create_slot     {
	my $nr = shift;
	$attributes[$_+1] = $attributes[$_] for reverse $nr .. last_nr();
	$attributes[$nr] = {};
	set_current_nr($current_nr+1) if $current_nr >= $nr;
	$previous_nr++ if $previous_nr >= $nr;
}
sub empty_slot      {
	my $nr = shift;
	return if $nr < 0 or exists $attributes[$nr];
	$attributes[$nr] = {}
}
sub delete_slot     { 
	my $nr = validate_doc_nr(shift);
	return if $nr < 0;
	splice @attributes, $nr, 1;
}

# generic attr data accessors on any value and any doc
sub get_attribute {
	my $attr = shift;
	return unless defined $attr or $attr;
	my $nr = shift;
	$nr = defined $nr ? validate_doc_nr($nr) : current_nr();
	return if $nr < 0;
	$attributes[ $nr ]{ $attr } if defined $attributes[ $nr ]{ $attr };
}

sub set_attribute {
	my $attr = shift;
	my $value = shift;
	return unless defined $value;
	my $nr = shift;
	$nr = defined $nr ? validate_doc_nr($nr) : current_nr();
	return if $nr < 0;
	$attributes[ $nr ]{ $attr } = $value;
	$value;
}

sub set_all_attributes { # all attr of one doc
	my $attr = shift;
	my $nr = validate_doc_nr(shift);
	return if $nr < 0 or ref $attr ne 'HASH';
	$attributes[ $nr ] = $attr;
}
# shortcut accessors just for current doc and many values
sub attributes {
	my $params = shift;
	my $nr = validate_doc_nr(shift);
	return if $nr < 0;
	my $attr = $attributes[$nr];
	if (ref $params eq 'ARRAY') {
		my @result;
		push @result, $attr->{ $_ } for @$params;
		return \@result;
	}
	elsif (ref $params eq 'HASH') {
		$attr->{$_} = $params->{$_} for keys %$params;
	}
}
# shortcut accessors just for current doc and one value
sub attr {
	if (defined $_[1]){ $current_attr->{$_[0]} = $_[1]}
	else              { $current_attr->{$_[0]} }
}

# specific data (attribute) accessors
sub first_name      { get_attribute('firstname', $_[0]) }
sub file_name       { get_attribute('file_name', $_[0]) }
sub file_path       { defined $_[0] ? set_file_path($_[0]) : get_file_path() }
sub get_file_path   { get_attribute('file_path', $_[0]) }
sub set_file_path   {
	my ( $file_path, $doc_nr ) = @_;
	$doc_nr = valid_or_current_doc_nr($doc_nr);
	set_attribute('file_path', $file_path, $doc_nr);
	dissect_path( $file_path, $doc_nr );
}

sub dissect_path    {
	my ($file_path, $doc_nr) = @_;
	$doc_nr = validate_doc_nr($doc_nr);
	return if $doc_nr < 0;
	my $attr = $attributes[$doc_nr];
	my ($volume, $directories, $file) = File::Spec->splitpath( $file_path );
	$directories = $volume.$directories if $volume;
	$attr->{directory} = $directories;
	$attr->{file_name} = $file;

	if ( length($file) > 0 ) {
		my @filenameparts = split /\./, $file ;
		$attr->{ending}   = pop @filenameparts if @filenameparts > 1;
		$attr->{firstname}= join '.', @filenameparts;
	}
}

sub all_file_pathes {
	my @pathes;
	push @pathes, $_->{file_path} for @attributes;
	return \@pathes;
}
sub all_file_names  {
	my @names;
	$names[$_] = $_->{file_name} for @attributes;
	return \@names;
}

sub nr_from_file_path {
	my $given_path = shift;
	return -1 unless $given_path;
	for ( 0 .. $#attributes ) {
		if (defined $attributes[$_]{'file_path'} 
		and $attributes[$_]{'file_path'} eq $given_path) {
			return $_;
		}
	}
	return -1;
}

sub file_already_open { 1 if nr_from_file_path(shift) > -1 }
sub cursor_pos {
	$attributes[$current_nr]{cursor_pos} if $values{loaded};
}
sub nr_from_ep {
	my $ep = shift;
	for (@{all_nr()}) {
		return $_ if $ep eq _ep($_);
	}
	return -1;
}
sub get_all_ep {
	my @ep;
	for (@{all_nr()}) {
		my $ep = _ep($_);
		push @ep, $ep if $ep;
	}
	\@ep;
}

# more complex operations
sub set_missing_attributes_to_default {
	my ($nr, $file) = @_;
	$nr = validate_doc_nr($nr);
	return if $nr < 0;
	$file = get_file_path($nr) unless defined $file;
	my $default = Kephra::File::_config()->{defaultsettings};
}

sub set_attributes_to_default {
	my ($nr, $file) = @_;
	$nr = validate_doc_nr($nr);
	return if $nr < 0;
	my $config = Kephra::File::_config()->{defaultsettings};
	return unless ref $config eq 'HASH';
	$file = get_file_path($nr) unless defined $file;
	my $attr = {
		'edit_pos'    => -1,
		'ep_ref'      => _ep($nr),
		'file_path'   => $file,
	};
	my $default = (defined $file and -e $file) ? $config->{open} : $config->{new};
	$attr->{$_} = $default->{$_} 
		for qw(EOL codepage cursor_pos readonly syntaxmode tab_size tab_use);
	set_all_attributes($attr, $nr);
	dissect_path($file, $nr);
	set_current_nr($nr) if $nr == current_nr();
}

sub evaluate_attributes {
	my $doc_nr = validate_doc_nr(shift);
	return if $doc_nr < 0;
	my $config = Kephra::File::_config();
	my $attr = $attributes[$doc_nr];
	my $ep = Kephra::App::EditPanel::_ref();

	Kephra::EventTable::freeze('document.text.change');
	Kephra::Document::Property::set( {$_ => $attr->{$_} } )
		for qw(codepage tab_use tab_size EOL readonly syntaxmode);
	Kephra::EventTable::thaw('document.text.change');

	# setting selection and caret position
	if ($attr->{selstart} and $attr->{selstart}) {
		$attr->{cursor_pos} < $attr->{selend}
			? $ep->SetSelection( $attr->{selend},$attr->{selstart})
			: $ep->SetSelection( $attr->{selstart},$attr->{selend});
	}
	else { $ep->GotoPos( $attr->{cursor_pos} ) }
	if ($config->{open}{in_current_dir}){
		$config->{current}{directory} = $attr->{directory}
			if $attr->{directory};
	}
	else { $config->{current}{directory} = '' }
	Kephra::App::EditPanel::set_word_chars($ep);
	Kephra::App::EditPanel::Indicator::paint_bracelight($ep)
		if Kephra::App::EditPanel::Indicator::bracelight_visible();
	Kephra::App::EditPanel::Margin::autosize_line_number();
	Kephra::App::EditPanel::Fold::restore($doc_nr);
	Kephra::App::StatusBar::refresh_cursor();
	Kephra::Edit::Marker::restore($doc_nr);
	Kephra::Edit::_let_caret_visible();
}

sub update_attributes { # was named save_properties
	my $doc_nr = valid_or_current_doc_nr(shift);
	return if $doc_nr < 0;
	my $attr = _hash($doc_nr);
	my $ep = _ep($doc_nr);
	$attr->{cursor_pos}= $ep->GetCurrentPos;
	$attr->{selstart}  = $ep->GetSelectionStart;
	$attr->{selend}    = $ep->GetSelectionEnd;
	Kephra::App::EditPanel::Fold::store($doc_nr);
	Kephra::Edit::Marker::store($doc_nr);
}

1;

=head1 NAME

Kephra::Document::Data - API for data assotiated with opened documents

=head1 DESCRIPTION

=cut
