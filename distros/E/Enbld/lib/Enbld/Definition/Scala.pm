package Enbld::Definition::Scala;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'scala';
    $self->{defined}{WebSite}           =   'http://www.scala-lang.org';
    $self->{defined}{VersionForm}       =   '\d\.\d{1,2}\.\d';
    $self->{defined}{Extension}         =   'tgz';
    $self->{defined}{DownloadSite}      =   'http://www.scala-lang.org/files/archive/';

    $self->{defined}{CopyFiles}         =
        [ 'bin', 'examples', 'man', 'src', 'doc', 'lib', 'misc' ];

    $self->{defined}{CommandConfigure}  =   '';
    $self->{defined}{CommandMake}       =   '';
    $self->{defined}{CommandTest}       =   '';
    $self->{defined}{CommandInstall}    =   '';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Scala - definition module for The Scala Programming Language

=head1 SEE ALSO

L<The Scala Programming Language|http://www.scala-lang.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
