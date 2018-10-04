use v5.18;
use warnings;

package Datify::Path;
# ABSTRACT: Describe structures like filesystem paths.
our $VERSION = 'v0.18.270'; # VERSION

use Datify;
use String::Tools qw(subst);

our %SETTINGS = (
    list_count     => '[$i/$n]',
    path_separator => '/',
    statement      => '$key = $value',
);

### Public methods ###

sub new {
    my $self = shift || __PACKAGE__;
    if ( my $class = ref $self ) {
        return bless { %$self,    @_, }, $class;
    } else {
        return bless { %SETTINGS, @_, }, $self;
    }
}

sub set {
    my $self = shift;
    my %set  = @_;

    my $return;
    my $class;
    if ( $class = ref $self ) {
        # Make a copy
        $self   = bless { %$self }, $class;
        $return = 0;
    } else {
        $class  = $self;
        $self   = \%SETTINGS;
        $return = 1;
    }

    %$self = ( %$self, %set );

    return ( $self, $class )[$return];
}

sub pathify {
    my $self = shift; $self = $self->new() unless ref $self;

    my $wantarray = wantarray;
    return unless defined $wantarray;
    return $wantarray
        ?   map $self->_flatten, $self->_pathify(@_)
        : [ map $self->_flatten, $self->_pathify(@_) ];
}

### Private methods ###

sub _pathify {
    my $self = shift; $self = $self->new() unless ref $self;
    my $s    = 1 == @_ ? shift : \@_;
    return undef unless defined $s;
    my $ref = ref $s;

    if      ( 'ARRAY'  eq $ref ) {
        return $self->_pathify_array($s);
    } elsif ( 'HASH'   eq $ref ) {
        return $self->_pathify_hash($s);
    #} elsif ( 'REF'    eq $ref ) {
    #   TODO
    #    return $self->_pathify_ref($s);
    #} elsif ( 'SCALAR' eq $ref ) {
    #   TODO
    #    return $self->_pathify_scalar($s);
    } elsif ( not $ref ) {
        return $s;
    } else {
        # Hopefully it has stringification overload.
        return "$s";
        #die 'Cannot handle ' . $ref;
    }
}

sub _pathify_array {
    my $self  = shift; $self = $self->new() unless ref $self;
    my $array = shift;

    my $size = Datify->numify( scalar @$array );
    return [ subst( $self->{list_count}, i => 0, n => 0 ), undef ]
        if ( $size eq '0' );

    my $format = subst(
        $self->{list_count},
        i => '%' . length($size) . 's',
        n => $size
    );

    my @structure;
    while ( my ( $i, $v ) = each @$array ) {
        my $key = sprintf( $format, Datify->numify( 1 + $i ) );
        push @structure, map { [ $key, $_ ] } $self->_pathify($v);
    }
    return @structure;
}

sub _pathify_hash {
    my $self = shift; $self = $self->new() unless ref $self;
    my $hash = shift;

    return [ $self->{path_separator}, undef ] if ( 0 == scalar keys %$hash );

    my @structure;
    foreach my $k ( sort Datify::keysort keys(%$hash) ) {
        my $key = $self->{path_separator} . Datify->keyify($k);
        push @structure,
            map { [ $key, $_ ] } $self->_pathify( $hash->{$k} );
    }
    return @structure;
}

sub _flatten {
    my $self = shift; $self = $self->new() unless ref $self;
    my ( $key, $value ) = @{ @_ ? $_[0] : $_ };

    if ( defined $value ) {
        if ( ref $value ) {
            # Assuming it's an ARRAY
            return $key . $self->_flatten($value);
        } else {
            return subst(
                $self->{statement},
                key   => $key,
                value => Datify->keyify($value)
            );
        }
    } else {
        return $key;
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Datify::Path - Describe structures like filesystem paths.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rkleemann/Datify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 VERSION

version v0.18.270

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2018 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__

=head1 SYNOPSIS

 use Datify::Path;

 my $pathify = Datify::Path->new();

 say foreach $pathify->pathify( [ qw( this that the-other ) ] );
 # [1/3] = this
 # [2/3] = that
 # [3/3] = 'the-other'

 say foreach $pathify->pathify( { a => 100, b => 1024, c => 102030 } );
 # /a = 100
 # /b = 1_024
 # /c = 102_030

 say foreach $pathify->pathify(
     {
         array  => [ 1, 10, 100, 10000, 100_000_000 ],
         hash   => { a => 'alpha', b => 'bravo', c => undef },
         nested => [
            { '!@#$%^&*()' => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 ] },
            { '' => 'empty string' },
            { " \t\n" => 'space, tab, & newline' },
            { 'empty array' => [] },
            { 'empty hash'  => {} },
         ],
     }
 );
 # /array[1/5] = 1
 # /array[2/5] = 10
 # /array[3/5] = 100
 # /array[4/5] = 10_000
 # /array[5/5] = 100_000_000
 # /hash/a = alpha
 # /hash/b = bravo
 # /hash/c
 # /nested[1/4]/'!@#$%^&*()'[ 1/10] = 1
 # /nested[1/4]/'!@#$%^&*()'[ 2/10] = 2
 # /nested[1/4]/'!@#$%^&*()'[ 3/10] = 3
 # /nested[1/4]/'!@#$%^&*()'[ 4/10] = 4
 # /nested[1/4]/'!@#$%^&*()'[ 5/10] = 5
 # /nested[1/4]/'!@#$%^&*()'[ 6/10] = 6
 # /nested[1/4]/'!@#$%^&*()'[ 7/10] = 7
 # /nested[1/4]/'!@#$%^&*()'[ 8/10] = 8
 # /nested[1/4]/'!@#$%^&*()'[ 9/10] = 9
 # /nested[1/4]/'!@#$%^&*()'[10/10] = 0
 # /nested[2/4]/'' = 'empty string'
 # /nested[3/4]/" \t\n" = 'space, tab, & newline'
 # /nested[4/4]/'empty array'[0/0]
 # /nested[4/4]/'empty hash'/

=head1 DESCRIPTION

Datify::Path will convert a data structure consisting of arrays, hashes,
and scalars into a form similar to a path listing.  This can be useful when
searching for a particular value, then finding the "path" that leads to it.

=head1 TODO

=head1 SEE ALSO

