package Lingua::Ogmios::Annotations::Section;

use Lingua::Ogmios::Annotations::Element;
use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::Annotations::Element);

sub new
{
    my ($class, $fields) = @_;
    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    my $section = $class->SUPER::new({
	'id' => $fields->{'id'},
				   }
	);

    if (!defined $fields->{'from'}) {
	die("from is not defined");
    }
    if (!defined $fields->{'to'}) {
	die("to is not defined");
    }

    bless ($section,$class);

    $section->setFrom($fields->{'from'});
    $section->setTo($fields->{'to'});

    if (defined $fields->{'title'}) {
	$section->title($fields->{'title'});
    }
    if (defined $fields->{'type'}) {
	$section->type($fields->{'type'});
    }
    if (defined $fields->{'rank'}) {
	$section->rank($fields->{'rank'});
    }
    if (defined $fields->{'parent_section'}) {
	$section->parent_section($fields->{'parent_section'});
    }
    if (defined $fields->{'child_sections'}) {
	$section->child_sections($fields->{'child_sections'});
    }
    
    return $section;
}


sub rank {
    my $self = shift;

    $self->{'rank'} = shift if @_;
    return $self->{'rank'};
}

sub type {
    my $self = shift;

    $self->{'type'} = shift if @_;
    return $self->{'type'};
}


sub title {
    my $self = shift;

    $self->{'title'} = shift if @_;
    return $self->{'title'};
}


sub getRank {
    my ($self) = @_;

    my $i = 0;

    if (defined $self->parent_section) {
	for($i = 0; $i < scalar(@{$self->parent_section->child_sections}); $i++) {
	    if ($self->getId == $self->parent_section->child_sections->[$i]->getId) {
		return($i);
	    }
	}
    }
    return(-1);

}

sub isTitle {
    my $self = shift;

    if ((defined $self->parent_section) && (defined $self->parent_section->{'title'})
	&& ($self->rank == 0)) {
	return(1);
    }
    return(0);

}

sub parent_section {
    my $self = shift;

    $self->{'parent_section'} = shift if @_;
    return $self->{'parent_section'};
}

sub child_sections {
    my $self = shift;

    $self->{'child_sections'} = shift if @_;
    return $self->{'child_sections'};
}

sub has_child_sections {
    my $self = shift;

    return((defined $self->child_sections) && (scalar(@{$self->child_sections}) > 0));
}

sub setFrom {
    my ($self, $from) = @_;

    $self->{'from'} = $from;

}

sub setTo {
    my ($self, $to) = @_;

    $self->{'to'} = $to;
}

sub getFrom {
    my ($self) = @_;

    return($self->{'from'});

}

sub getFromOffset {
    my ($self) = @_;

    if (ref($self->{'from'}) eq "Lingua::Ogmios::Annotations::Token") {
	return($self->{'from'}->getFrom);
    } else {
	return($self->{'from'});
    }

}

sub getToOffset {
    my ($self) = @_;

    if (ref($self->{'to'}) eq "Lingua::Ogmios::Annotations::Token") {
	return($self->{'to'}->getTo);
    } else {
	return($self->{'to'});
    }

}

sub getTo {
    my ($self) = @_;

    return($self->{'to'});
}


sub getForm {

    my ($self, $tokenLevel) = @_;

#     warn "ref start: " . ref($self->getFrom) . "\n";
#     warn "ref to: " . ref($self->getTo) . "\n";
    my $token;
    my $start_token;
    my $end_token;

    my $sectionForm;

    if (ref($self->getFrom) eq "Lingua::Ogmios::Annotations::Token") {
	# from is a token
	$start_token = $self->getFrom;
    } else {
	# from is a offset
	$start_token = $tokenLevel->getElementByOffset($self->getFrom)->[0];
    }
    if (ref($self->getTo) eq "Lingua::Ogmios::Annotations::Token") {
	# To is a token
	$end_token = $self->getTo;
    } else {
	# to is a offset
	$end_token = $tokenLevel->getElementByOffset($self->getTo)->[0];
    }

    $token = $start_token;
    $sectionForm = $token->getContent;    
    while(!$token->equals($end_token)) {
	$token = $token->next;
	$sectionForm .= $token->getContent;
	
    };
#     warn "$sectionForm\n";
    return($start_token, $end_token, $sectionForm);

}

sub firstDefinedTitle {
    my ($self) = @_;

    if (defined $self->title) {
	return($self->title);
    } else {
	if (defined $self->parent_section) {
	    return($self->parent_section->firstDefinedTitle);
	} else {
	    return(undef);
	}
    }

}

sub XMLout {
    my ($self, $order) = @_;

    return($self->SUPER::XMLout("section", $order));
}


sub tokenIsInside {
    my ($self, $token) = @_;

    if (($self->getFromOffset < $token->getFrom) && 
	($token->getTo < $self->getToOffset)) {
	return(1);
    } else {
	return(0)
    }
}

sub reference {
    my ($self) = @_;

    my $start_token;
    my $end_token;
    my @refs;
    my $token;

    if (ref($self->getFrom) eq "Lingua::Ogmios::Annotations::Token") {
	# from is a token
	$start_token = $self->getFrom;
    } else {
	# from is a offset
	# $start_token = $tokenLevel->getElementByOffset($self->getFrom)->[0];
    }
    # warn "..\n";
    # warn $self->getTo . " : " . ref($self->getTo) . "\n";
    if (ref($self->getTo) eq "Lingua::Ogmios::Annotations::Token") {
	# To is a token
	$end_token = $self->getTo;
    } else {
	# to is a offset
	# $end_token = $tokenLevel->getElementByOffset($self->getTo)->[0];
    }
    # warn "...\n";
    if (defined $start_token) {
	$token = $start_token;
	push @refs, $token;
	while(!$token->equals($end_token)) {
	    $token = $token->next;
	    push @refs, $token;
	};
    }
    # warn "....\n";
    return(\@refs);
}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Section - Perl extension for representing the document sections

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

