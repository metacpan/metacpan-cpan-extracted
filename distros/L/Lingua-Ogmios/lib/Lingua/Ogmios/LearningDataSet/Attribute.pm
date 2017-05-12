package Lingua::Ogmios::LearningDataSet::Attribute;

use strict;
use warnings;

our $VERSION='0.1';

sub new {
    my $class = shift;
    my $fields = shift;

    my $attribute = {
	'index' => -1,
	'name' => $fields->{name},
	'prefix' => $fields->{prefix},
	'type' => $fields->{type},
	'weight' => $fields->{weight},
	'comment' => $fields->{comment},
	'value' => $fields->{value},
    };

    bless($attribute, $class);
    
    return($attribute);
}

sub index {
    my $self = shift;

    if (@_) {
	$self->{'index'} = shift;
    }
    return($self->{'index'});
}

# sub set_subname {
#     my ($self) = @_;

#     $self->{'subname'} = $self->{'name'};
#     $self->{'subname'} =~ s/^$self->{'weight'}//;

#     return($self->{'subname'});

# }

sub value {
    my ($self) = @_;

    return($self->{'value'});

}

sub name {
    my $self = shift;

    if (@_) {
	$self->{'name'} = shift;
    }
    return($self->{'name'});
}

sub prefix {
    my $self = shift;

    if (@_) {
	$self->{'prefix'} = shift;
    }
    return($self->{'prefix'});
}

sub comment {
    my $self = shift;

    if (@_) {
	$self->{'comment'} = shift;
    }
    return($self->{'comment'});
}

sub type {
    my $self = shift;

    if (@_) {
	$self->{'type'} = shift;
    }
    return($self->{'type'});
}

sub weight {
    my $self = shift;

    if (@_) {
	$self->{'weight'} = shift;
    }
    return($self->{'weight'});
}

sub getARFF {
    my $self = shift;

    my $arffString;

    $arffString  = "% " . $self->index . ": " . $self->comment . "\n";
    $arffString .= '@ATTRIBUTE ' . $self->name . " ";
    if (ref($self->type) eq "ARRAY") {
	$arffString .= '{'. join(",", @{$self->type}) . '}';
    } else {
	$arffString .= $self->type;
    }

    # if (defined $self->weight) {
	
    # }
    return($arffString);
    
}

sub getSVM {
    my $self = shift;

    return("");
}

=head1 NAME

Lingua::Ogmios::LearningDataSet::Attribute - Perl extension for managing the learning attributes

=head1 SYNOPSIS

use Lingua::Ogmios::LearningDataSet::Attribute;

my %config = Lingua::Ogmios::LearningDataSet::Attribute::load_config($rcfile);

$yatea = Lingua::Ogmios::LearningDataSet::Attribute->new($config{"OPTIONS"}, \%config);

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
