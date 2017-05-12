package Message::Passing::Output::Log::Any::Adapter;
$Message::Passing::Output::Log::Any::Adapter::VERSION = '0.003';
# ABSTRACT: output messages via Log::Any::Adapter.
use Moo;
use MooX::Types::MooseLike::Base qw( Str ArrayRef );
use Log::Any qw( $log );
use Log::Any::Adapter;
use namespace::clean -except => 'meta';


has adapter_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has adapter_params => (
    is  => 'ro',
    isa => ArrayRef,
);

sub BUILD {
    my $self = shift;

    my @params = ( $self->adapter_name );
    push @params, @{ $self->adapter_params }
        if defined $self->adapter_params;

    Log::Any::Adapter->set(@params);
}

sub consume {
    my ( $self, $msg ) = @_;

    my $severity = 'info';

    $log->$severity($msg);
}

with 'Message::Passing::Role::Output';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Message::Passing::Output::Log::Any::Adapter - output messages via Log::Any::Adapter.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Message::Passing::Output::Log::Any::Adapter;

    my $logger = Message::Passing::Output::Log::Any::Adapter->new(
        adapter_name   => 'File',
        adapter_params => [ '/var/log/foo.log' ],
    );
    $logger->consume( 'message' );

    # or directly on the command line:
    # message-pass --input STDIN --output Log::Any::Adapter --output_options \
    #     '{"adapter_name":"File","adapter_params":["/var/log/foo.log"]}'

=head1 DESCRIPTION

Provides a very flexible output by using Log::Any Adapter that in turn can use
L<Log::Log4perl> or L<Log::Dispatch> to forward the messages.

The log level is not configurable at the moment and defaults to info.

=for Pod::Coverage BUILD

=head1 METHODS

=head2 adapter_name

An attribute for the L<Log::Any::Adapter> class.

=head2 adapter_params

An attribute for the parameters that get passed to the L<Log::Any::Adapter>.

=head2 consume

Consumes a message by JSON encoding it and printing it, followed by \n

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
