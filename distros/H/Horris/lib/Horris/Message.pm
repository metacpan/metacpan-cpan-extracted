package Horris::Message;
# ABSTRACT: Internal Message Structure For Horris


use Moose;
use Moose::Util::TypeConstraints;
use namespace::clean -except => qw(meta);

class_type 'Horris::Message::Address';

coerce 'Horris::Message::Address'
    => from 'Str'
        => via { Horris::Message::Address->new($_) }
;

has from => (
    is => 'ro',
    isa => 'Horris::Message::Address',
    coerce => 1,
    required => 1,
    handles  => [ qw(modifier nickname username hostname) ]
);

has channel => (
    is => 'ro',
    isa => 'Str',
);

has message => (
    is => 'ro',
    isa => 'Str',
);

has timestamp => (
    is => 'ro',
    isa => 'Int',
    default => sub { time() }
);

__PACKAGE__->meta->make_immutable;

package Horris::Message::Address;
use Moose;

has str_ref => (
    is => 'ro',
    isa => 'ScalarRef',
    required => 1,
    trigger => sub {
        my $self = shift;
        $self->__parsed(0);
    },
);

has __parsed => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 0,
);

has modifier => (
    is => 'ro',
    isa => 'Maybe[Str]',
    writer => 'set_modifier',
);

has nickname => (
    is => 'ro',
    isa => 'Maybe[Str]',
    writer => 'set_nickname',
);

has username => (
    is => 'ro',
    isa => 'Maybe[Str]',
    writer => 'set_username',
);

has hostname => (
    is => 'ro',
    isa => 'Maybe[Str]',
    writer => 'set_hostname',
);

around BUILDARGS => sub {
    my ($next, $class, @args) = @_;

    if (@args == 1) {
        @args = (str_ref => \$args[0]);
    }
    $next->($class, @args);
};

around qw(modifier nickname username hostname) => \&__check_parsed;

sub __check_parsed {
    my ($next, $self, @args) = @_;

    if (@args) {
        return $next->($self, @args);
    }

    if (! $self->__parsed) {
        my $ref = $self->str_ref;

		$$ref =~ /^([^!]+)!([^@]+)@(.*)$/;
        $self->set_modifier( '' );
        $self->set_nickname( $1 || '' );
        $self->set_username( $2 || '' );
        $self->set_hostname( $3 || '' );
        $self->__parsed(1);
    }
    return $next->($self);
}

__PACKAGE__->meta->make_immutable();

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Message - Internal Message Structure For Horris

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    no synopsis

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

