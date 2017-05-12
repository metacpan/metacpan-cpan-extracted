package HTML::Widget::Filter::TrimEdges;

use warnings;
use strict;
use base 'HTML::Widget::Filter';

=head1 NAME

HTML::Widget::Filter::TrimEdges - Trim whitespaces from beginning and end of string

=head1 SYNOPSIS

    my $f = $widget->filter( 'TrimEdges', 'foo' );

=head1 DESCRIPTION

TrimEdges Filter.

=head1 METHODS

=head2 filter

=cut

sub filter {
    my ( $self, $value ) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
