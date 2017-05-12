package Lingua::Ogmios::Annotations::Sentence;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);


# <!-- =================================================== --> 
# <!--                    SENTENCE LEVEL                   --> 
# <!-- =================================================== --> 
# <!ELEMENT  sentence_level (log_id?, comments*, sentence+)  > 
 
# <!--                    sentence                         --> 
# <!ELEMENT  sentence     (id, log_id?, refid_start_token, 
#                          refid_end_token, form?)           > 
 
# <!--          Reference of the token at the beginning    --> 
# <!--          of the sentence                            --> 
# <!ELEMENT  refid_start_token 
#                         (#PCDATA)                          > 
 
# <!--               Reference of the token at the end     --> 
# <!--               of the sentence                       --> 
# <!ELEMENT  refid_end_token 
#                         (#PCDATA)                          > 
 
# <!--                     word id, part of the word       -->
# <!ELEMENT  refid_word  (#PCDATA)                           >


sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if (!defined $fields->{'refid_start_token'}) { # refid_start_token
	die("refid_start_token is not defined");
    }
    if (!defined $fields->{'refid_end_token'}) { # refid_end_token
	die("refid_end_token is not defined");
    }
    my $sentence = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($sentence,$class);

    $sentence->refid_start_token($fields->{'refid_start_token'});
    $sentence->refid_end_token($fields->{'refid_end_token'});

    if (defined $fields->{'form'}) {
	$sentence->setForm($fields->{'form'});
    }

    if (defined $fields->{'log_id'}) {
	$sentence->setLogId($fields->{'log_id'});
    }
    if (defined $fields->{'lang'}) {
	$sentence->Lang($fields->{'lang'});
    }
    return($sentence);
}

sub start_token {
    my $self = shift;

    return($self->refid_start_token);
}

sub refid_start_token {
    my $self = shift;

    $self->{refid_start_token} = shift if @_;
    return($self->{refid_start_token});
}

# sub getFrom {
#     my $self = shift;
#     return($self->{refid_start_token});
# }

sub end_token {
    my $self = shift;

    return($self->refid_end_token);
}

sub refid_end_token {
    my $self = shift;

    $self->{refid_end_token} = shift if @_;
    return($self->{refid_end_token});
}

sub lang {
    my $self = shift;

    $self->{"lang"} = shift if @_;
    return($self->{"lang"});
}

# sub getTo {
#     my $self = shift;
#     return($self->{refid_end_token});
# }


sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("sentence", $order));
}

sub reference {
    my ($self) = @_;

    my @refs;
    my $token;

    $token = $self->refid_start_token;
    push @refs, $token;
    while(!$token->equals($self->refid_end_token)) {
	$token = $token->next;
	push @refs, $token;
    };
    return(\@refs);
}


sub getWordsFromSentence {
    my ($self, $document) = @_;

    my $word;
    # my $lemma;

    # my $sentLemma = "";;
    my $token = $self->start_token;

    # my $token_prec = 0;
    my @words = ();

    if (defined $token) {
	do {
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		# $lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		push @words, $word;
		$token = $word->end_token;
		# $token_prec = 0;
	    } else {
		# $offsets{length($sentLemma)} = [$token];
		# $sentLemma .= $token->getContent;
		# $token_prec = 1;
	    }
	    if (defined $token) {
		$token = $token->next;
	    }
	} while((defined $token) && (defined $token->previous) && (!($token->previous->equals($self->end_token))));
    }
    return(\@words);
}


sub getTermsFromSentence {
    my ($self, $document) = @_;

    my $word;
    # my $lemma;

    # my $sentLemma = "";;
    my $token = $self->start_token;

    # my $token_prec = 0;
    my @terms = ();
    my @semfs;
    my $semf;

    if (defined $token) {
	do {
	    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("start_token", $token->getId)) {
		@semfs = @{$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("start_token", $token->getId)};
		# $lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		foreach $semf (@semfs) {
		    if ($semf->isTerm) {
			push @terms, $semf;
		    }
		}
	    }
	    $token = $token->next;
	} while((defined $token) && (defined $token->previous) && (!($token->previous->equals($self->end_token))));
    }
    return(\@terms);
}



1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Sentence - Perl extension for the sentence annotations

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

