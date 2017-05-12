package Lingua::YaTeA::ChunkingDataSet;
use strict;
use warnings;
use Lingua::YaTeA::ChunkingDataSubset;

our $VERSION=$Lingua::YaTeA::VERSION;


sub new
{
    my ($class,$file_set) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ChunkingFrontiers} = Lingua::YaTeA::ChunkingDataSubset->new;
    $this->{ChunkingExceptions} = Lingua::YaTeA::ChunkingDataSubset->new;
    $this->{CleaningFrontiers} = Lingua::YaTeA::ChunkingDataSubset->new;
    $this->{CleaningExceptions} = Lingua::YaTeA::ChunkingDataSubset->new;
 
    $this->loadData($file_set);
    return $this;
}


sub loadData
{
    my ($this,$file_set) = @_;
    my $name;
    my $path;
    my $subset;
    my $line;
    my $type;
    my $value;
    my @file_names = ("ChunkingFrontiers","ChunkingExceptions","CleaningFrontiers","CleaningExceptions");
    foreach $name (@file_names)
    {
	$path = $file_set->getFile($name)->getPath;
		
	$subset = $this->getSubset($name);
	
	my $fh = FileHandle->new("<$path");

	while ($line= $fh->getline)
	{
	    if(($line !~ /^#/)&&($line !~ /^\s*$/))
	    {
		$line =~ s/\r//g;
		chomp $line;
		$line =~ /([^\t]+)\t([^\t]+)/;
		$type= $1;
		$value = $2;
		$subset->addSome($type,$value);
	    }
	}
	
    }
}

sub getSubset
{
    my ($this,$name) = @_;
    return $this->{$name};
}


sub existData
{
    my ($this,$set,$type,$data) = @_;
    return $this->getSubset($set)->existData($type,$data);
}

1;

__END__

=head1 NAME

Lingua::YaTeA::ChunkingDataSet - Perl extension for the set of chuncking data

=head1 SYNOPSIS

  use Lingua::YaTeA::ChunkingDataSet;
  Lingua::YaTeA::ChunkingDataSet->new($file_set);

=head1 DESCRIPTION

The module implements sets of chunking data, i.e. chunking frontiers
(field C<ChunkingFrontiers>), chunking exceptions (field
C<ChunkingExceptions>), cleaning frontiers (C<CleaningFrontiers>), and
cleaning exceptions (C<CleaningExceptions>). Chunking data are stored
in subsets (C<Lingua::YaTeA::ChunckingSubset>).

=head1 METHODS

=head2 new()

    new($file_set);

The method creates a set of chunking data and the related subset. The
data stored in the directory c<$file_set> (an object C<Lingua::FileSet>) are loaded in the subsets.

=head2 loadData()

    loadData($file_set);

The method loads the chuncking data stored in the directory
c<$file_set> (an object C<Lingua::FileSet>) in the related subsets:
chunking frontiers (field C<ChunkingFrontiers>), chunking exceptions
(field C<ChunkingExceptions>), cleaning frontiers
(C<CleaningFrontiers>), and cleaning exceptions
(C<CleaningExceptions>).

=head2 getSubset()

    getSubset($name);

The method returns the subset corresponding to the field C<$name>
(i.e. ChunkingFrontiers, ChunkingExceptions, CleaningFrontiers,
CleaningExceptions).



=head2 existData()

    existData($set,$type,$data);

The methods checks if the data C<$data> exists in the field C<$type>
in the subset C<$set>. It returns 1 if it exists, otherwise 0.


=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
