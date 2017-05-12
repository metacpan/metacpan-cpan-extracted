package Lingua::YaTeA::ForbiddenStructureAny;
use Lingua::YaTeA::ForbiddenStructure;
use strict;
use warnings;

our @ISA = qw(Lingua::YaTeA::ForbiddenStructure);
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$infos_a) = @_;
    my ($form,$reg_exp) = $class->parse($infos_a->[0]);
    my $this = $class->SUPER::new($form);
    bless ($this,$class);
    $this->{ACTION} = $infos_a->[2];
    $this->{SPLIT_AFTER} = $this->setSplitAfter($infos_a);
    $this->{REG_EXP} = $reg_exp;
    return $this;
}


# TODO
sub setSplitAfter
{
    my ($this,$infos_a) = @_;
    if ($this->{ACTION} eq "split")
    {
	return $infos_a->[3] - 1;
    }
    return "";
}

sub parse
{
    my ($class,$string) = @_;
    my @elements = split / /, $string;
    my $element;
    my $forbidden_tag = "\(\\n\\<\\/\?\(FORBIDDEN\|FRONTIER\)\[\^\>\]\+\>\)\*";
    my $reg_exp = "";
    my $form;
    
    foreach $element (@elements){
	$element =~ /^([^\\]+)\\(.+)$/;
	if(!defined $2)
	{
	    warn "FS error:" . $string. "\n";
	}
	if ($2 eq "IF"){
	    $reg_exp .= $forbidden_tag . "\?\\n" . quotemeta($1)."\\t\[\^\\t\]\+\\t\[\^\\t\]\+" . $forbidden_tag;
	}
	else{
	    if ($2 eq "POS"){
		$reg_exp .= $forbidden_tag . "\?\\n\[\^\\t\]\+\\t" . quotemeta($1)."\\t\[\^\\t\]\+". $forbidden_tag;
	    }
	    else{
		if ($2 eq "LF"){
		    $reg_exp .= $forbidden_tag . "\?\\n\[\^\\t\]\+\\t\[\^\\t\]\+\\t".quotemeta($1). $forbidden_tag;
		}
	    }
	}
	$form .= $1 . " ";
    }
    $reg_exp .= "\\n";
    $form =~ s/ $//;
    return ($form,$reg_exp);
}

sub getAction
{
    my ($this) = @_;
    return $this->{ACTION};
}

sub getRegExp
{
    my ($this) = @_;
    return $this->{REG_EXP};
}

sub getSplitAfter
{
    my ($this) = @_;
    return $this->{SPLIT_AFTER};
}


1;

__END__

=head1 NAME

Lingua::YaTeA::ForbiddenStructureAny - Perl extension for forbidden
structures in any position of a chunk.

=head1 SYNOPSIS

  use Lingua::YaTeA::ForbiddenStructureAny;
  Lingua::YaTeA::ForbiddenStructureAny->new(\@infos_a);

=head1 DESCRIPTION

The module describes the forbidden structures that can be used in any
position in the chunk. This is a specialisation of the
C<Lingua::YaTeA::ForbiddenStructure> module. Three fields are added:

=over

=item *

C<ACTION>: this field defines the action (C<split> or C<delete>.


=item *

C<SPLIT_AFTER>: if the C<split> action is used, this field defines the
words, lemmas, tags of patterns that will be used to perform the
splitting process.


=item *

C<REG_EXP>: this field contains the regular expression corresponding
to the pattern of the forbidden structure.



=back


=head1 METHODS

=head2 new()

    new($infos_a)

The method creates a forbidden structure that can be found in any
position. The forbidden structure is defined from the array given by
reference C<$infos_a>. All fields are set.

=head2 setSplitAfter()

    setSplitAfter($infos_a)

This method return the value hat will be set in the SPLIT_AFTER field
if necessary.



=head2 parse()

    parse($string);

The method parses the pattern of the forbidden structure C<$string>
and returns the C<$form> of the forbidden structure and the corresponding
regular expression. 

=head2 getAction()

    getAction();

The method returns the value of the C<ACTION> field.

=head2 getRegExp()

    getRegExp();

The method returns the value of the C<REG_EXPO> field.


=head2 getSplitAfter()

    getSplitAfter();

The method returns the value of the C<SPLIT_AFTER> field.

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
