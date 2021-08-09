package JSONSchema::Validator::Error;

# ABSTRACT: Error class

use strict;
use warnings;

use overload
    '""' => sub { $_[0]->to_string },
    fallback => 1;

our @ISA = 'Exporter';
our @EXPORT_OK = qw(error);

sub error {
    return __PACKAGE__->new(@_);
}

sub new {
    my ($class, %params) = @_;

    return bless {
        message => $params{message},
        context =>  $params{context} // [],
        # parent => $params{parent},
        instance_path => $params{instance_path},
        schema_path => $params{schema_path}
    }, $class;
}

sub context { shift->{context} }
sub message { shift->{message} }
sub instance_path { shift->{instance_path} }
sub schema_path { shift->{schema_path} }

sub to_string {
    my $self = shift;
    my $msg = $self->message;
    my $instance_path = $self->instance_path;
    my $schema_path = $self->schema_path;
    $msg .= " [instance path: ${instance_path}]" if $instance_path;
    $msg .= " [schema path: ${schema_path}]" if $schema_path;
    return $msg;
}

sub unwind_to_string_list {
    my $self = shift;
    return [$self->to_string] unless @{$self->context};

    my $res = [];
    my $msg = $self->message;

    for my $err (@{$self->context}) {
        for my $err_str (@{$err->unwind_to_string_list}) {
            push @$res, "$msg: $err_str";
        }
    }

    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Error - Error class

=head1 VERSION

version 0.006

=head1 AUTHORS

=over 4

=item *

Alexey Stavrov <logioniz@ya.ru>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

Anton Fedotov <tosha.fedotov.2000@gmail.com>

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Andrey Khozov <andrey@rydlab.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
