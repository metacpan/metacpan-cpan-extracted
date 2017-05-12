package Log::Any::Plugin::Format;
# ABSTRACT: Add a formatting subroutine to your Log::Any adapter

our $VERSION = '0.02';

use strict;
use warnings;

use Log::Any::Adapter::Util qw( log_level_aliases logging_methods );
use Class::Method::Modifiers qw( install_modifier );

sub install {
    my ($class, $adapter_class, %args) = @_;

    my $formatter = sub { join ' ', @_ };
       $formatter = $args{formatter}
        if defined $args{formatter} and ref $args{formatter} eq 'CODE';

    # Create format attribute if it doesn't exist
    unless ($adapter_class->can('format')) {
        install_modifier( $adapter_class, 'fresh', format => sub {
          my ($self, $sub) = @_;

          return $formatter unless defined $sub;

          $formatter = $sub;
          return $self;
        });
    }

    my $aliases = { log_level_aliases() };

    # Format input parameters for logging methods
    for my $method ( logging_methods() ) {
        install_modifier( $adapter_class, 'around', $method => sub {
            my $orig = shift;
            my $self = shift;

            my @new = $self->format->(@_);
            return $self->$orig( @new );
        });
    }

    # Make aliases call their counterparts
    for my $alias ( keys %{$aliases} ) {
        install_modifier( $adapter_class, 'around', $alias => sub {
            my $orig = shift;
            my $self = shift;

            my $method = $aliases->{$alias};
            return $self->$method(@_);
        });
    }
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set( 'SomeAdapter' );

    # Make all logged messages uppercase
    use Log::Any::Plugin;
    Log::Any::Plugin->add( 'Format', formatter => sub { map { uc } @_ } );

=head1 DESCRIPTION

Log::Any::Plugin::Format adds an external formatting subroutine to the current
adapter. This subroutine will be injected into all logging methods as an
argument pre-processor. The called logging method will receive the list
returned by the formatter subroutine as its arguments.

=head1 CONFIGURATION

=over 4

=item B<formatter>

Sets the formatting subroutine. The default subroutine is a no-op.

=back

=head1 METHODS

This plugin adds the following method to your adapter:

=over 4

=item B<format>

Sets or gets the current formatting subroutine history. When used as a getter
it returns the existing value; otherwise it returns the logging object.

=back

=head1 SEE ALSO

=over 4

=item * L<Log::Any::Plugin>

=item * L<Mojo::Log>

=back

=head1 AUTHOR

=over 4

=item * José Joaquín Atria (L<jjatria@cpan.org>)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
