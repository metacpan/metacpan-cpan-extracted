package Kephra::File::IO;
our $VERSION = '0.20';

use strict;
use warnings;

# read a file into a scintilla buffer, is much faster then open_buffer
sub open_buffer {
	my $doc_nr = shift;
	my $file   = shift || Kephra::Document::Data::get_file_path($doc_nr);
	my $ep     = shift || Kephra::Document::Data::_ep($doc_nr);
	my $err_txt= Kephra::API::localisation->{dialog}{error};
	my $input;
	unless ($file) {
		Kephra::Dialog::warning_box("file_read " . $err_txt->{no_param}, $err_txt->{general} );
	} else {
		unless ( -r $file ) {
			Kephra::Dialog::warning_box( $err_txt->{file_read} . " " . $file, $err_txt->{file} );
		} else {
			my $did_open = open my $FH,'<', $file;
			unless ($did_open){
				Kephra::Dialog::warning_box($err_txt->{file_read} . " $file", $err_txt->{file});
				return 0;
			}
			my $codepage = Kephra::Document::Data::get_attribute('codepage', $doc_nr);
			if ($codepage eq 'auto'){
				binmode $FH;
				read $FH, my $probe, 20000;
				if ($probe){
					my $enc = Encode::Guess::guess_encoding( $probe, 'latin1' );
					seek $FH, 0, 0;
					$codepage = $enc =~ /utf8/ ? 'utf8' : '8bit';
					Kephra::Document::Data::set_attribute('codepage', $codepage, $doc_nr);
				} else {
					$codepage = Kephra::File::_config->{defaultsettings}{new}{codepage};
				}
				Kephra::Document::Data::set_attribute('codepage', $codepage, $doc_nr);
			}
			binmode $FH, $codepage eq 'utf8' ? ":utf8" : ":raw"; # ":encoding(utf8)"
			Kephra::EventTable::freeze('document.text.change');
			my $content = do { local $/; <$FH> };
			$ep->AddText( $content ) if defined $content;
			Kephra::EventTable::thaw('document.text.change');
			return 1;
		}
	}
	return 0;
}

# wite into file from buffer variable
sub write_buffer {
	my $doc_nr = shift || Kephra::Document::Data::current_nr();
	my $file   = shift || Kephra::Document::Data::get_file_path($doc_nr);
	my $ep     = shift || Kephra::Document::Data::_ep($doc_nr);
	my $err_txt = Kephra::API::localisation->{dialog}{error};
	# check if there is a name or if file that you overwrite is locked
	if ( not $file or (-e $file and not -w $file) ) {
		Kephra::Dialog::warning_box
			("file_write " . $err_txt->{'no_param'}, $err_txt->{general} );
	} else {
		my $codepage = Kephra::Document::Data::get_attribute('codepage', $doc_nr);
		my $did_open = open my $FH, '>', $file;
		unless ($did_open){
			Kephra::Dialog::warning_box($err_txt->{file_write} . " $file", $err_txt->{file} );
			return 0;
		}
		binmode $FH, $codepage eq 'utf8' ? ":utf8" : ":raw"; # ":encoding(utf8)"
		print $FH $ep->GetText();
	}
}


sub get_age {
	my $file = shift;
	return (stat $file)[9] if -e $file;
}

1;
