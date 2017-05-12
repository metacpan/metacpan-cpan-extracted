package Log::Log4perl::Appender::Elasticsearch::Bulk;
use version ();
$Log::Log4perl::Appender::Elasticsearch::Bulk::VERSION = version->parse("0.09");

use 5.006;
use strict;
use warnings;

use constant _INTERNAL_DEBUG => 0;

use base "Log::Log4perl::Appender::Elasticsearch";

=head1 NAME

Log::Log4perl::Appender::Elasticsearch::Bulk

=head1 DESCRIPTION

This appender is based on L<Log::Log4perl::Appender::Elasticsearch>. It buffers the log entries and flush by certain buffer size or on destroy.

=head1 VERSION

Version 0.09

=cut

=head1 OPTIONS

=over 4

=item

buffer_size

the number of log entries in a bulk load.

default 50

=back

For further options see L<Log::Log4perl::Appender::Elasticsearch>

=cut

sub new {
    my ($class, %p) = @_;
    my $fc = delete($p{buffer_size});

    my $self = $class->SUPER::new(%p);

    $self->{_buffer} = [];
    $self->{_buffer_size} = $fc || 50;

    return $self;
} ## end sub new

sub _flush {
    my ($self) = @_;
    my $data   = "";
    my $buff   = delete $self->{_buffer};
    $self->{_buffer} = [];

    scalar(@{$buff}) || return;

    foreach (@{$buff}) {
        $data .= join $/, '{"index":{}}', $self->_to_json($_), '';
    }

    if (_INTERNAL_DEBUG) {
        require Data::Dumper;
        print Data::Dumper::Dumper($buff);
        print $data;
    }

    $self->_send_request($data, '_bulk');
} ## end sub _flush

sub log {
    my ($self, %p) = @_;
    push @{ $self->{_buffer} }, $self->_prepare_body(%p);
    (scalar(@{ $self->{_buffer} }) == $self->{_buffer_size}) && $self->_flush();
}

sub DESTROY {
    my ($self) = @_;
    _INTERNAL_DEBUG && print "_flush on destroy\n";
    $self->_flush();
}

=head1 AUTHOR

Alexei Pastuchov <palik at cpan.com>

=head1 REPOSITORY

L<https://github.com/p-alik/Log-Log4perl-Appender-Elasticsearch.git>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 by Alexei Pastuchov E<lt>palik at cpan.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;    # End of Log::Log4perl::Appender::Elasticsearch::Bulk
