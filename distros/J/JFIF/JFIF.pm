package JPEG::JFIF;


$JPEG::JFIF::VERSION = '0.12';
use strict;

sub new {
    my ($c, %args) = @_;
    my $class = ref($c) || $c;

    my %tagTab = (
	object_name 			=> 5,
	urgency                         => 10,
	category 			=> 15,
	supplemental_categories 	=> 20,
        photostation_ident              => 22,
	keywords 			=> 25,
	special_instructions 		=> 40,
	byline_title 			=> 55,
	created_time                    => 60,
        photostation_orig               => 65,
	byline 				=> 80,
	city 				=> 90,
	province_state 			=> 95,
	country_name 			=> 101,
	original_transmission_reference => 103,
	headline 			=> 105,
	credit 				=> 110,
	source 				=> 115,
        copyright_notice                => 116,
	caption 			=> 120,
	caption_writer 			=> 122,
        photostation_note               => 230,
        photostation_info               => 231,
	); $args{tagTab} = \%tagTab;
	
    bless \%args, $class;
}

#
# Function to retrieve all possible data from JPEG file
#

sub getdata_all {
  my ($cl,$name) = @_;
  my $jpeg_data;

  if (!exists($cl->{bim})) { $cl->get8bimheaders(); }

  # parse every 8BIM
  foreach my $current_tag ( keys %{ $cl->{tagTab} } ) {
    my $idsearch = $cl->{tagTab}->{$current_tag};

    foreach my $data (values %{ $cl->{bim} } ) {
      for( my $i = 0 ; $i < length($data) ; $i++) {
	if ( ( my $id = unpack( "n", substr( $data, $i, 2) ) ) == 0x1C02 ) {
	  $i += 2;
	  if ( unpack("C", substr( $data, $i, 1 ) ) == $idsearch ) {
	    $i++;
	    # length data in that subset
	    my $len = unpack("n", substr( $data, $i, 2) );
	    $i += 2;

	    # no strict "refs";

	    my $current_value = substr($data,$i,$len);
	    if ( defined $jpeg_data->{ $current_tag } ) {
	      if ( ref( $jpeg_data->{ $current_tag } ) eq 'ARRAY' ) {
		my @tmp_array = @{ $jpeg_data->{ $current_tag } };
		push @tmp_array, $current_value;
		$jpeg_data->{ $current_tag } = \@tmp_array;
	      } else {
                push my @tmp_array, $jpeg_data->{ $current_tag };
		push @tmp_array, $current_value;
		$jpeg_data->{ $current_tag } = \@tmp_array;
	      }
	    } else {
	      $jpeg_data->{ $current_tag } = $current_value;
	    }
	  }
	}
      }
    }
  }
  return $jpeg_data;
}

#
# Function to retrieve certain ($name) field from JPEG file
#

sub getdata {
    my ($cl,$name) = @_;
    if (!exists($cl->{tagTab}->{$name})) { print STDERR "Tag \"$name\" not supported or misspelled (use lowercase)\n"; return(-1); };
    my $idsearch = $cl->{tagTab}->{$name};

    if (!exists($cl->{bim})) { $cl->get8bimheaders(); }

    # parse every 8BIM
    foreach my $data (values %{$cl->{bim}}) {
	for(my $i=0 ; $i<length($data) ; $i++) {
	    if ((my $id = unpack("n",substr($data,$i,2))) == 0x1C02) {
		$i += 2;
		if (unpack("C",substr($data,$i,1)) == $idsearch) {
		    $i++;
		    # length data in that subset
    		    my $len = unpack("n",substr($data,$i,2));
		    $i += 2;
		    return(substr($data,$i,$len));
		}
	    }
	}
    }
}

sub get8bimheaders {
    my ($cl,$header) = @_;
    if (!exists($cl->{header})) { $header = $cl->getheader(); }
    my $count = 0;
    for (my $i=0; $i<$cl->{headsize}; $i++) {
	if (unpack("N",substr($header,$i,4)) == 0x3842494D) {
	    $i += 4;
	    # 8BIM ID
	    my $id = unpack("n",substr($header,$i,2)); 
	    $i += 2;
	    # 8BIM Name
	    my $titlen = unpack("C",substr($header,$i,1));
	    $i += 1;
	    my $tagname;
	    if ($titlen != 0) { 
		# Photoshop 6.0
		$tagname = substr($header,$i,$titlen);
		$i += $titlen ;
		# if not parity len then add 0x00 (Adobe bug?!!)
		if (($titlen % 2) == 0) { $i++; }
	    } else { 
		# Photoshop 5.5
		$i += 1; 
	    }
	    # 8BIM Length
	    my $bimlen = unpack("N",substr($header,$i,4));
	    $i += 4;
	    $cl->{bim}->{$count++} = substr($header,$i,$bimlen);
	    $i += $bimlen;
	    # if not parity len then add 0x00 (Adobe bug?!!)
	    if (($bimlen % 2) == 0) { $i--; }
	}
      }
  }



sub getheader {
    my $cl = shift;
    if (!exists($cl->{filename}) || !exists($cl->{file})) { print STDERR "Read file first!\n"; return(-1); }
    for (my $i = 0;$i<$cl->{size};$i++) {
	if (unpack("n",substr($cl->{file},$i,2)) == 0xFFED) { 
	    $cl->{headsize} = unpack("n",substr($cl->{file},$i+2,2))-2;
	    $cl->{header} = substr($cl->{file},$i+4,$cl->{headsize});
	    return($cl->{header});
	}
    }
}



sub check {
    my $cl = shift;
    if (!exists($cl->{filename}) || !exists($cl->{file})) { return(-1); }
    if (unpack("n",substr($cl->{file},0,2)) != 0xFFD8) { print STDERR "Not JPEG file!\n"; return(-1); }
}



sub read {
    my ($cl,$filename) = @_;
    if (!open(FILE,"<".$filename)) { print STDERR "Couldn't open file $filename!\n"; return(-1); }
    binmode(FILE);
    while(read(FILE,my $buffer,1024) != 0) { $cl->{file}.=$buffer; };
    $cl->{filename} = $filename;
    $cl->{size} = (stat(FILE))[7];
    close(FILE);
    $cl->check();
}



sub write {
    my $cl = shift;
    if (exists($cl->{filename}) || exists($cl->{file})) {
	open(FILE,">".$cl->{filename}) || print STDERR "Couldn't open file ".$cl->{filename}." for write!\n";
	binmode(FILE);
        print FILE $cl->{file};
	close(FILE);
    } else { print STDERR "Couldn't write file!\n"; }
}

1;

__END__

=head1 NAME

JPEG::JFIF - JFIF/JPEG tags operations.

=head1 VERSION

JFIF.pm v. 0.12

=head1 CHANGES

 0.12 - Closed ticket #40161
 0.11 - added function getdata_all to retrieve all data as hash from file and some new fields (by Viljo Marrandi)
 0.10 - rewrite code to support older and newest Adobe Photoshop JPEG/JFIF formats, and to have better API.
 0.9.3  - another rule to workaround for that stupid 0x00 in APP14 (I couldn't find it in JFIF documentation)
 0.9 - fix caption add 0x00 in some situations. I don't know what it is, But have to be.
 0.8 - can set comment (Caption) tag correctly (hihi)
 0.7 - can read all metatags

=head1 SYNOPSIS

This module can read additional info that is set by Adobe Photoshop in jpeg files (JFIF/JPEG format)

=head1 DESCRIPTION

This module can read additional info that is set by Adobe Photoshop in jpeg files (JFIF/JPEG format)
Available sections name for getdata(name) are :

	object_name
	urgency
	category
	supplemental_categories
        photostation_ident
	keywords
	special_instructions
	byline_title
	created_time
        photostation_orig
	byline
	city
	province_state
	country_name
	original_transmission_reference
	headline
	credit
	source
        copyright_notice
	caption
	caption_writer
        photostation_note
        photostation_info

=head1 EXAMPLE

	#!/usr/bin/perl

	use JPEG::JFIF;
	use strict;

	my $jfif = new JPEG::JFIF;
	# this give you "caption" tag content.
	$jfif->read("file.jpg");
	print $jfif->getdata("caption"); 

=head1 COPYRIGHT AND LICENCE

Copyright 2002-2008 Marcin Krzyzanowski
Licence : Lesser General Public License v. 2.0

=head1 AUTHOR

Marcin Krzyzanowski <krzak at hakore.com>
http://www.hakore.com/

=cut
