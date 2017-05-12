package Enbld::Definition::Rakudostar;

use strict;
use warnings;

use version;

use parent qw/Enbld::Definition/;

require Enbld::Feature;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}  = 'rakudo-star';
    $self->{defined}{WebSite}      = 'http://rakudo.org';
    $self->{defined}{VersionForm}  = '\d{4}\.\d{2}';
    $self->{defined}{DownloadSite} = 'http://rakudo.org/downloads/star/';

    $self->{defined}{TestAction}   = 'rakudo-test';

    $self->{defined}{CommandConfigure} = 'perl Configure.pl --backends=moar --gen-moar --gen-nqp';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Rakudostar - definition module for Rakudo Perl 6

=head1 SEE ALSO

L<Rakudo Perl 6|http://rakudo.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
