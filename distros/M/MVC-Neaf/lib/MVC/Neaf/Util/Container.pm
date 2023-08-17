package MVC::Neaf::Util::Container;

use strict;
use warnings;
our $VERSION = '0.2901';

=head1 NAME

MVC::Neaf::Util::Container - path & method based container for Not Even A Framework

=head1 DESCRIPTION

This is utility class.
Nothing to see here unless one intends to work on L<MVC::Neaf> itself.

This class can hold multiple entities addressed by paths and methods
and extract them in the needed order.

=head1 SYNOPSIS

    my $c = MVC::Neaf::Util::Container->new;

    $c->store( "foo", path => '/foo', method => 'GET' );
    $c->store( "bar", path => '/foo/bar', exclude => '/foo/bar/baz' );

    $c->fetch( path => "/foo", method => 'GET' ); # foo
    $c->fetch( path => "/foo/bar", method => 'GET' ); # foo bar
    $c->fetch( path => "/foo/bar", method => 'POST' );
            # qw(bar) - 'foo' limited to GET only
    $c->fetch( path => "/foo/bar/baz", method => 'GET' );
            # qw(foo) - 'bar' excluded

=cut

use Carp;

use parent qw(MVC::Neaf::Util::Base);
use MVC::Neaf::Util qw( maybe_list canonize_path path_prefixes supported_methods check_path );
our @CARP_NOT = qw(MVC::Neaf::Route);

=head1 ATTRIBUTES

=head2 exclusive

Only store one item per (path,method) pair, and fail loudly in case of conflicts.

=head1 METHODS

=head2 store

    store( $data, %spec )

Store $data in container. Spec may include:

=over

=item path - single path or list of paths, '/' assumed if none.

=item method - name of method or array of methods.
By default, all methods supported by Neaf.

=item exclude - single path or list of paths. None by default.

=item prepend - if true, prepend to the list instead of appending.

=item tentative (exclusive container only) - if true, don't override existing
declarations, and don't complain when overridden.

=item override (exclusive container only) - if true, override
any preexisting content.

=back

=cut

sub store {
    my ($self, $data, %opt) = @_;

    $self->my_croak( "'tentative' and 'override' are useless for non-exclusive container" )
        if !$self->{exclusive} and ( $opt{tentative} or $opt{override} );

    $self->my_croak( "'tentative' and 'override' are mutually exclusive" )
        if $opt{tentative} and $opt{override};

    $opt{data} = $data;

    my @methods = map { uc $_ } maybe_list( $opt{method}, supported_methods() );

    my @todo = check_path map { canonize_path( $_ ) } maybe_list( $opt{path}, '' );
    if ($opt{exclude}) {
        my $rex = join '|', map { quotemeta(canonize_path($_)) }
            check_path maybe_list( $opt{exclude} );
        $opt{exclude} = qr(^(?:$rex)(?:[/?]|$));
        @todo = grep { $_ !~ $opt{exclude} } @todo
    };

    if ($self->{exclusive}) {
        my @list = $self->store_check_conflict( %opt, method => \@methods, path => \@todo );
        $self->my_croak( "Conflicting path spec: ".join ", ", @list )
            if @list;
    };

    foreach my $method ( @methods ) {
        foreach my $path ( @todo ) {
            my $array = $self->{data}{$method}{$path} ||= [];
            if ( $self->{exclusive} ) {
                @$array = (\%opt)
                    unless $array->[0] and $opt{tentative} and !$array->[0]{tentative};
            } elsif ( $opt{prepend} ) {
                unshift @$array, \%opt;
            } else {
                push @$array, \%opt;
            };
        };
    };

    $self;
};

=head2 store_check_conflict

    store_check_conflict( path => ..., method => ... )

Check that no previous declarations conflict with the new one.

This is only if exclusive was specified.

=cut

sub store_check_conflict {
    my ($self, %opt) = @_;

    $self->my_croak( "useless call for non-exclusive container" )
        unless $self->{exclusive};

    if (!$opt{tentative} and !$opt{override}) {
        # Check for conflicts before changing anything
        my %conflict;
        foreach my $method ( @{ $opt{method} } ) {
            foreach my $path ( @{ $opt{path} } ) {
                my $existing = $self->{data}{$method}{$path};
                next unless $existing && $existing->[0];
                next if $existing->[0]->{tentative};
                push @{ $conflict{$path} }, $method;
            };
        };

        my @list =
            map { $_."[".(join ",", sort @{ $conflict{$_} })."]" }
            sort keys %conflict;
        return @list;
    };

    return ();
};

=head2 list_methods

Returns methods currently in the storage.

=cut

sub list_methods {
    my $self = shift;

    return keys %{ $self->{data} };
};

=head2 list_paths

Returns paths for given method, or all if no method given.

=cut

sub list_paths {
    my ($self, @methods) = @_;

    @methods = $self->list_methods
        unless @methods;

    my %uniq;
    foreach my $method (@methods) {
        $uniq{$_}++ for keys %{ $self->{data}{$method} };
    };
    return keys %uniq;
};

=head2 fetch

    fetch( %spec )

Return all matching previously stored objects,
from shorter to longer paths, in order of addition.

Spec may include:

=over

=item path - a single path to match against

=item method - method to match against

=back

=cut

sub fetch {
    my $self = shift;
    return map { $_->{data} } $self->fetch_raw(@_);
};

=head2 fetch_last

Same as fetch(), but only return the last (last added & longest path) element.

=cut

sub fetch_last {
    my $self = shift;
    my ($bucket) = reverse $self->fetch_raw(@_);
    return $bucket->{data};
};

=head2 fetch_raw

Same as fetch(), but return additional info instead of just stored item:

    {
        data   => $your_item_here,
        path   => $all_the_paths,
        method => $list_of_methods,
        ...
    }

=cut

sub fetch_raw {
    my ($self, %opt) = @_;

    my @missing = grep { !defined $opt{$_} } qw(path method);
    croak __PACKAGE__."->fetch: required fields missing: @missing"
        if @missing;

    my $path   = canonize_path( $opt{path} );

    my @ret;
    my $tree = $self->{data}{ $opt{method} };

    foreach my $prefix ( path_prefixes( $opt{path} || '' ) ) {
        my $list = $tree->{$prefix};
        next unless $list;
        foreach my $node( @$list ) {
            next if $node->{exclude} and $opt{path} =~ $node->{exclude};
            push @ret, $node;
        };
    };

    return @ret;
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2023 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
