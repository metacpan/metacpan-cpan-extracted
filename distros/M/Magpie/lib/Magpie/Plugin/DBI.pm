package Magpie::Plugin::DBI;
$Magpie::Plugin::DBI::VERSION = '1.163200';
use Moose::Role;

# ABSTRACT: A simple Role for dealing with DBI-backed assets;
#
use Magpie::Constants;

has dsn => (
    isa       => "Str",
    is        => "ro",
    predicate => "has_dsn",
);

has extra_args => (
    isa       => "HashRef|ArrayRef",
    is        => "ro",
    predicate => "has_extra_args",
);

has username => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_username',
);

has password => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_password',
);

sub _connect_args {
    my $self = shift;
    my @args = ( $self->dsn || die "dsn is required" );

    if ( $self->has_username ) {
        push @args, user => $self->username;
    }

    if ( $self->has_password ) {
        push @args, password => $self->password;
    }

    if ( $self->has_extra_args ) {
        my $extra = $self->extra_args;

        if ( ref($extra) eq 'ARRAY' ) {
            push @args, @$extra;
        }
        else {
            push @args, %$extra;
        }
    }

    \@args;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Plugin::DBI - A simple Role for dealing with DBI-backed assets;

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
