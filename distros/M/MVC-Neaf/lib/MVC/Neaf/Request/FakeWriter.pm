package MVC::Neaf::Request::FakeWriter;

use strict;
use warnings;
our $VERSION = 0.17;

=head1 NAME

MVC::Neaf::Request::FakeWriter - part of test suite for Not Even A Framework

=head1 DESCRIPTION

See L<MVC::Neaf> and L<MVC::Neaf::Request::PSGI>.
Unless you plan to contribute to framework itself, this module is useless.

This module converts L<PSGI> asynchronous response with callback to a normal
straightforward response ([status, header, content]).

=head1 SINOPSYS

    use Data::Dumper;
    use MVC::Neaf::Request::FakeWriter;

    my $capture = MVC::Neaf::Request::FakeWriter->new;
    my $result = $capture->respond( $psgi_app_return );
    warn Dumper( $result ); # normal PSGI response
        # aka [ status, [ head...], [content...] ]

=head1 METHODS

=head2 new

Constructor (no args).

=head2 respond( sub { ... } )

Respond to provided callback in PSGI-compatible manner.

=head2 write( $data )

Append given data to buffer.

=head2 close()

Do nothing.

=cut

sub new {
    return bless {}, shift;
};

sub respond {
    my ($self, $psgi_ret) = @_;

    return $psgi_ret if ref $psgi_ret eq 'ARRAY';

    $psgi_ret->( sub {
        my $resp = shift;
        $self->{status} = $resp->[0];
        $self->{header} = $resp->[1];
        $self->{content} = $resp->[2] || [];

        return $self;
    } );

    return [ $self->{status}, $self->{header}, $self->{content} ];
};

sub write {
    my ($self, $data) = @_;
    push @{ $self->{content} }, $data;
};

sub close {
};

1;
