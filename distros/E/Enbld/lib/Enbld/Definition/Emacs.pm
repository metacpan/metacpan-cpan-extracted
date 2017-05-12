package Enbld::Definition::Emacs;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    
    $self->{defined}{WebSite}      =   'http://www.gnu.org/software/emacs/';

    $self->{defined}{DownloadSite} =   'http://ftp.gnu.org/gnu/emacs/';

    $self->{defined}{ArchiveName}  =   'emacs';
    $self->{defined}{VersionForm}  =   '2\d\.\d';

    $self->{defined}{AdditionalArgument} =  '--without-x --without-dbus';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Emacs - definition module for GNU Emacs

=head1 SEE ALSO

L<GNU Emacs|http://www.gnu.org/software/emacs/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
