package Ftree::DataParsers::ArrayImporters::CSVArrayImporter;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');
use Params::Validate qw(:all);
# use CGI::Carp qw(fatalsToBrowser);
my $fh;

sub new {
    my ($classname, $file_name, $encoding) = @_;
	my $self = {
    	current_line => undef,
  };
  open $fh, "<:encoding($encoding)", "$file_name"
     or die "Unable to open datafile $file_name";
  $self->{current_line} = <$fh>;
  return bless $self, $classname;
}
sub hasNext {
	my ($self) = validate_pos(@_, {type => HASHREF});
	return $self->{current_line};
}
sub next {
	my ($self) = validate_pos(@_, {type => HASHREF});
	my $prevline = $self->{current_line};
	do {
		$self->{current_line} = <$fh>;
	}
	while($self->{current_line} && $self->{current_line} =~ m/^\s*\#/x);  # skip comments


	chomp($prevline);
	return split( /;/, $prevline);
}
sub close {
	my ($self) = validate_pos(@_, {type => HASHREF});
	close($fh) or die "Unable to close datafile";
}

1;
