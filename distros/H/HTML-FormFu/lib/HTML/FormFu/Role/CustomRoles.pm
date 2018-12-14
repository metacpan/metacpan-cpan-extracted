use strict;

package HTML::FormFu::Role::CustomRoles;
# ABSTRACT: add custom roles
$HTML::FormFu::Role::CustomRoles::VERSION = '2.07';
use Moose::Role;
use Moose::Util qw( ensure_all_roles );

use List::Util 1.45 qw( uniq );

has _roles => (
    is      => 'rw',
    default => sub { [] },
    lazy    => 1,
    isa     => 'ArrayRef',
);

sub roles {
    my $self = shift;

    my @roles = @{ $self->_roles };
    my @new;

    if ( 1 == @_ && 'ARRAY' eq ref $_[0] ) {
        @new = @{ $_[0] };
    }
    elsif (@_) {
        @new = @_;
    }

    if (@new) {
        for my $role (@new) {
            if ( !ref($role) && $role =~ s/^\+// ) {
                push @roles, $role;
            }
            elsif ( !ref $role ) {
                push @roles, "HTML::FormFu::Role::$role";
            }
            else {
                push @roles, $role;
            }
        }

        @roles = uniq @roles;

        ensure_all_roles( $self, @roles );

        $self->_roles( \@roles );
    }

    return [@roles];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Role::CustomRoles - add custom roles

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
