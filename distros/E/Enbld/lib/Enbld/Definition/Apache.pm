package Enbld::Definition::Apache;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    
    $self->{defined}{ArchiveName}  = 'httpd';
    $self->{defined}{WebSite}      = 'http://httpd.apache.org';
    $self->{defined}{VersionForm}  = '2\.\d\.\d{1,2}';
    $self->{defined}{Extension}    = 'tar.gz';
    $self->{defined}{DownloadSite} = 'http://archive.apache.org/dist/httpd/';

    $self->{defined}{Dependencies} = sub { return [ 'pcre', 'apr', 'aprutil' ] };

    $self->{defined}{AdditionalArgument}=   \&set_argument;

    $self->{defined}{CommandTest}       =   '';

    return $self;
}

sub set_argument {
    my $attributes = shift;

    require Enbld::Home;
    my $to_install = Enbld::Home->library;

    my $argument = "--with-pcre=$to_install --with-apr=$to_install --with-apr-util=$to_install";

    return $argument;
}

1;

=pod

=head1 NAME

Enbld::Definition::Apache - definition module for Apache HTTP Server

=head1 SEE ALSO

L<Apache HTTP Server|http://httpd.apache.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
