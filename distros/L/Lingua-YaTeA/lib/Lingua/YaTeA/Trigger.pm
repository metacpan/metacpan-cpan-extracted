package Lingua::YaTeA::Trigger;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$type,$form) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{TYPE} = $type;
    $this->{FORM} = $form;
    $this->{FS} = [];
    return $this;
}

sub addFS
{
    my ($this,$fs) = @_;
    push @{$this->{FS}}, $fs;
}

sub getType
{
    my ($this) = @_;
    return $this->{TYPE};
}

sub getForm
{
    my ($this) = @_;
    return $this->{FORM};
}

1;

__END__

=head1 NAME

Lingua::YaTeA::Trigger - Perl extension for a trigger.

=head1 SYNOPSIS

  use Lingua::YaTeA::Trigger;
  Lingua::YaTeA::Trigger->new();


=head1 DESCRIPTION

This module represents a trigge. Each trigger contains three fields:
C<TYPE>, C<FORM> and C<FS>. The field C<TYPE> contains the type of the
trigger. The field C<FORM> contains the form of the trigger. The field
C<FS> contains an array of forbidden structures defining the trigger.



=head1 METHODS


=head2 new()

    new($type,$form);

This method creates a trigger with the type C<$type> and the form
C<$form>. The forbidden structure field remains empty.

=head2 addFS()

    addFS($fs);

The method adds the forbidden structure C<$fs> in the related field.


=head2 getType()

    getType();

This method returns the type of the trigger.

=head2 getForm()

    getForm();

This method returns the form of the trigger.

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
