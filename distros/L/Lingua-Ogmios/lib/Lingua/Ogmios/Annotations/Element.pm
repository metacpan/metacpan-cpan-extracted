package Lingua::Ogmios::Annotations::Element;

use strict;
use warnings;


sub new
{
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	die("id is not defined");
    }

    my $element = {
	'id' => $fields->{'id'},
	'log_id' => undef,
	'form' => undef,
	'next' => undef,
	'previous' => undef,
    };
    bless ($element,$class);

    if (defined $fields->{'log_id'}) {
	$element->setLogId($fields->{'log_id'});
    }

    if (defined $fields->{'form'}) {
	$element->setForm($fields->{'form'});
    }

    return $element;
}

sub next {
    my $self = shift;

    $self->{'next'} = shift if @_;
    return($self->{'next'});
}

sub previous {
    my $self = shift;

    $self->{'previous'} = shift if @_;
    return($self->{'previous'});
}

sub equals {
    my ($self, $element) = @_;

    if ($self->getId == $element->getId) {
	return(1);
    } else {
	return(0);
    }
}

sub _getField {
    my ($self, $field) = @_;

    return($self->{$field});
}

sub _setField {
    my ($self, $field, $value) = @_;

    $self->{$field} = $value;
}

sub getId {
    my ($self) = @_;

    return($self->{'id'});
}

sub setId {
    my ($self, $id) = @_;

    $self->{'id'} = $id;
}

sub getLogId {
    my ($self) = @_;

    return($self->{'log_id'});
}

sub setLogId {
    my ($self, $log_id) = @_;

    $self->{'log_id'} = $log_id;
}

sub getForm {
    my ($self) = @_;

    return($self->{'form'});
}

sub setForm {
    my ($self, $form) = @_;

#     $self->{'form'} = $self->_xmlencode($form);
    $self->{'form'} = $form;
}


sub print {
    my ($self, $fh) = @_;
    if (!defined $fh) {
	$fh = \*STDERR
    }
    my $field;
    foreach $field (keys %$self) {
	if (defined $self->{$field}) {
	    print "$field => " . $self->{$field} . "\n";
	}
    }
    return(0);
}


sub printXML {
    my ($self, $name, $order) = @_;

    print $self->XMLout($name, $order);
}

sub _XMLoutField {
    my ($self, $field, $field_content, $shift) = @_;

    my $str;

    my $elt;
    my $internal_field;
    my $position;


    if (!defined($shift)) {
	$shift = "\t\t";
    }

    # warn "$field - " . ref($field_content) . "\n";
    if (ref($field_content) eq "ARRAY") {
	$position = index($field, "list_");
	if ($position == 0) {
	    $str .= "$shift<$field>\n";
	    $internal_field = substr($field, $position + 5);
	    foreach $elt (@{$field_content}) {
		$str .= $self->_XMLoutField($internal_field, $elt, "$shift\t");
	    }
	    $str .= "$shift</$field>\n";
	} else {
	    foreach $elt (@{$field_content}) {
		$str .= $self->_XMLoutField($field, $elt, "$shift");
	    }
	}
    }

    if (ref($field_content) eq "HASH") {
	$str .= "$shift<$field>\n";
	if (defined($internal_field = $field_content->{"reference"})) {
	    foreach $elt (@{$field_content->{$field_content->{"reference"}}}) {
		$str .= $self->_XMLoutField($internal_field, $elt, "$shift\t");
	    }
	} else {
	    if ($field eq "weights") {
		foreach $elt (keys %$field_content) {
		    # if (!defined ($field_content->{$elt})) {
		    # 	warn "$elt\n";
		    # }
		    $str .= "$shift\t<weight name=\"$elt\">";
		    $str .= $field_content->{$elt} . "</weight>\n";
		}
	    } else {
		foreach $elt (keys %$field_content) {
# 		    $str .= "$shift<$elt>" . $field_content->{$elt} . "</$elt>\n";
		    $str .= $self->_XMLoutField($elt,$field_content->{$elt},"$shift\t"); #"$shift<$elt>" . $field_content->{$elt} . "</$elt>\n";
		}
	    }
	}
	    $str .= "$shift</$field>\n";
    }

    if (index(ref($field_content), "Lingua::Ogmios") > -1) {
	# warn "$field: " . $field_content->getId . "\n";
	$str .= "$shift<$field>";
#  	$str .= $field_content->getId . " = " . $field_content;
 	$str .= $field_content->getId;
	$str .= "</$field>\n";
    }

    if (ref($field_content) eq "") {
 	$str .= "$shift<$field>";
	$str .= $field_content;
 	$str .= "</$field>\n";
    }
    return($str);
}

sub XMLout {
    my ($self, $name, $order) = @_;
    my $field;

    my $str;

    my $elt;
    my $internal_field;
    my $position;

    # warn "$name\n";
    $str = "\t<$name>\n";
    foreach $field (@$order) {
	# warn "-->$field\n";
	if (defined $self->_getField($field)) {
	    if ((defined(ref($self->_getField($field)))) && (ref($self->_getField($field)) ne "")) {
		$str .= $self->_XMLoutField($field, $self->_getField($field), "\t\t") ;		
	    } else {
		$str .= "\t\t<$field>" . $self->_xmlencode($self->_getField($field)) . "</$field>\n";
	    }
	}
    }
    $str .= "\t</$name>\n";
    return($str);
}

sub XMLout_orig {
    my ($self, $name, $order) = @_;
    my $field;

    my $str;

    my $elt;
    my $internal_field;
    my $position;

    $str = "\t<$name>\n";
    foreach $field (@$order) {
	if (defined $self->_getField($field)) {
	    if (ref $self->_getField($field) eq "ARRAY") {
		$str .= "\t\t<$field>";
		$position = index($field, "list_");
		if ($position == 0) {
		    $str .= "\n";
		    $internal_field = substr($field, $position + 5);
		    foreach $elt (@{$self->_getField($field)}) {
			$str .= "\t\t\t<$internal_field>" . $elt->getId . "</$internal_field>\n";
		    }
		    $str .= "\t\t";
		} else {
		    $str .= $self->_getField($field)->[0] ;
		    
		}
		$str .= "</$field>\n";
	    } else {
		if (ref $self->_getField($field) eq "HASH") {
		    $str .= "\t\t<$field>";
# 		    $position = index($field, "list_");
# 		    if ($position == 0) {
		    $str .= "\n";
		    $internal_field = $self->_getField($field)->{"reference"};
		    foreach $elt (@{$self->_getField($field)->{$self->_getField($field)->{"reference"}}}) {
			$str .= "\t\t\t<$internal_field>" . $elt->getId . "</$internal_field>\n";
		    }
		    $str .= "\t\t";
		    $str .= "</$field>\n";
		} else {
		    $str .= "\t\t<$field>" . $self->_xmlencode($self->_getField($field)) . "</$field>\n";
		}
	    }
	}
    }
    $str .= "\t</$name>\n";
    return($str);
}

sub _xmldecode { # to be optimized
    my ($self, $string) = @_;

    $string =~ s/&amp;/&/go;
    $string =~ s/&quot;/\"/og;
    $string =~ s/&apos;/\'/og;
    $string =~ s/&lt;/</og;
    $string =~ s/&gt;/>/og;

    return($string);
}

sub _xmlencode { # to be optimized
    my ($self, $string) = @_;

    $string =~ s/&/&amp;/og;
    $string =~ s/\"/&quot;/og;
    $string =~ s/\'/&apos;/og;
    $string =~ s/</&lt;/og;
    $string =~ s/>/&gt;/og;
    
    return($string);
}

sub getFrom {
    my ($self) = @_;

    return($self->start_token->getFrom);
}

sub getTo {
    my ($self) = @_;

    return($self->end_token->getFrom);
}

sub isBefore {
    my ($self, $element) = @_;

    if ($self->getTo < $element->getFrom) {
	return(1);
    }
    return(0);
}

sub isAfter {
    my ($self, $element) = @_;

    if ($element->getTo < $self->getFrom) {
	return(1);
    }
    return(0);
}


sub contains {
    my ($self, $element) = @_;

    # warn "------------------------------------------------------------------------\n";
    # warn $element->getForm . "\n";
    my $offset_start;
    my $offset_end;
    if (ref($self) eq "Lingua::Ogmios::Annotations::Token") {
	$offset_start = $self->getFrom;
	$offset_end = $self->getTo;
    } else {
	$offset_start = $element->start_token->getFrom;
	$offset_end = $element->end_token->getTo;
    }
    # warn "\t$offset\n\n";

    if (($self->start_token->getFrom <= $offset_start) &&
	($offset_end <= $self->end_token->getTo)) {
#	    warn "OK\n";
	return(1);
    }
    return(0);
}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Element - Perl extension for the annotations (generic module)

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

