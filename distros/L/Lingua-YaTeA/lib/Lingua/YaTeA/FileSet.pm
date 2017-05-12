package Lingua::YaTeA::FileSet;
use Lingua::YaTeA::File;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$repository) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{REPOSITORY} = $repository;
    $this->{FILES} = ();
    return $this;
}


sub checkRepositoryExists
{
    my ($this) = @_;
    if (! -d $this->getRepository)
    {
	die "No such repository :" . $this->getRepository . "\n";
    }
    else
    {
	print STDERR "Data will be loaded from: ". $this->getRepository . "\n";
    }
}

sub addFile
{
    my ($this,$repository,$name) = @_;
    my $file;
    my $option;
    
    $file = Lingua::YaTeA::File->new($repository,$name);
    
    $this->{FILES}->{$file->getInternalName} = $file;
}

sub getFile
{
    my ($this,$name) = @_;
    return $this->{FILES}->{$name};
}

sub addFiles
{
    my ($this,$repository,$file_name_a) = @_;
    my $name;
    foreach $name (@$file_name_a)
    {
	$this->addFile($repository,$name);
    }
}

sub getRepository
{
    my ($this) = @_;
    return $this->{REPOSITORY} ;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::FileSet - Perl extension for managing the directory containing the configuration file set given a language.

=head1 SYNOPSIS

  use Lingua::YaTeA::FileSet;
  Lingua::YaTeA::FileSet->new($repository);

=head1 DESCRIPTION

The module provides methods for managing a repository of configuration
filss for a given language. Information associated to the file set is
the repository path (field C<REPOSITORY>) and the file list. This list
is (an array stored in the field C<FILES> wher each element is a
C<Lingua::YaTeA::File> object.

=head1 METHODS

=head2 new()

    new($repository);

This method creates a object and sets the C<REPOSITORY> field.

=head2 checkRepositoryExists()

    checkRepositoryExists();

This methods checks if the directory referring to the repository
exists or not.

=head2 addFile()

    addFile($repository, $name);

The method adds a new file (C<$name>) from the repository
C<$repository>.


=head2 getFile()

    getFile($filename);

The method returns the object C<Lingua::YaTeA::File> corresponding to
the file C<$filename>.

=head2 addFiles()

    addFile($repository, \@filenames);

This method adds the list of configuration files contained in the
array given by reference (C<\@filenames>).

=head2 getRepository()

    getRepository();

This method returns the name of the repository.


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
