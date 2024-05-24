package Linux::Info::Distribution::Custom::CloudLinux;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::Custom';
use Class::XSAccessor getters => { get_codename => 'codename', };

our $VERSION = '2.12'; # VERSION
# ABSTRACT: a subclass of Linux::Info::Distribution::Custom


sub _set_regex {
    my $self = shift;
    $self->{regex} =
qr/(?<name>CloudLinux\sServer)\srelease\s(?<version>[\d\.]+)\s\((?<codename>[\w\s]+)\)/;
}

sub _set_others {
    my ( $self, $data_ref ) = @_;
    $self->{name}     = $data_ref->{name};
    $self->{version}  = $data_ref->{version};
    $self->{codename} = $data_ref->{codename};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Distribution::Custom::CloudLinux - a subclass of Linux::Info::Distribution::Custom

=head1 VERSION

version 2.12

=head1 METHODS

=head2 get_codename

Returns a string of the distribution codename.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
