use 5.008001;
use strict;
use warnings;

package Footprintless::Test::Log::Any::Adapter::Handle;

# ABSTRACT: Simple adapter for logging to a handle
our $VERSION = '1.032';

use Log::Any::Adapter::Util ();

use base qw/Log::Any::Adapter::Base/;

my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');

sub init {
    my ($self) = @_;
    if ( exists $self->{handle} ) {
        $self->{handle} = *{ $self->{handle} }{IO};
    }

    if ( exists $self->{log_level} ) {
        $self->{log_level} = Log::Any::Adapter::Util::numeric_level( $self->{log_level} )
            unless $self->{log_level} =~ /^\d+$/;
    }
    else {
        $self->{log_level} = $trace_level;
    }
}

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level($method);
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if $method_level > $self->{log_level};
        return unless $self->{handle};
        print { $self->{handle} } "$text\n";
    };
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    my $base = substr( $method, 3 );
    my $method_level = Log::Any::Adapter::Util::numeric_level($base);
    *{$method} = sub {
        return !!( $method_level <= $_[0]->{log_level} );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Footprintless::Test::Log::Any::Adapter::Handle - Simple adapter for logging to a handle


=head1 SYNOPSIS

    use Footprintless::Test::Log::Any::Adapter 
        ('Handle', handle => \*STDERR );

=head1 DESCRIPTION

This simple built-in L<Log::Any|Log::Any> adapter logs each message to STDERR
with a newline appended. Category is ignored.

The C<log_level> attribute may be set to define a minimum level to log.

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jonathan Swartz and David Golden.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
