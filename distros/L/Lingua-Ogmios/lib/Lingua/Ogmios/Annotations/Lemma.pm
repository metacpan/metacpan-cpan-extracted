package Lingua::Ogmios::Annotations::Lemma;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

# <!-- =================================================== --> 
# <!--                    LEMMA LEVEL                      --> 
# <!-- =================================================== --> 
# <!ELEMENT  lemma_level  (log_id?, comments*, lemma+)       > 
 
# <!--                    lemma                            --> 
# <!ELEMENT  lemma        (id, log_id?, canonical_form+, 
#                          refid_word, form?)                > 
 
# <!--              canonical form of the word             --> 
# <!--              corresponding to the lemma             --> 
# <!ELEMENT  canonical_form 
#                         (#PCDATA)                          > 

sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if (!defined $fields->{'refid_word'}) { # refid_word
	die("refid_word is not defined");
    }
    if (!defined $fields->{'canonical_form'}) { # canonical_form
	die("canonical_form is not defined");
    }
    my $lemma = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($lemma,$class);

    $lemma->canonical_form($fields->{'canonical_form'});
    $lemma->refid_word($fields->{'refid_word'});

    if (defined $fields->{'log_id'}) {
	$lemma->setLogId($fields->{'log_id'});
    }
    return($lemma);
}

sub refid_word {
    my $self = shift;

    $self->{'refid_word'} = shift if @_;
    return($self->{'refid_word'});
}

sub canonical_form {
    my $self = shift;

    $self->{"canonical_form"} = shift if @_;
    return($self->{"canonical_form"});
}

sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("lemma", $order));
}

sub reference {
    my ($self) = @_;

    return([$self->refid_word]);
}

1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Lemma - Perl extension for the annotations of lemma

=head1 SYNOPSIS

use Lingua::Ogmios::Annotations::???;

my $word = Lingua::Ogmios::Annotations::???::new($fields);


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 FIELDS

=over

=item *


=back


=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

