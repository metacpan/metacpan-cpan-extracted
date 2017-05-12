package Enbld::Definition::Aprutil;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    
    $self->{defined}{WebSite}       = 'http://apr.apache.org';

    $self->{defined}{DownloadSite}  = 'http://archive.apache.org/dist/apr/';
    $self->{defined}{ArchiveName}   = 'apr-util';
    $self->{defined}{VersionForm}   = '\d\.\d\.\d{1,2}';

    $self->{defined}{Dependencies}  = sub { return [ 'apr' ] };

    $self->{defined}{AdditionalArgument} = \&set_argument;

    return $self;
}

sub set_argument {
    my $attributes = shift;

    require Enbld::Home;
    my $to_install = Enbld::Home->library;

    my $argument = "--with-apr=$to_install";

    return $argument;
}

1;

=pod

=head1 NAME

Enbld::Definition::Aprutil - definition module for The Apache Portable Runtime Project

=head1 SEE ALSO

L<The Apache Portable Runtime Project|http://apr.apache.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
