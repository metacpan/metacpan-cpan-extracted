package Lingua::JA::TFIDF::Base;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Carp;

__PACKAGE__->mk_classdata( _config => {} );

sub new {
    my $class  = shift;
    my $args   = shift;
    my %config = ();
    if ( ref $args eq 'HASH' ) {
        %config = %$args;
    }
    my $self = $class->SUPER::new();
    $self->config(%config);
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

sub config {
    my $class = shift;
    if (@_) {
        if ( @_ == 1 && !defined $_[0] ) {
            $class->_config(undef);
        }
        else {
            my %args = @_;
            $class->_config( $class->_merge_hashes( $class->_config, \%args ) );
        }
    }
    return $class->_config;
}

sub _merge_hashes {
    my $class = shift;
    my ( $lefthash, $righthash ) = @_;

    if ( !defined $righthash ) {
        return $lefthash;
    }

    if ( !defined $lefthash ) {
        return $righthash;
    }

    my %merged = %{$lefthash};
    for my $key ( keys %{$righthash} ) {
        my $right_ref = ( ref $righthash->{$key} || '' ) eq 'HASH';
        my $left_ref =
          ( ( exists $lefthash->{$key} && ref $lefthash->{$key} ) || '' ) eq
          'HASH';
        if ( $right_ref and $left_ref ) {
            $merged{$key} =
              merge_hashes( $lefthash->{$key}, $righthash->{$key} );
        }
        else {
            $merged{$key} = $righthash->{$key};
        }
    }

    return \%merged;
}

1;

__END__

=head1 NAME

Lingua::JA::TFIDF::Base - Base Class of Lingua::JA::TFIDF

=head1 SYNOPSYS

  package My::Class;
  use base qw(Lingua::JA::TFIDF::Base);

=head1 METHODS

=head2 new

=head2 mk_virtual_methods

=head2 config


=cut