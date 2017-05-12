package JavaScript::Code::Accessor;

use strict;
use vars qw[ $VERSION ];
use base qw[ Class::Accessor::Chained::Fast ];
use Carp ();

use Scalar::Util ();

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Accessor - A Accessor Class

=head2 SYNOPSIS

    use base qw[ JavaScript::Code::Accessor ];

=head2 DESCRIPTION

Accessor Class

=head1 METHDOS

=head2 JavaScript::Code::Accessor->new( %args | \%args )

Takes a hash or a hashref as initialization arguments.

=cut

sub new {
    my $obj   = shift;
    my $class = ref $obj || $obj;

    return $class->SUPER::new( $class->__args(@_) );
}

sub __args {
    my $self = shift;

    return {} unless @_;

    my $ref = @_ ? Scalar::Util::reftype( $_[0] ) || '' : '';
    my %args =
      $ref eq 'HASH'
      ? %{ shift() }
      : @_;

    return \%args;
}

=head1 SEE ALSO

L<JavaScript::Code>, L<Class::Accessor::Chained::Fast>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
