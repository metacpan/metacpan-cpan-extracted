package Lingua::Ogmios::LearningDataSet::Data;


use strict;
use warnings;

our $VERSION='0.1';

sub new {

    my $class = shift;
    my $fields = shift;


    my $data = {
	'values' => $fields->{values},
	'type' => $fields->{type},
	'weight' => $fields->{weight},
	'countVal' => 0,
	'class' => $fields->{class},
	'comment' => $fields->{comment},
	'qid' => $fields->{qid},
    };

    bless($data, $class);

    if (!defined $data->type) {
	$data->type('normal');
    }

    if (defined $data->values) {
	$data->countVal(scalar(@{$data->values}));
    } else {
	$data->{values} = [];
    }

    if (defined $fields->{"countVal"}) {
	$data->countVal($fields->{"countVal"});
    }

    return($data);
}

sub weight {
    my $self = shift;

    if (@_) {
	$self->{'weight'} = shift;
    }
    return($self->{'weight'});
}

sub comment {
    my $self = shift;

    if (@_) {
	$self->{'comment'} = shift;
    }
    return($self->{'comment'});
}

sub qid {
    my $self = shift;

    if (@_) {
	$self->{'qid'} = shift;
    }
    return($self->{'qid'});
}

sub class {
    my $self = shift;

    if (@_) {
	$self->{'class'} = shift;
    }
    return($self->{'class'});
}

sub isNormal {
    my ($self) = @_;

    if ($self->type eq "normal") {
	return(1);
    } else {
	return(0);
    }
}

sub isSparse {
    my ($self) = @_;

    if ($self->type eq "sparse") {
	return(1);
    } else {
	return(0);
    }
}


sub type {
    my $self = shift;

    if (@_) {
	$self->{'type'} = shift;
    }
    return($self->{'type'});
}

sub countVal {
    my $self = shift;

    if (@_) {
	$self->{'countVal'} = shift;
    }
    return($self->{'countVal'});
}

sub values {
    my $self = shift;

    if (@_) {
	my $values_ref = shift;
	push @{$self->{'values'}}, @$values_ref;
	if (defined $self->values) {
	    $self->countVal(scalar(@{$self->values}));
	}

    }
    return($self->{'values'});
}



sub incr_value {
    my $self = shift;
    my $index = shift;

    if ($index >= $self->countVal) {
	warn "\nindex ($index) out of range (countVal=" . $self->countVal . " - a)\n";
    }

    $self->values->[$index]++;
    return($self->values->[$index]);
}


sub value {
    my $self = shift;
    my $index = shift;

    if ($index >= $self->countVal) {
	warn "\nindex ($index) out of range (countVal=" . $self->countVal . " - b)\n";
    }

    if (@_) {
	$self->values->[$index] = shift;
    }
    return($self->values->[$index]);
}


sub getARFF {
    my ($self) = @_;

    my $i;
    my $arffString = "";

    if (defined $self->comment) {
	$arffString .= "% " . $self->comment . "\n";
    }

    if ($self->isNormal) {
	$arffString .= join(',',@{$self->values}) . ",";
	if (defined $self->class) {
	    $arffString .= $self->class;
	} else {
	    $arffString .= "?"
	}
    }

    if ($self->isSparse) {
	$arffString .= '{';
	for($i=0;$i < $self->countVal;$i++) {
	    if (defined $self->values->[$i]) {
		#warn $self->values->[$i] . "($i)\n";
		$arffString .= "$i " . $self->values->[$i] . ", ";
	    }
	}
	$arffString .= $self->countVal . " ";
	if (defined $self->class) {
	    $arffString .= $self->class;
	} else {
	    $arffString .= "?"
	}
	$arffString .= '}';
    }


    return($arffString);
}

sub getSVM {
    my $self = shift;
    my $classes = shift;
    my $printComments = shift;
    my $svmString;
    my $i;

    if (((!defined $printComments) || ($printComments == 1)) && (defined $self->comment)) {
	$svmString = $self->comment . "\n";
    }
    if (defined $self->class) {
	# warn "====> " . $self->class . ";\n";
	if (scalar(keys %$classes) == 1) {
	    if (exists $classes->{$self->class}) {
		$svmString .= "+1 ";
	    } else {
		$svmString .= "-1 ";
	    }
	} else {
	    # warn "==> $classes\n";
	    # for my $c (keys(%{$classes})) {
	    # 	warn "$c : " . $classes->{$c} . "\n";
	    # }
	    # warn $self->class . "\n";
	    if (exists $classes->{$self->class}) {
		$svmString .= $classes->{$self->class} . " ";
	    }
	}
    } else {
	$svmString .= "0 ";
    }
    # warn "$svmString\n";
    if (defined $self->qid) {
	$svmString .= "qid:" . $self->qid . " ";
    }

    for($i=0;$i < $self->countVal;$i++) {
	if (defined $self->values->[$i]) {
	    $svmString .= ($i+1) . ":" . $self->values->[$i] . " ";
	}
    }
    return($svmString);
}


=head1 NAME

Lingua::Ogmios::LearningDataSet::Data - Perl extension for managing the learning data 

=head1 SYNOPSIS

use Lingua::Ogmios::LearningDataSet::Data;

my %config = Lingua::Ogmios::LearningDataSet::Data::load_config($rcfile);

$yatea = Lingua::Ogmios::LearningDataSet::Data->new($config{"OPTIONS"}, \%config);

$yatea->termExtraction($corpus);


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
