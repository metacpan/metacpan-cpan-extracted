package Lingua::YaTeA::ForbiddenStructureMark;
use strict;
use warnings;
use Lingua::YaTeA::AnnotationMark;


our @ISA = qw(Lingua::YaTeA::AnnotationMark);
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$form) = @_;
    my ($id,$action,$split_after,$type) = $class->parse($form);
    my $this = $class->SUPER::new($form,$id,$type);
    bless ($this,$class);
    $this->{ACTION} = $action;
    $this->{SPLIT_AFTER} = $split_after;
    return $this;
}

sub parse
{
    my ($class,$form) = @_;
    my $id;
    my $action;
    my $split_after;
    my $type;
    
    if ($form =~ /^\<FORBIDDEN ID=([0-9]+) ACTION=([a-z]+)( SPLIT_AFTER=([0-9]+))?\>/)
    { # opening forbidden structure mark
	$type = "opener";
	$id = $1;
	$action = $2;
	if ($action eq "split")
	{ # if splitting instructions are provided
	    $split_after = $4;
	}
    }
    else
    { # closing forbidden structure mark
	if($form =~ /^\<\/FORBIDDEN ID=([0-9]+) ACTION=([a-z]+)( SPLIT_AFTER=([0-9]+))?\>/)
	{
	    $type = "closer";
	    $id = $1;
	    $action = $2;
	    if ($action eq "split")
	    { # if splitting instructions are provided
		$split_after = $4;
	    }
	}
	else{
	    die "Invalid line: " .$form . "\n";
	}  
    }
    return ($id,$action,$split_after,$type);
}

sub isOpener
{
    my ($this) = @_;
    if($this->{TYPE} eq "opener")
    {
	return 1
    }
    return 0;
}

sub isCloser
{
    my ($this) = @_;
    if($this->{TYPE} eq "closer")
    {
	return 1
    }
    return 0;
}

sub getAction
{
    my ($this) = @_;
    return $this->{ACTION}
}


sub getSplitAfter
{
    my ($this) = @_;
    return $this->{SPLIT_AFTER}
}


sub isActionSplit
{
    my ($this) = @_;
    if($this->getAction eq "split")
    {
	return 1
    }
    return 0;
}

sub isActionDelete
{
    my ($this) = @_;
    if($this->getAction eq "delete")
    {
	return 1
    }
    return 0;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::ForbiddenStructureMark - Perl extension for mananging the annotation marks for the forbidden structures

=head1 SYNOPSIS

  use Lingua::YaTeA::ForbiddenStructureMark;
  Lingua::YaTeA::ForbiddenStructureMark->new($form);

=head1 DESCRIPTION

This method implements the annotation marks defining the forbidden
structures in the corpus. forbidden structure marks are
lexico-syntactic structures defining the phrases which must not appear
in the terms. The object inherits of the module
Lingua::YaTea::AnnotaionMark. In addition to the annotation marks,
each forbidden structure mark has a C<ACTION> field defining the
action to carry out when the mark is identified (value C<split> or
C<delete>), and a C<SPLIT_AFTER> field address the word after which
the split action will be done.

=head1 METHODS

=head2 new()

    new($form);

The method creates and retuens a new object for a forbidden structure
mark C<$form> as it appears in the annotated corpus. C<$form> is in a
specific internal format.

=head2 parse()

    parse($form);

The method parses the forbiddent strcuture mark C<$form>, and returns
its identifier, the action to carry out, in the case of a split
action, the word address which is used to split, and the type of mark
(C<opener> if the starting mark, and C<closer> if it is the ending
mark).

=head2 isOpener()

    isOpener();

The method indicates if the mark is an opener, that is a mark
indicating the beginning of a forbidden structure. The method returns
1 if the mark is an opener.

=head2 isCloser()

    isCloser();

The method indicates if the mark is a closer, that is a mark
indicating the end of a forbidden structure. The method returns 1 if
the mark is a closer.


=head2 getAction()

    getAction();

The method returns the action associated to the mark.

=head2 getSplitAfter()

    getSplitAfter();

The method returns the word address where split action will be applyied.

=head2 isActionSplit()

    isActionSplit();

The method indicates if the action is a split action (1 if yes, 0 if not).

=head2 isActionDelete()

    isActionDelete();

The method indicates if the action is a delete action (1 if yes, 0 if not).


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
