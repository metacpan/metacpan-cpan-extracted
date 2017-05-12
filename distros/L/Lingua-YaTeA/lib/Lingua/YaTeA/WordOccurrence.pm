package Lingua::YaTeA::WordOccurrence;
use strict;
use warnings;
use Lingua::YaTeA::ChunkingDataSet;
use UNIVERSAL;
use Scalar::Util qw(blessed);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$form) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{FORM} = $this->setForm($form);
    return $this;
}

sub setForm
{
    my ($this,$form) = @_;
    $this->{FORM} = $form;
}

sub getForm
{
    my ($this,$form) = @_;
    return $this->{FORM};
}

sub isChunkEnd
{
    my ($this,$action,$split_after,$sentence_boundary,$document_boundary,$chunking_data) = @_;
    
    if ((blessed($this)) && ($this->isa("Lingua::YaTeA::WordFromCorpus")))
    {
	if ($Lingua::YaTeA::Corpus::tt_counter != 0){ # word is between testified term frontiers: not end
	    return 0;
	}
	$$split_after--;
	if($$split_after == 0)
	{
	    return 1;
	}
	if ( # word is a sentence or document boundary : end 
	    ($this->isSentenceBoundary($sentence_boundary) == 1)
	    ||
	    ($this->isDocumentBoundary($document_boundary) == 1)
	    )
	{
	    return 1;
	}
	# Test if word is a chunking frontier
	if ($this->isChunkingFrontier($chunking_data))
	{
	    if($Lingua::YaTeA::Corpus::tt_counter == 0)
	    {
		return 1;
	    }
	}

    }
    else{
	if ((blessed($this)) && ($this->isa("Lingua::YaTeA::ForbiddenStructureMark")))
	{
	    if ($this->isOpener)
	    {
		$Lingua::YaTeA::Corpus::forbidden_counter ++;
		$$action = $this->getAction;
		if($$action eq "split")
		{
		    
		    $$split_after = $this->getSplitAfter +1;
		}
	    }
	    else{
		if ($this->isCloser)
		{
		    $Lingua::YaTeA::Corpus::forbidden_counter --;
		    if (($Lingua::YaTeA::Corpus::tt_counter == 0) && ($this->getAction ne "split")) {
			# warn "==>1\n";
			return 1;
		    } else {
			return(0);
		    }
		}	
		else{
		    die "erreur\n";
		}
	    }	
	}
	else
	{
	    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::TestifiedTermMark'))) {
		if ($this->isOpener)
		{
		    $Lingua::YaTeA::Corpus::tt_counter++;
		}
		else
		{
		    if ($this->isCloser)
		    {
			$Lingua::YaTeA::Corpus::tt_counter--;
		    }
		}
		return 0;
	    }
	}
    }
    
    if( # word is in a forbidden structure but out of testified term frontiers: end
	($Lingua::YaTeA::Corpus::forbidden_counter != 0)
	&&
	($Lingua::YaTeA::Corpus::tt_counter == 0)
	)
    {
	if ($$action eq "delete")
	{
	    return 1;
	}
	else{
	   
	   # $Lingua::YaTeA::Corpus::split_counter--;
	   # if($Lingua::YaTeA::Corpus::split_counter == 0)
	    
	    #return 0;
	}
	return 0;
    }


}

sub print
{
    my ($this,$fh) = @_;
    if(defined $fh)
    {
	print $fh $this->getForm . "\n";
    }
    else
    {
	print $this->getForm . "\n";
    }
}

1;

__END__

=head1 NAME

Lingua::YaTeA::WordOccurrence - Perl extension for managing word occurrence

=head1 SYNOPSIS

  use Lingua::YaTeA::WordOccurrence;
  Lingua::YaTeA::WordOccurrence->new($form)

=head1 DESCRIPTION

The module implements a basic representation of word occurrence in the
input corpus. It is used in the module Lingua::YaTeA::AnnotationMark.

=head1 METHODS

==head2 new()

    new($form);

The method creates a new object for managing word occurrence having
the inflected form C<$form>.

=head2 setForm()

    setForm($form);

The method sets the inflected form (C<$form>) of the word occurrence.

=head2 getForm()

    getForm();

The methods returns the inflected form of the word occurrence.

=head2 isChunkEnd()

    isChunkEnd($action,$split_after,$sentence_boundary,$document_boundary,$chunking_data);

The methods indicates if the word occurrence is the end of chunk
(return value 1) or not (return value 0) regarding the sentence and
document boundaries (C<$sentence_boundary> and C<$document_boundary>),
if the chunknig frontier (according toC<$chunking_data>), or the
presence of a forbidden frontier and the related action (C<$action>
values are C<delete> and C<split> -- C<$split_after> indicates if the
rank of the word after which the chunk is split).


=head2 print()

    print($fh);

The method prints into the file hanlder C<$fh>, the information
related to the word occurrence (i.e. its inflected form).

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
