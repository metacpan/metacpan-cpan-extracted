package MDOM::Assignment;

use strict;
use warnings;

#use Smart::Comments;
use base 'MDOM::Node';
use MDOM::Util qw( trim_tokens );

sub lhs ($) {
    my ($self) = @_;
    $self->_parse if !defined $self->{op};
    my $tokens = $self->{lhs};
    wantarray ? @$tokens : $tokens;
}

sub rhs ($) {
    my ($self) = @_;
    $self->_parse if !defined $self->{op};
    my $tokens = $self->{rhs};
    wantarray ? @$tokens : $tokens;
}

sub op {
    my ($self) = @_;
    $self->_parse if !defined $self->{op};
    $self->{op};
}

sub _parse ($) {
    my ($self) = @_;
    my @elems = $self->elements;
    ### Assignment elems: @elems
    my (@lhs, @rhs, $op);
    for my $elem (@elems) {
        if (!$op) {
            if ($elem->class eq 'MDOM::Token::Separator') {
                $op = $elem;
            } else {
                push @lhs, $elem;
            }
        } elsif ($elem->class eq 'MDOM::Token::Comment') {
            last;
        } else {
            push @rhs, $elem;
        }
    }
    trim_tokens(\@lhs);
    pop @rhs if $rhs[-1] eq "\n";
    shift @rhs if $rhs[0]->class eq 'MDOM::Token::Whitespace';
    $self->{lhs} = \@lhs;
    $self->{rhs} = \@rhs;
    $self->{op}  = $op;
}

1;

__END__

=encoding utf-8

=head1 NAME

MDOM::Assignment - DOM Assignment Node for Makefiles

=head1 DESCRIPTION

An assignment node.

=head2 Accessors

=over 4

=item lhs

left hand side of assignment

=item rhs

right hand side of assignment

=item op

assignment operator

=back

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006-2014 by Yichun "agentzh" Zhang (章亦春).

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MDOM::Document>, L<MDOM::Document::Gmake>, L<PPI>, L<Makefile::Parser::GmakeDB>, L<makesimple>.

