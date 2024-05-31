package Linux::Info::Distribution::Custom::Amazon;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::Custom';

our $VERSION = '2.16'; # VERSION
# ABSTRACT: a subclass of Linux::Info::Distribution::Custom


sub _set_regex {
    my $self = shift;
    $self->{regex} =
      qr/(?<name>Amazon\sLinux)\sAMI\srelease\s(?<version>[\d\.]+)/;
}

sub _set_others {
    my ( $self, $data_ref ) = @_;
    $self->{name}       = $data_ref->{name};
    $self->{version}    = $data_ref->{version};
    $self->{version_id} = $data_ref->{version};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Distribution::Custom::Amazon - a subclass of Linux::Info::Distribution::Custom

=head1 VERSION

version 2.16

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
