package Lingua::JA::Categorize::Base;
use strict;
use warnings;
use Scalar::Util qw(weaken);
use base qw(Class::Accessor::Fast Class::Data::ConfigHash);
use Carp;

__PACKAGE__->mk_accessors($_) for qw(context);

sub new {
    my $class  = shift;
    my %args   = @_;
    my $config = delete $args{config};
    my $self   = $class->SUPER::new( {@_} );
    $self->config($config) if $config;
	weaken( $self->{context} );
    return $self;
}

sub mk_virtual_methods {
    my $class = shift;
    foreach my $method (@_) {
        my $slot = "${class}::${method}";
        {
            no strict 'refs';
            *{$slot} = sub {
                Carp::croak( ref( $_[0] ) . "::${method} is not overridden" );
              }
        }
    }
    return ();
}

1;

__END__

=head1 NAME

Lingua::JA::Categorize::Base - Base Class of Lingua::JA::Categorize

=head1 SYNOPSYS

  package My::Class;
  use base qw(Lingua::JA::Categorize::Base);

=head1 METHODS

=head2 new

=head2 mk_virtual_methods

=cut

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
