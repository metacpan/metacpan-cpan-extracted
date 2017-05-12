package Devel::Unplug::OO;

use strict;
use warnings;
use Devel::Unplug ();

=head1 NAME

Devel::Unplug::OO - OO interface to L<Devel::Unplug>

=head1 VERSION

This document describes Devel::Unplug::OO version 0.03

=cut

use vars qw($VERSION @ISA);

$VERSION = '0.03';

=head1 SYNOPSIS

    {
        my $unp = Devel::Unplug::OO->new( 'Some::Module' );
        eval "use Some::Module";
        like $@, qr{Some::Module}, "failed OK";
    }
    eval "use Some::Module";
    ok !$@, "loaded OK";

=head1 DESCRIPTION

C<Devel::Unplug::OO> is an object oriented wrapper around
L<Devel::Unplug>. It provides a convenient interface for unplugging a
set of modules for the life of a particular scope and then automatically
inserting them at the end of the scope.

=cut

=head1 INTERFACE 

=head2 C<< new( $module ... ) >>

Make a new C<Devel::Unplug::OO>. Any modules named as parameters
will be unplugged. When the returned object is destroyed they will
be re-inserted.

    # Unplug
    my $u = Devel::Unplug::OO->new( 'Some::Module' );
    
    # Insert
    undef $u;

=cut

sub new {
    my $class = shift;
    my $self = bless [@_], $class;
    Devel::Unplug::unplug( @$self );
    return $self;
}

sub DESTROY {
    my $self = shift;
    Devel::Unplug::insert( @$self );
}

1;
__END__

=head1 DEPENDENCIES

L<Devel::Unplug>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-devel-unplug@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
