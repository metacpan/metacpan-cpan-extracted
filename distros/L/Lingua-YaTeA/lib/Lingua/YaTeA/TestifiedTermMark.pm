package Lingua::YaTeA::TestifiedTermMark;
use strict;
use warnings;
use Lingua::YaTeA::AnnotationMark;


our @ISA = qw(Lingua::YaTeA::AnnotationMark);
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$form) = @_;
    my ($frontier_id,$testified_id,$type) = $class->parse($form);
    my $this = $class->SUPER::new($form,$frontier_id,$type);
    bless ($this,$class);
    $this->{TESTIFIED_ID} = $testified_id;
    $this->{START} = (); # should be 0
    $this->{END} = ();  # should be 0
    return $this;
}


sub getTestifiedID
{
    my ($this) = @_;
    return $this->{TESTIFIED_ID};
}

sub isOpener
{
    my ($this) = @_;
    if ($this->getType eq "opener")
    {
	return 1;
    }
    return 0;
}

sub isCloser
{
    my ($this) = @_;
    if ($this->getType eq "closer")
    {
	return 1;
    }
    return 0;
}

sub parse
{
    my ($class,$form) = @_;
    my $frontier_id;
    my $testified_id;
    my $type;

    # opening testified term frontier
    if ($form =~ /^\<FRONTIER ID=([0-9]+) TT=([0-9]+)/)
    {
	$frontier_id = $1;
	$testified_id = $2;
	$type = "opener";
    }
    # closing testified term frontier
    else
    {
	if ($form =~ /^\<\/FRONTIER ID=([0-9]+) TT=([0-9]+)/)
	{
	    $frontier_id = $1;
	    $testified_id = $2;
	    $type = "closer";
	}
	else
	{
	    die "balise invalide :" . $form;
	}
    }
    return ($frontier_id,$testified_id,$type);
}

sub getStart
{
    my ($this) = @_;
    return $this->{START};  
}

sub getEnd
{
    my ($this) = @_;
    return $this->{END};  
}

1;

__END__

=head1 NAME

Lingua::YaTeA::TestifiedTermMark - Perl extension for marks of testified terms

=head1 SYNOPSIS

  use Lingua::YaTeA::TestifiedTermMark;
  Lingua::YaTeA::TestifiedTermMark->new();

=head1 DESCRIPTION

The module implements the marks indicating testified terms in the
document structures. Each mark delimited with a start offset
(C<START>) and a end offset (C<END>). An identifier C<TESTTIED_ID> is
associated to the mark. The module inherits of the module
C<Lingua::YaTeA::AnnotationMark>.

=head1 METHODS

=head2 new()

    new($form);

The method creates a new mark of testitied term from the form C<$form>.

=head2 getTestifiedID()

    getTestifiedID();

The method returns the identifier of the mark.

=head2 isOpener()

    isOpener();

The method returns 1 if the mark is an opening mark, otherwise 0.

=head2 isCloser()

    isCloser();

The method returns 1 if the mark is an closing mark, otherwise 0.


=head2 parse()

    parse($form);

The method parses the form C<$form> and returns an array containing
three elements: the identifier of the frontier, the identifier of the
testitied term and the type of the mark (C<opener> or C<closer>).

=head2 getStart()

    getStart();

The method returns the start offset of the mark.

=head2 getEnd()

    getEnd();

The method returns the end offset of the mark.


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
