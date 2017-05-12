package Lingua::Ogmios::Annotations::Stem;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);


# <!-- =================================================== --> 
# <!--                    STEM LEVEL                       --> 
# <!-- =================================================== --> 
# <!ELEMENT  stem_level   (log_id?, comments*, stem+)        > 
 
# <!--                    stem                             --> 
# <!ELEMENT  stem         (id, log_id?, stem_form+, 
#                          refid_word, form?)                > 
 
# <!--                    stem form                        --> 
# <!ELEMENT  stem_form    (#PCDATA)                          > 
 
sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if (!defined $fields->{'refid_word'}) { # refid_word
	die("refid_word is not defined");
    }
    if (!defined $fields->{'stem_form'}) { # stem_form
	die("stem_form is not defined");
    }
    my $stem = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($stem,$class);

    $stem->stem_form($fields->{'stem_form'});
    $stem->refid_word($fields->{'refid_word'});

    if (defined $fields->{'log_id'}) {
	$stem->setLogId($fields->{'log_id'});
    }
    return($stem);
}

sub refid_word {
    my $self = shift;

    $self->{'refid_word'} = shift if @_;
    return($self->{'refid_word'});
}

sub stem_form {
    my $self = shift;

    $self->{"stem_form"} = shift if @_;
    return($self->{"stem_form"});
}

sub setstem_form_idx {
    my ($self, $idx , $value) = @_;

    if ((defined $idx) && (defined $value)) {

	$self->stem_form->[$idx] = $value;
        return($value);
    } else {
	return(undef);
    }
}

sub add_stem_form_idx {
    my ($self, $value) = @_;

    if (defined $value) {

	push @{$self->stem_form}, $value;
        return($value);
    } else {
	return(undef);
    }
}


sub getstem_form_idx {
    my ($self, $idx) = @_;

    if (defined $idx) {
	return($self->stem_form->[$idx]);
    } else {
	return(undef);
    }
}

sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("stem", $order));
}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Stem - Perl extension for the stem annotations 

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

