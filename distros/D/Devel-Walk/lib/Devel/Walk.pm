package Devel::Walk;

use 5.010000;
use strict;
use warnings;

use Scalar::Util qw( refaddr reftype );

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( walk unstorable ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( walk );

our $VERSION = '0.04';

our $TOP = 1;
our %SEEN;

sub DEBUG () { 0 }

sub walk
{
    my( $obj, $sub, $loc ) = @_;
    # Thank you tobyink@cpan.org for pointing out refaddr()
    my $addr = refaddr( $obj );

    $loc ||= '$o';
    return unless $sub->($loc, $obj);

    my $r = reftype $obj;
    return unless $r;
    return if $SEEN{$addr};

    DEBUG and warn "$loc is $r";

    my $was_top = $TOP;
    local $TOP = 0;
    if( 'HASH' eq $r ) {
        local $SEEN{ $addr } = 1;
        $loc .= "->" if $was_top;
        foreach my $key ( keys %$obj ) {
            walk( $obj->{$key}, $sub, $loc."{$key}" );
        }
    }
    elsif( 'ARRAY' eq $r ) {
        local $SEEN{ $addr } = 1;
        $loc .= "->" if $was_top;
        for( my $q=0; $q<=$#$obj; $q++ ) {
            walk( $obj->[$q], $sub, $loc."[$q]" );
        }
    }
    elsif( 'REF' eq $r or 'SCALAR' eq $r ) {
        local $SEEN{ $addr } = 1;
        walk( $$obj, $sub, "\$\${$loc}" );
    }

}


1;

__END__

=head1 NAME

Devel::Walk - Walk a complex object or reference.

=head1 SYNOPSIS

    use Devel::Walk;

    use Storable qw( freeze );

    # We are looking for things that are unfreezable
    sub unfreezable
    {
        my( $location, $obj ) = @_;
        return unless ref $obj
        return if eval { local $SIG{__DIE__} = 'DEFAULT'; freeze $obj; 1; };
        warn "$location ($obj) is unfreezable";
        return 1;
    }

    walk( $suspect, \&unfreezable, '$obj' );




=head1 DESCRIPTION

Devel::Walk is used to recursely walk through a data structure, visiting
each element in it one at a time.  It keeps track of the location as a
string that could, potentially, be used to delete or modify the structure.

=head2 walk

    walk( $struct, $sub, '$basename' );

Recursely walks through C<$suspect>, invoking C<$sub> on each element of
each structure.  C<$basename> is updated with each recursion to be.  Only
walks through ARRAY, HASH, SCALAR and REF references.  Non-references and
other references (CODE, GLOB, IO, etc) are passed over, though C<$sub> is
still invoked.

If C<$basename> is empty, C<'$o'> is used as a default.

For each element of the structure, C<$sub> is invoked as follows:

    $sub->( $location, $obj );

Where C<$obj> is the current element of the structure being looked at and
C<$location> is a string that can be used to find the current value.  Think
of it as the I<address> of the current object, but in perl format.  You can
use L<perlfunc/eval> to find a value, provided C<$basename> is available in
the current context.

Example : C<"$o->{top}{second}[3]">

If C<$sub> returns true, recursion will happen on that reference.  If
C<$sub> returns false, recursion ends.  

Devel::Walk will stop recursing when it detects circular references in your
data structure.  For example, in the following code, C<$foo> will be seen
first, so we don't walk through C<$foo->{foo}>.

    my $foo = {biff=>1};
    $foo->{foo} = $foo;
    walk( $foo, sub { print "$_[0]\n"; 1 }, '$foo' );

Will only output:

    $foo
    $foo->{foo}
    $foo->{biff}


=head1 SEE ALSO

L<Devel::Walk::Unstorable>

=head1 AUTHOR

Philip Gwyn, E<lt>perl -at- pied.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
