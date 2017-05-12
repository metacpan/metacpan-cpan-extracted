package Lim::RPC::Value::Collection;

use common::sense;
use Carp;

use Lim ();

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=over 4

=item OPT_REQUIRED

=item OPT_SWALLOW

=item OPT_SINGLE

=back

=cut

our $VERSION = $Lim::VERSION;

sub OPT_REQUIRED (){ 0x00000001 }
sub OPT_SWALLOW (){ 0x00000002 }
sub OPT_SINGLE (){ 0x00000004 }

our %OPTIONS = (
    'required' => OPT_REQUIRED,
    'swallow' => OPT_SWALLOW,
    'single' => OPT_SINGLE
);

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = scalar @_ > 1 ? ( @_ ) : ( textual => $_[0] );
    my $self = {
        options => 0
    };

    if (exists $args{textual}) {
        foreach (split(/\s+/o, lc($args{textual}))) {
            if (exists $OPTIONS{$_}) {
                $self->{options} |= $OPTIONS{$_};
            }
            else {
                confess __PACKAGE__, ': unknown RPC value collection setting "'.$_.'"';
            }
        }
    }
    else {
        unless (defined $args{children} and ref($args{children}) eq 'HASH') {
            confess __PACKAGE__, ': No children specified or invalid';
        }
        $self->{children} = $args{children};

        if (defined $args{options}) {
            unless (ref($args{options}) eq 'ARRAY') {
                confess __PACKAGE__, ': Invalid options specified';
            }

            foreach (@{$args{options}}) {
                if (exists $OPTIONS{$_}) {
                    $self->{options} |= $OPTIONS{$_};
                }
                else {
                    confess __PACKAGE__, ': Unknown RPC value collection option "'.$_.'"';
                }
            }
        }
    }

    bless $self, $class;
}

sub DESTROY {
    my ($self) = @_;
}

=head2 children

=cut

sub children {
    $_[0]->{children};
}

=head2 set_children

=cut

sub set_children {
    if (defined $_[1] and ref($_[1]) eq 'HASH') {
        $_[0]->{children} = $_[1];
    }

    $_[0];
}

=head2 required

=cut

sub required {
    $_[0]->{options} & OPT_REQUIRED ? 1 : 0;
}

=head2 swallow

=cut

sub swallow {
    $_[0]->{options} & OPT_SWALLOW ? 1 : 0;
}

=head2 single

=cut

sub single {
    $_[0]->{options} & OPT_SINGLE ? 1 : 0;
}

=head2 comform

=cut

sub comform {
    unless (defined $_[1]) {
        return 0;
    }
    if ($_[0]->single) {
        unless (ref($_[1]) eq 'HASH') {
            return 0;
        }
    }
    unless (ref($_[1]) eq 'HASH' or ref($_[1]) eq 'ARRAY') {
        return 0;
    }
    return 1;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

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

1; # End of Lim::RPC::Value::Collection
