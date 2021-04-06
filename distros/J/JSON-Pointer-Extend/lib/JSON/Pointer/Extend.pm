package JSON::Pointer::Extend;

use utf8;
use strict;
use warnings;

use JSON::Pointer;
use Carp qw();

our $VERSION = '0.02';

sub new {
    my ($class, %opt) = @_;
    my $self = {};
    bless $self, $class;

    $opt{'-pointer'} && $self->pointer(delete $opt{'-pointer'});
    $opt{'-document'} && $self->document(delete $opt{'-document'});

    return $self;
}

sub process {
    my ($self) = @_;
    my $pointer = $self->pointer // Carp::croak("'pointer' not defined");

    for my $key (keys %$pointer) {
        $self->_recursive_process($self->document, $key, $pointer->{$key});
    }
    return 1;
}

sub _recursive_process {
    my ($self, $document, $pointer, $cb) = @_;

    if ($pointer =~ /(.*?)\/\*(.+)?/) {
        my $path = $1;
        my $tail = $2;
        my $arr_ref = JSON::Pointer->get($document, $path);
        if (ref($arr_ref) ne 'ARRAY') {
            Carp::croak("Path '$path' not array");
        }

        my @arr = @$arr_ref;
        if ($tail) {
            for my $el (@arr) {
                $self->_recursive_process($el, $tail, $cb);
            }
        }
        else {
            my ($root_pointer, $field_name) = $pointer =~ /(.*)\/(.+)/;
            for my $el (@arr) {
                $cb->($el, JSON::Pointer->get($document, $root_pointer), $field_name);
            }
        }
    }
    elsif ($pointer eq '') {
        my $path = '';
        my $arr_ref = JSON::Pointer->get($document, $path);
        if (ref($arr_ref) ne 'ARRAY') {
            Carp::croak("Path '$path' not array");
        }

        my @arr = @$arr_ref;
        for my $el (@arr) {
            $cb->($el, $arr_ref, undef);
        }
    }
    else {
        my ($root_pointer, $field_name) = $pointer =~ /(.+)?\/(.+)/;
        $cb->(JSON::Pointer->get($document, $pointer), $root_pointer ? JSON::Pointer->get($document, $root_pointer) : $document, $field_name);
    }
}

############################### GET/SET METHODS ##############################

sub document {
    if (scalar(@_) > 1) {
        my $ref = ref($_[1]);
        if ($ref ne 'HASH' && $ref ne 'ARRAY') {
            Carp::croak("'document' must be a hashref or arrayref");
        }
        $_[0]->{'document'} = $_[1];
    }
    return $_[0]->{'document'};
}

sub pointer {
    if (scalar(@_) > 1) {
        if (ref($_[1]) ne 'HASH') {
            Carp::croak("'pointer' must be a hashref");
        }
        $_[0]->{'pointer'} = $_[1];
    }
    return $_[0]->{'pointer'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Pointer::Extend - L<JSON::Pointer> extension module

=head1 VERSION

version 0.02

=head1 SYNOPSYS

    use JSON::Pointer::Extend;

    my $json_pointer = JSON::Pointer::Extend->new(
        -document       => {
            'seat'          => {
                'name'          => 'Seat 1',
            },
            'prices'        => [
                {'name'         => 'price1'},
                {'name'         => 'price2'},
                {'name'         => 'price3'},
            ],
        },
        -pointer        => {
            '/seat/name'        => sub {
                my ($value, $document, $field_name) = @_;
                ...
            },
            '/prices/*/name'    => sub {
                my ($value, $document, $field_name) = @_;
                ...
            },
        },
    );

    $json_pointer->process();

=head1 DESCRIPTION

C<JSON::Pointer::Extend> - Extend Perl implementation of JSON Pointer (RFC6901)

=head1 METHODS

=head2 document($document :HashRef|Arrayref) :HashRef|ArrayRef

=over

=item $document :HashRef|ArrayRef - Target perl data structure that is able to be presented by JSON format.

Get/Set document value.

=back

=head2 pointer($pointer :HashRef) :HashRef

=over

=item $pointer :HashRef - Key: JSON Pointer string to identify specified value in the document. Value: Callback to proccess value, args: ($value, $document, $field_name)

Get/Set pointer value.

=back

=head2 process() :Scalar

Start process data

=head1 DEPENDENCE

L<JSON::Pointer>, L<Carp>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

