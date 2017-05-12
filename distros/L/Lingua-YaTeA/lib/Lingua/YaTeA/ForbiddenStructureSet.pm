package Lingua::YaTeA::ForbiddenStructureSet;
use strict;
use warnings;
use Lingua::YaTeA::ForbiddenStructureAny;
use Lingua::YaTeA::ForbiddenStructureStartOrEnd;
use Lingua::YaTeA::TriggerSet;

our $VERSION=$Lingua::YaTeA::VERSION;


sub new
{
    my ($class,$file_path) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ANY} = [];
    $this->{START} = [];
    $this->{END} = [];
    $this->{START_TRIGGERS} = Lingua::YaTeA::TriggerSet->new();
    $this->{END_TRIGGERS} = Lingua::YaTeA::TriggerSet->new();
    $this->loadStructures($file_path);
    return $this;
}


sub loadStructures
{
    my ($this,$file_path) = @_;

    my @infos;
    my $fh = FileHandle->new("<$file_path");
    my $line;
    while ($line= $fh->getline)
    {
	if(($line !~ /^#/)&&($line !~ /^\s*$/))
	{
	    @infos = split /\t/, $line;
	    $this->cleanInfos(\@infos);
	    if($infos[1] eq "ANY")
	    {
		my $fs = Lingua::YaTeA::ForbiddenStructureAny->new(\@infos); 
		push @{$this->{ANY}}, $fs;
	    }
	    else{
		chomp $infos[1];
		if(($infos[1] eq "START") ||($infos[1] eq "END") )
		{
		    my $fs = Lingua::YaTeA::ForbiddenStructureStartOrEnd->new(\@infos,$this->getTriggerSet($infos[1])); 
		    push @{$this->{$infos[1]}}, $fs;
		}
	    }
	}
    }
    $this->sort($this->getSubset("START"));
    $this->sort($this->getSubset("END"));
    
}



sub getTriggerSet
{
    my ($this,$position) = @_;
    my $name = $position . "_TRIGGERS";
    return $this->{$name};
}

sub getSubset
{
    my ($this,$name) = @_;
    return $this->{$name};

}

sub cleanInfos
{
    my ($this,$infos_a) = @_;
    my $info;
    foreach $info (@$infos_a)
    {
	chomp $info;
	$info =~ s/\r//g;
    }
}

sub sort
{
    my ($this,$subset) = @_;
   
    @$subset = sort ({$b->getLength <=> $a->getLength} @$subset);

}


1;

__END__

=head1 NAME

Lingua::YaTeA::ForbiddenStructureSet - Perl extension for managing the
forbiddent structures.

=head1 SYNOPSIS

  use Lingua::YaTeA::ForbiddenStructureSet;
  Lingua::YaTeA::ForbiddenStructureSet->new();

=head1 DESCRIPTION

This module gathers forbidden structures used while the chunking
step. The set of forbidden structures is composed of five fields:

=over

=item *

C<ANY>

It lists the strings corresponding to forbidden structures used in ANY position of a chunk

=item *

C<START>

It lists the strings corresponding to forbidden structures used in the START position of a chunk

=item *

C<END>

It lists the strings corresponding to forbidden structures used in the END position of a chunk

=item *

C<START_TRIGGERS>

This field contains the triggers defining the beginning of the
forbidden structure.

=item *

C<END_TRIGGERS>

This field contains the triggers defining the end of the forbidden
structure.


=back



=head1 METHODS

=head2 new()


    new($file_path)

The method creates a forbidden structure set and loads the forbidden
structures from the file C<$file_path>.


=head2 loadStructures()


    loadStructures($file_path);

The method loads the forbidden structures from the file C<$file_path>, and set the triggers.


=head2 getTriggerSet()

    getTriggerSet($position);

This methid returns the trigger set that can be used in the position
C<ANY>, C<START> or C<END>.

=head2 getSubset()

    getSubset($name);


This methid returns the forbidden structure subset according the given position C<$name> (i.e.
C<ANY>, C<START> or C<END>).

=head2 cleanInfos()

    cleanInfos($infos_a);

The internal method is used to chomp the informations read in the
file. C<infos_a> is the reference to the array containing the
information related to a forbidden structure.
					     

=head2 sort()

    sort($subset);

the method sorts the forbidden structure subset according their length.


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
