package HTTP::Headers::ActionPack::PriorityList;
BEGIN {
  $HTTP::Headers::ActionPack::PriorityList::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::PriorityList::VERSION = '0.09';
}
# ABSTRACT: A Priority List

use strict;
use warnings;

use HTTP::Headers::ActionPack::Util qw[
    split_header_words
    join_header_words
];

use parent 'HTTP::Headers::ActionPack::Core::BaseHeaderList';

sub BUILDARGS { +{ 'index' => {}, 'items' => {} } }

sub BUILD {
    my ($self, @items) = @_;
    foreach my $item ( @items ) {
        $self->add( @$item )
    }
}

sub index { (shift)->{'index'} }
sub items { (shift)->{'items'} }

sub new_from_string {
    my ($class, $header_string) = @_;
    my $list = $class->new;
    foreach my $header ( split_header_words( $header_string ) ) {
        $list->add_header_value( $header );
    }
    $list;
}

sub as_string {
    my $self = shift;
    join ', ' => map {
        my ($q, $subject) = @{ $_ };
        join_header_words( $subject, q => $q );
    } $self->iterable;
}

sub add {
    my ($self, $q, $choice) = @_;
    # XXX - should failure to canonicalize be an error? or should
    # canonicalize_choice itself throw an error on bad values?
    $choice = $self->canonicalize_choice($choice)
        or return;
    $q += 0; # be sure to numify this
    $self->index->{ $choice } = $q;
    $self->items->{ $q } = [] unless exists $self->items->{ $q };
    push @{ $self->items->{ $q } } => $choice;
}

sub add_header_value {
    my $self = shift;
    my ($choice, %params) = @{ $_[0] };
    $self->add( exists $params{'q'} ? $params{'q'} : 1.0, $choice );
}

sub get {
    my ($self, $q) = @_;
    $self->items->{ $q };
}

sub priority_of {
    my ($self, $choice) = @_;
    $choice = $self->canonicalize_choice($choice)
        or return;
    $self->index->{ $choice };
}

sub iterable {
    my $self = shift;
    map {
        my $q = $_;
        map { [ $q, $_ ] } @{ $self->items->{ $q } }
    } reverse sort keys %{ $self->items };
}

sub canonicalize_choice {
    return $_[1];
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::PriorityList - A Priority List

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::PriorityList;

  # simple constructor
  my $plist = HTTP::Headers::ActionPack::PriorityList->new(
      [ 1.0 => 'foo' ],
      [ 0.5 => 'bar' ],
      [ 0.2 => 'baz' ],
  );

  # from headers
  my $plist = HTTP::Headers::ActionPack::PriorityList->new_from_string(
      'foo; q=1.0, bar; q=0.5, baz; q=0.2'
  );

=head1 DESCRIPTION

This is a simple priority list implementation, this is used to
handle the Accept-* headers as they typically will contain
values along with a "q" value to indicate quality.

=head1 METHODS

=over 4

=item C<new>

=item C<new_from_string ( $header_string )>

This accepts a HTTP header string which get parsed
and loaded accordingly.

=item C<index>

=item C<items>

=item C<add ( $quality, $choice )>

Add in a new C<$choice> with a given C<$quality>.

=item C<get ( $quality )>

Given a certain C<$quality>, it returns the various
choices available.

=item C<priority_of ( $choice )>

Given a certain C<$choice> this returns the associated
quality of it.

=item C<iterable>

This returns a list of two item ARRAY refs with the
quality as the first item and the associated choice
as the second item. These are sorted accordingly.

When two items have the same priority, they are returned
in the order that they were found in the header.

=item C<canonicalize_choice>

By default, this does nothing. It exists so that subclasses can override it.

=back

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Nelson <anelson@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
