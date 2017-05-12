package HTML::Widget::Accessor;

use warnings;
use strict;
use base 'Class::Accessor::Chained::Fast';
use Carp qw/croak/;

*attrs = \&attributes;

=head1 NAME

HTML::Widget::Accessor - Accessor Class

=head1 SYNOPSIS

    use base 'HTML::Widget::Accessor';

=head1 DESCRIPTION

Accessor Class.

=head1 METHODS

=head2 attributes

=head2 attrs

Arguments: %attributes

Arguments: \%attributes

Return Value: $self

Arguments: none

Return Value: \%attributes

Accepts either a list of key/value pairs, or a hash-ref.

    $w->attributes( $key => $value );
    $w->attributes( { $key => $value } );

Returns the object reference, to allow method chaining.

As of v1.10, passing a hash-ref no longer deletes current 
attributes, instead the attributes are added to the current attributes 
hash.

This means the attributes hash-ref can no longer be emptied using 
C<$w->attributes( { } );>. Instead, you may use 
C<%{ $w->attributes } = ();>.

As a special case, if no arguments are passed, the return value is a 
hash-ref of attributes instead of the object reference. This provides 
backwards compatability to support:

    $w->attributes->{key} = $value;

L</attrs> is an alias for L</attributes>.

=cut

sub attributes {
    my $self = shift;

    $self->{attributes} = {} if not defined $self->{attributes};

    # special-case to support $w->attrs->{key} = value
    return $self->{attributes} unless @_;

    my %attrs =
        ( scalar(@_) == 1 )
        ? %{ $_[0] }
        : @_;

    $self->{attributes}->{$_} = $attrs{$_} for keys %attrs;

    return $self;
}

=head2 mk_attr_accessors

Arguments: @names

Return Value: @names

=cut

sub mk_attr_accessors {
    my ( $self, @names ) = @_;
    my $class = ref $self || $self;
    for my $name (@names) {
        no strict 'refs';
        *{"$class\::$name"} = sub {
            return ( $_[0]->{attributes}->{$name} || $_[0] ) unless @_ > 1;
            my $self = shift;
            $self->{attributes}->{$name} = ( @_ == 1 ? $_[0] : [@_] );
            return $self;
            }
    }
}

sub _instantiate {
    my ( $self, $class, @args ) = @_;
    my $file = $class . ".pm";
    $file =~ s{::}{/}g;
    eval { require $file };
    croak qq/Couldn't load class "$class", "$@"/ if $@;
    return $class->new(@args);
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
