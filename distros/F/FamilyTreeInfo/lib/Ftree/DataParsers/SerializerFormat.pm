package Ftree::DataParsers::SerializerFormat;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');
use Ftree::DataParsers::FieldValidatorParser;
use Ftree::DataParsers::ExtendedSimonWardFormat; # for getting pictures. Temporal solution
use Ftree::FamilyTreeData;
use Storable;
# use CGI::Carp qw(fatalsToBrowser);

sub createFamilyTreeDataFromFile {
  my ($config_) = @_;
  my $file_name = $config_->{file_name} or die "No file_name is given in config";

  my $family_tree_data = Storable::retrieve($file_name);
  if(defined $config_->{photo_dir}) {
    Ftree::DataParsers::ExtendedSimonWardFormat::setPictureDirectory($config_->{photo_dir});
    Ftree::DataParsers::ExtendedSimonWardFormat::fill_up_pictures($family_tree_data);
  }

  return $family_tree_data;
}

1;
