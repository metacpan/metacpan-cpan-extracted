package MDOM::Rule::Simple;

use strict;
use warnings;

#use Smart::Comments;
use base 'MDOM::Rule';
use MDOM::Util qw( trim_tokens );

sub targets {
    my ($self) = @_;
    $self->_parse if !$self->{colon};
    my $tokens = $self->{targets};
    wantarray ? @$tokens : $tokens;
}

sub normal_prereqs {
    my ($self) = @_;
    $self->_parse if !$self->{colon};
    my $tokens = $self->{normal_prereqs};
    wantarray ? @$tokens : $tokens;
}

sub order_prereqs {
    my ($self) = @_;
    $self->_parse if !$self->{colon};
    my $tokens = $self->{order_prereqs};
    wantarray ? @$tokens : $tokens;
}
sub colon {
    my ($self) = @_;
    $self->_parse if !$self->{colon};
    $self->{colon};
}

sub command {
    my ($self) = @_;
    $self->_parse if !$self->{colon};
    $self->{command};
}

sub _parse {
    my ($self) = @_;
    my @elems = $self->elements;
    my (@targets, $colon, @normal_prereqs, @order_prereqs, $command);
    my $prereqs = \@normal_prereqs;
    ## @elems
    for my $elem (@elems) {
        if (!$colon) {
            if ($elem->class eq 'MDOM::Token::Separator') {
                $colon = $elem->content;
            } else {
                push @targets, $elem;
            }
        } elsif ($elem->class eq 'MDOM::Token::Comment') {
            last;
        } elsif ($elem->class eq 'MDOM::Command') {
            $command = $elem;
            last;
        } elsif ($elem->class eq 'MDOM::Token::Bare' and
                 $elem->content eq '|') {
            $prereqs = \@order_prereqs;
        } else {
            push @$prereqs, $elem;
        }
    }
    trim_tokens(\@targets);
    trim_tokens(\@normal_prereqs);
    trim_tokens(\@order_prereqs);
    $self->{targets} = \@targets;
    $self->{colon}   = $colon;
    $self->{normal_prereqs} = \@normal_prereqs;
    $self->{order_prereqs} = \@order_prereqs;
    $self->{command} = $command;
    ### $self
}

1;

__END__

=encoding utf-8

=head1 NAME

MDOM::Rule::Simple - DOM simple rule node for Makefiles

=head1 DESCRIPTION

A simple rule node.

=head2 Accessors

=over 4

=item colon

=item command

=item normal_prereqs

=item order_prereqs

=item targets

=back

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006-2014 by Yichun "agentzh" Zhang (章亦春).

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MDOM::Document>, L<MDOM::Document::Gmake>, L<PPI>, L<Makefile::Parser::GmakeDB>, L<makesimple>.

