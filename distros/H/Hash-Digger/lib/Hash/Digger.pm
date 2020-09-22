package Hash::Digger;

use 5.006;
use strict;
use warnings;
use Carp 'croak';

=head1 NAME

Hash::Digger - Access nested hash structures without vivification

=head1 VERSION

Version 0.0.3

=cut

our $VERSION = '0.0.3';

=head1 SYNOPSIS

Allows accessing hash structures without triggering autovivification.

    my %hash;

    $hash{'foo'}{'bar'} = 'baz';

    diggable \%hash, 'foo', 'bar';
    # Truthy

    diggable \%hash, 'xxx', 'yyy';
    # Falsey

    dig \%hash, 'foo', 'bar';
    # 'baz'

    dig \%hash, 'foo', 'bar', 'xxx';
    # undef

    exhume 'some default', \%hash, 'foo', 'bar';
    # 'baz'

    exhume 'some default', \%hash, 'foo', 'xxx';
    # 'some default'

    # Hash structure has not changed:
    use Data::Dumper;
    Dumper \%hash;
    # $VAR1 = {
    #           'foo' => {
    #                      'bar' => 'baz'
    #                    }
    #         };

=head1 EXPORT

dig, diggable, exhume

=cut

use Exporter 'import';
our @EXPORT_OK = qw(dig diggable exhume);

=head1 SUBROUTINES/METHODS

=head2 diggable

Check if given path is diggable on the hash (`exists` equivalent)

=cut

sub diggable {
    my ( $root, @path ) = @_;
    return ( _traverse_hash( $root, @path ) )[1];
}

=head2 dig

Dig the hash and return the value. If the path is not valid, it returns undef.

=cut

sub dig {
    my ( $root, @path ) = @_;
    return exhume( undef, $root, @path );
}

=head2 exhume

Dig the hash and return the value. If the path is not valid, it returns a default value.

=cut

sub exhume {
    my ( $default, $root, @path ) = @_;
    my $value = ( _traverse_hash( $root, @path ) )[0];
    return defined $value ? $value : $default;
}

## no critic (ValuesAndExpressions::ProhibitConstantPragma)
use constant E_NO_ROOT      => 'Root node is undefined';
use constant E_NO_ROOT_HASH => 'Root node is not a hash reference';
use constant E_NO_PATH      => 'No path to exhume';

# Traverse hash for the given path and return the data.
# Last item could be `undef` as in `$hash{'foo'}{'bar'} = undef`,
# so we also need to return if the element exists or not
sub _traverse_hash {
    my ( $root, @path ) = @_;
    my $exists = 0;

    croak E_NO_ROOT      if !defined $root;
    croak E_NO_ROOT_HASH if !_is_hash_reference($root);
    croak E_NO_PATH      if @path == 0;

    while ( my $element = shift @path ) {
        if ( !exists $root->{$element} ) {
            return ( undef, q() );
        }

        $root = $root->{$element};

        if ( !_is_hash_reference($root) && @path > 0 ) {
            return ( undef, q() );
        }
    }

    return ( $root, 1 );
}

sub _is_hash_reference {
    my $item = shift;
    return ref $item eq ref {};
}

=head1 REPOSITORY

L<https://github.com/juliodcs/Hash-Digger>

=head1 AUTHOR

Julio de Castro, C<< <julio.dcs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-digger at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Digger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Digger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Digger>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hash-Digger>

=item * Search CPAN

L<https://metacpan.org/release/Hash-Digger>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Julio de Castro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Hash::Digger
