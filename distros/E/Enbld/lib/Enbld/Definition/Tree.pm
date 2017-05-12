package Enbld::Definition::Tree;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'tree';
    $self->{defined}{WebSite}           =
        'http://mama.indstate.edu/users/ice/tree/';
    $self->{defined}{DarwinArgument}    = \&set_args;
    $self->{defined}{VersionForm}       =   '1\.\d\.\d';
    $self->{defined}{Extension}         =   'tgz';
    $self->{defined}{DownloadSite}      =
        'http://mama.indstate.edu/users/ice/tree/src/';

    $self->{defined}{Prefix}            =   'prefix=';

    $self->{defined}{CommandConfigure}  =   '';
    $self->{defined}{CommandTest}       =   '';

    return $self;
}

sub set_args {

    my $args = 'CFLAGS="-O2 -Wall -fomit-frame-pointer -no-cpp-precomp"' .
        ' '.  'LDFLAGS=' . ' ' .
        'OBJS="tree.o unix.o html.o xml.o hash.o color.o strverscmp.o"';

    return $args;
}

1;

=pod

=head1 NAME

Enbld::Definition::Tree - definition module for Tree

=head1 SEE ALSO

L<Tree|http://mama.indstate.edu/users/ice/tree/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
