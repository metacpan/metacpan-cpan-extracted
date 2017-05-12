package Lingua::Ogmios::Annotations::Token;

use Lingua::Ogmios::Annotations::Element;
use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::Annotations::Element);

sub new
{
    my ($class, $fields) = @_;
    if (!defined $fields->{'content'}) {
	die("content is not defined");
    }
    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    my $token = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'content'},
				   }
	);

    
    if (!defined $fields->{'type'}) {
	die("type is not defined");
    }
    if (!defined $fields->{'from'}) {
	die("from is not defined");
    }
    if (!defined $fields->{'to'}) {
	die("to is not defined");
    }

    bless ($token,$class);
    $token->setContent($fields->{'content'});
    $token->setType($fields->{'type'});
    $token->setFrom($fields->{'from'});
    $token->setTo($fields->{'to'});
    
    return $token;
}

sub getContent {
    my ($self) = @_;

#     return($self->getForm);
     return($self->{'content'});
}

sub setContent {
    my ($self, $content) = @_;

#     $self->setForm($content);
     $self->{'content'}=$content;
}

sub setType {
    my ($self, $type) = @_;

    $self->{'type'} = $type;
}

sub setFrom {
    my ($self, $from) = @_;

    $self->{'from'} = $from;

}

sub setTo {
    my ($self, $to) = @_;

    $self->{'to'} = $to;
}

sub getType {
    my ($self) = @_;

    return($self->{'type'});
}

sub isType {
    my ($self, $type) = @_;

    return($self->getType eq $type);
}

sub isSep {
    my ($self) = @_;

    return($self->isType('sep'));
}

sub isSymb {
    my ($self) = @_;

    return($self->isType('symb'));
}

sub isAlpha {
    my ($self) = @_;

    return($self->isType('alpha'));
}

sub isNum {
    my ($self) = @_;

    return($self->isType('num'));
}

sub getFrom {
    my ($self) = @_;

    return($self->{'from'});

}

sub getTo {
    my ($self) = @_;

    return($self->{'to'});
}


sub printXML {
    my ($self, $order) = @_;

    print $self->XMLout($order);
}

sub XMLout {
    my ($self, $order) = @_;

    return($self->SUPER::XMLout("token", $order));
}

# sub before {
#     my ($self, $token2) = @_;

#     return($self->
# }

sub getElementFormList {
    my ($self) = @_;

#     warn $self->getContent . "\n";

    return($self->getContent);

}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Token - Perl extension for the token annotations

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

