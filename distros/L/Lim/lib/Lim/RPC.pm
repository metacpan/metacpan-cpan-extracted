package Lim::RPC;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);

use Lim ();
use Lim::Error ();

=encoding utf8

=head1 NAME

Lim::RPC - Utilities for Lim's RPC

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

=head1 SYNOPSIS

=over 4

use Lim::RPC;

=back

=head1 NOTE

These functions are mainly used internaly, you should not have any reason to
call them.

=head1 METHODS

=over 4

=item Lim::RPC::V($q, $def)

V is for Verify, it will verify the content of the hash ref C<$q> against the
RPC definition in C<$def>. On an error it will L<confess>.

=cut

sub V {
    my ($q, $def) = @_;

    if (defined $q and defined $def) {
        unless (ref($q) eq 'HASH' and ref($def) eq 'HASH') {
            confess __PACKAGE__, ': Can not verify data, invalid parameters given';
        }

        my @v = ([$q, $def]);
        while (defined (my $v = shift(@v))) {
            ($q, $def) = @$v;
            my $a;

            if (ref($q) eq 'ARRAY') {
                $a = $q;
            }
            else {
                $a = [$q];
            }

            foreach $q (@{$a}) {
                unless (ref($q) eq 'HASH') {
                    confess __PACKAGE__, ': Can not verify data, invalid data given';
                }

                # check required
                foreach my $k (keys %$def) {
                    if (blessed($def->{$k}) and $def->{$k}->required and !exists $q->{$k}) {
                        confess __PACKAGE__, ': required data (', $k, ') missing, does not match definition';
                    }
                }

                # check data
                foreach my $k (keys %$q) {
                    unless (exists $def->{$k}) {
                        confess __PACKAGE__, ': invalid data (', $k, '), no definition exists';
                    }

                    if (blessed($def->{$k}) and !$def->{$k}->comform($q->{$k})) {
                        confess __PACKAGE__, ': invalid data (', $k, '), validation failed';
                    }

                    if (ref($q->{$k}) eq 'HASH' or ref($q->{$k}) eq 'ARRAY') {
                        if (ref($def->{$k}) eq 'HASH') {
                            push(@v, [$q->{$k}, $def->{$k}]);
                        }
                        elsif (blessed $def->{$k} and $def->{$k}->isa('Lim::RPC::Value::Collection')) {
                            unless ($def->{$k}->swallow) {
                                push(@v, [$q->{$k}, $def->{$k}->children]);
                            }
                        }
                        else {
                            confess __PACKAGE__, ': invalid definition (', $k, '), can not validate data';
                        }
                    }
                }
            }
        }
    }
    return;
}

=item Lim::RPC::R($cb, $data)

R is for Result, called when a RPC call finish and convert the given C<$data> to
the corresponding protocol.

=cut

sub R {
    my ($cb, $data) = @_;

    unless (blessed($cb)) {
        confess __PACKAGE__, ': cb not blessed';
    }

    if (blessed($data)) {
        if ($data->isa('Lim::Error')) {
            return $cb->cb->($data);
        }
    }
    elsif (defined $data) {
        unless (ref($data) eq 'HASH') {
            confess __PACKAGE__, ': data not a hash';
        }

        if ($cb->call_def and exists $cb->call_def->{out}) {
            Lim::RPC::V($data, $cb->call_def->{out});
        }
        elsif (%$data) {
            confess __PACKAGE__, ': data given without definition';
        }
    }
    else {
        if ($cb->call_def and exists $cb->call_def->{out}) {
            Lim::RPC::V({}, $cb->call_def->{out});
        }
    }

    return $cb->cb->(defined $data ? $data : {});
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::RPC

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC
