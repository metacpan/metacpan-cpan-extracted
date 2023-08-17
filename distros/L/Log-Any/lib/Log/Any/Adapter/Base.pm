use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::Base;

our $VERSION = '1.717';
our @CARP_NOT = ( 'Log::Any::Adapter' );

# we import these in case any legacy adapter uses them as class methods
use Log::Any::Adapter::Util qw/make_method dump_one_line/;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    $self->init(@_);
    return $self;
}

sub init { }

# Create stub logging methods
for my $method ( Log::Any::Adapter::Util::logging_and_detection_methods() ) {
    no strict 'refs';
    *$method = sub {
        my $class = ref( $_[0] ) || $_[0];
        die "$class does not implement $method";
    };
}

# This methods installs a method that delegates to an object attribute
sub delegate_method_to_slot {
    my ( $class, $slot, $method, $adapter_method ) = @_;

    make_method( $method,
        sub { my $self = shift; return $self->{$slot}->$adapter_method(@_) },
        $class );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Base

=head1 VERSION

version 1.717

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
