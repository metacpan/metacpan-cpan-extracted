package Devel::Walk::Unstorable;

use strict;
use warnings;

use Devel::Walk ();

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( check ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( unstorable );

our $VERSION = '0.02';

###############################################
sub unstorable
{
    my( $obj, $name ) = @_;
    my $S = Devel::Walk::Unstorable->new;
    $S->walk( $obj, $name );
    return $S->list;
}

###############################################
sub new
{
    my $package = shift;
    return bless {@_}, $package;
}

sub walk
{
    my( $self, $obj, $name ) = @_;
    local $self->{LAST};
    $self->{list} ||= [];
    Devel::Walk::walk( $obj, sub { $self->__unstorable( @_ ); }, $name );
    push @{ $self->{list} }, $self->{LAST} if defined $self->{LAST} and @{ $self->{list} } and 
                        $self->{list}[-1] ne $self->{LAST};
}

sub list { @{ $_[0]->{list} } }

sub __deepest
{
    my( $self, $old, $new ) = @_;
    return unless defined $old;
    my $ol = length( $old );
    # $old = '$something->{one}'
    # $new = '$something->{one}[0]'
    # $old is not deepest
    return if substr( $new, 0, $ol ) eq $old;

    # $old = '$something->{one}'
    # $new = '$${$something->{one}}{more}'
    # $old is not deepest
    return if $new =~ /^\$\$\{\Q$old\E\}/;
    # $old = '$something->{one}'
    # $new = '$something->{two}'
    # $old is deepest
    # warn "deepest='$old'";
    return 1;
}

sub __unstorable
{
    my( $self, $loc, $obj ) = @_;
    require 'Storable.pm';
    if( $self->__deepest( $self->{LAST}, $loc ) ) {
        # warn "deepest=$self->{LAST}";
        push @{ $self->{list} }, $self->{LAST};
        $self->{LAST} = undef;
    }

    if( $self->check( $loc, $obj ) ) {
        # warn "$loc is unstorable";
        $self->{LAST} = $loc;
        return 1;
    }
    else {
        # warn "$loc is storable";
    }
    return;
}

sub check
{
    my( $self, $loc, $obj ) = @_;
    return 1 if ref( $obj ) and not eval { $SIG{__DIE__} = 'DEFAULT'; Storable::freeze( $obj ); 1; };
    return;
}

1;

__END__

=head1 NAME

Devel::Walk::Unstorable - Find locations in complex structures that can't be serialized with Storable.

=head1 SYNOPSIS

    use Devel::Walk::Unstorable;

    my @list = unstorable( $suspect, '$suspect' );
    die "Can't store ", join "\n", @list if @list;


=head1 DESCRIPTION

This module uses L<Devel::Walk> to find all the locations of objects that can't
be stored with L<Storable/freeze>.

If you are like me, you regularly try to serialize large objects and save
them in a session file for your web application.  Storable's freeze is ideal
for this, except when it isn't.  You forgot to close a DBI handle somewhere
deep in your object.  Storable just reports this as a CODE reference, but
doesn't tell you what part of your structure is holding that reference.  You
can use C<unstorable> to walk your object structure to find the location.


It is highly recomended to only do this in a development environment, and only
if freeze has failed.

    my $data = eval { freeze( $obj ) };
    if( $@ ) {
        warn $@;
        my @list = unstorable( $obj, '$obj' );
        die "Unstorable reference at ", join "\n", @list;
    }

    # now you can write $data to you session DB.

=head2 unstorable

    my @bad = unstorable( $obj, $basename );

Walks C<$obj> and finds all the locations that can't be stored with
L<Storable/freeze>.  Returns the list of locations, if any.

C<$basename> may be omited and defaults to C<'$o'>.


=head1 OBJECT

You might want to customize the behaviour of this module.  If so, you can 
subclass C<Devel::Walk::Unstorable> and overload one of the worker modules.


    my $walker = Devel::Walk::Unstorable->new;
    $walker->walk( $obj, $name );
    my @bad = $walker->list;

=head2 new

    my $walker = Devel::Walk::Unstorable->new;

=head2 walk

    $walker->walk( $struct, '$basename' );

Recursely walks through C<$suspect>, invoking L</check> on each element of
each structure.  C<$basename> is updated with each recursion to be.  Only
walks through ARRAY, HASH, SCALAR and REF references.  

All locations that fail L</check> will be accumulated in a list.  The list
will only contain the deepest locations.

If C<$basename> is empty, C<'$o'> is used as a default.

=head2 list

    my @bad = $walker->list;

Returns the list of location that failed L</check>.


=head2 check

    my $ok = $walker->check( $loc, $obj );

By default, C<check> will return true if C<$obj> is a reference that fails
to be serialized with L<Storable/freeze>.  Returns false if C<$obj> is not a
reference, or if it's a reference that can be sucessfully serialized with
L<Storable/freeze>.


=head1 SEE ALSO

L<Devel::Walk>
L<Storable>

=head1 AUTHOR

Philip Gwyn, E<lt>fil-at-pied.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
