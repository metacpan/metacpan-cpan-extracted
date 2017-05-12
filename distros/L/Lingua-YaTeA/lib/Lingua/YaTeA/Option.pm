package Lingua::YaTeA::Option;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$name,$value) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{NAME} = $name;
    $this->{VALUE} = $value;
    return $this;
}

sub getName
{
    my ($this) = @_;
    return $this->{NAME};
}


sub getValue
{
    my ($this) = @_;
    return $this->{VALUE};
}

sub update
{
    my ($this,$new_value,$message_set,$display_language) = @_;
    my $old_value = $this->getValue;
    $this->{VALUE} = $new_value;
    if(defined $message_set)
    {
	print STDERR "WARNING: " . $this->getName . ": " . $message_set->getMessage('OPTION_VALUE_UPDATE')->getContent($display_language) . "\"" . $new_value . "\" (";
	print STDERR $message_set->getMessage('OLD_OPTION_VALUE')->getContent($display_language) . "\"". $old_value . "\")\n";
    } 
}

1;

__END__

=head1 NAME

Lingua::YaTeA::Option - Perl extension for option of the term extraction process

=head1 SYNOPSIS

  use Lingua::YaTeA::Option;
  Lingua::YaTeA::Option->new($name, $value);

=head1 DESCRIPTION

The module implements the option used by the term extractor. Options
are used to define the term extraction process.

=head1 METHODS


=head2 new()

    new($name,$value);

This method creates a Option object and sets its fields C<NAME> and
C<VALUE> with the variable C<name> and C<$value>.

=head2 getName()

    getName();

The method returns the name of the option.

=head2 getValue()

    getValue();

The method returns the value of the option.

=head2 update()

    update($new_value,$message_set,$display_language);

The method updates the value of the option with the new value
C<$new_value>.

The variables C<$message_set> and C<$display_language> are used for
displaying a warning or error message.


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
