package Ftree::DataParsers::ExtendedSimonWardFormat;

require Ftree::DataParsers::ArrayImporters::CSVArrayImporter;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');

use Ftree::Name;
use Ftree::Picture;
use Ftree::FamilyTreeData;
use Params::Validate qw(:all);
use Ftree::StringUtils;
use v5.10.1;
use experimental 'smartmatch';
use Ftree::DataParsers::FieldValidatorParser;

# use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use utf8;

my $picture_directory;

sub getID {
	my ($name_with_space) = @_;
	$name_with_space =~ s/ /_/g;
	return $name_with_space;
}

sub getNameFields {
	my ($full_name) = @_;
	$full_name =~ s/[0-9]//g;
	my @full_name_a = split( / /, $full_name );
	my $mid_name;
	if ( @full_name_a > 2 ) {
		$mid_name =
		  join( ' ', @full_name_a[ 1 .. $#full_name_a - 1 ] );
	}
	return {
		first_name => $full_name_a[0],
		mid_name   => $mid_name,
		last_name  => $full_name_a[-1]
	};
}

sub fill_up_pictures {
	my ($family_tree_data) = @_;
	while ( my ( $id, $person ) = each %{ $family_tree_data->{people} } ) {
		my $picture_file_name =
		  getPictureFileName( getFileName($id), $picture_directory );
		$person->set_default_picture(
			Ftree::Picture->new(
				{
					file_name => $picture_file_name,
					comment   => ""
				}
			)
		) if ( defined $picture_file_name );
	}
}

sub getPictureFileName {
	my ($id) = @_;

	if ( -e "$picture_directory/$id.jpg" ) {
		return "$id.jpg";
	}
	elsif ( -e "$picture_directory/$id.gif" ) {
		return "$id.gif";
	}
	elsif ( -e "$picture_directory/$id.tif" ) {
		return "$id.tif";
	}
	elsif ( -e "$picture_directory/$id.png" ) {
		return "$id.png";
		{

		};
	}
	else {
		return;
	}
}

sub setPictureDirectory {
	my ($picture_directory_) = @_;
	$picture_directory = $picture_directory_;
}

# return: 0, in case of file open error
sub createFamilyTreeDataFromFile {
	my ($config_) = @_;
	my $file_name = $config_->{file_name}
	  or die "No file_name is given in config";

	my $family_tree_data = Ftree::FamilyTreeData->new();

	# default encoding is utf8
	my $encoding = defined $config_->{encoding} ? $config_->{encoding} : "utf8";
	my $arrayImporter =
	  Ftree::DataParsers::ArrayImporters::CSVArrayImporter->new( $file_name,
		$encoding );
	while ( $arrayImporter->hasNext() ) {
		my @fields = $arrayImporter->next();
		@fields = map { Ftree::StringUtils::trim($_) } @fields;

		my $name_ref = getNameFields( $fields[0] );
		my ( $date_of_birth, $date_of_death ) =
		  defined $fields[5] ? split( /-/, $fields[5], 2 ) : ( undef, undef );

		my $temp_person = $family_tree_data->add_person(
			{
				id             => getID( $fields[0] ),
				first_name     => $name_ref->{first_name},
				mid_name       => $name_ref->{mid_name},
				last_name      => $name_ref->{last_name},
				title          => $fields[7],
				prefix         => $fields[8],
				suffix         => $fields[9],
				nickname       => $fields[10],
				father_id      => getID( $fields[1] ),
				mother_id      => getID( $fields[2] ),
				email          => $fields[3],
				homepage       => $fields[4],
				date_of_birth  => $date_of_birth,
				date_of_death  => $date_of_death,
				gender         => $fields[6],
				is_living      => $fields[11],
				place_of_birth => $fields[12],
				place_of_death => $fields[13],
				cemetery       => $fields[14],
				schools        => ( defined $fields[15] )
				? [ split( /,/, $fields[15] ) ]
				: undef,
				jobs => ( defined $fields[16] ) ? [ split( /,/, $fields[16] ) ]
				: undef,
				work_places => ( defined $fields[17] )
				? [ split( /,/, $fields[17] ) ]
				: undef,
				places_of_living => $fields[18],
				general          => $fields[19]
			}
		);
		if ( defined $temp_person->get_father()
			&& !defined $temp_person->get_father()->get_name() )
		{
			$temp_person->get_father()
			  ->set_name( Ftree::Name->new( getNameFields( $fields[1] ) ) );
		}
		if ( defined $temp_person->get_mother()
			&& !defined $temp_person->get_mother()->get_name() )
		{
			$temp_person->get_mother()
			  ->set_name( Ftree::Name->new( getNameFields( $fields[2] ) ) );
		}
	}
	$arrayImporter->close();
	if ( defined $config_->{photo_dir} ) {
		setPictureDirectory( $config_->{photo_dir} );
		fill_up_pictures($family_tree_data);
	}

	return $family_tree_data;
}

#######################################################
# converts a name to a filename
# (converts spaces, converts case)
# CHANGE: we dont remove middle name: $newname =~ s/ .* / /;
#
sub getFileName {
	my ($id) = @_;
	$id =~ s/ /_/g;
	$id =~ tr/A-Z/a-z/;

	#  $id =~ tr/[á,é,ó,ö,ő,ú,ü,ű,í,Á,É,Ó,Ö,Ő,Ú,Ü,Ű,Í]/
	#            [a,e,o,o,o,u,u,u,i,a,e,o,o,o,u,u,u,i]/; #IT DOES NOT WORK?!?

	# This works:
	$id =~ s/á/a/g;
	$id =~ s/ä/a/g;
	$id =~ s/é/e/g;
	$id =~ s/ó/o/g;
	$id =~ s/ö/o/g;
	$id =~ s/ő/o/g;
	$id =~ s/ú/u/g;
	$id =~ s/ü/u/g;
	$id =~ s/ű/u/g;
	$id =~ s/í/i/g;
	$id =~ s/Á/a/g;
	$id =~ s/É/e/g;
	$id =~ s/Ó/o/g;
	$id =~ s/Ö/o/g;
	$id =~ s/Ő/o/g;
	$id =~ s/Ú/u/g;
	$id =~ s/Ü/u/g;
	$id =~ s/Ű/u/g;
	$id =~ s/Í/i/g;
	$id =~ s/ß/b/g;
	return $id;
}

1;

