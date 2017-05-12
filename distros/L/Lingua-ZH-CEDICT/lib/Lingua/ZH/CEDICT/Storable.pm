package Lingua::ZH::CEDICT::Storable;

# Copyright (c) 2002-2005 Christian Renz <crenz@web42.com>
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;
use warnings;
use vars qw($VERSION @ISA);
use Storable;

$VERSION = '0.03';
@ISA = qw(Lingua::ZH::CEDICT);

sub new {
    my $class = shift;
    my $self = +{@_};

    unless ($self->{filename}) {
        $self->{filename} = __FILE__;
        $self->{filename} =~ s/Storable\.pm/CEDICT.store/;
    }
    bless $self, $class;
}

sub init {
    my $self = shift;

    my $data = retrieve($self->{filename});

    foreach (qw(version entry keysZh keysPinyin keysEn)) {
        $self->{$_} = $data->{$_};
    }
    return 1;
}

sub importData {
    my ($self, $dict) = @_;

    my $data = $dict->exportData();

    foreach (qw(version entry keysZh keysPinyin keysEn)) {
        $self->{$_} = $data->{$_};
    }

    store($data, $self->{filename});
}

1;
__END__

=head1 NAME

Lingua::ZH::CEDICT::Storable - Interface for stored dictionary data

=head1 SYNOPSIS

  use Lingua::ZH::CEDICT;

  # these are the default values; you may omit them
  $dict = Lingua::ZH::CEDICT->new(source   => "Storable",
                                  filename => "$libdir/CEDICT.store");

  # load data from cedict.store
  $dict->init();

  # or import from textfile and store in cedict.store for future use
  $tdict = Lingua::ZH::CEDICT->new{src => "Textfile");
  $dict->importData($tdict);

=head1 DESCRIPTION

This module uses L<Storable|Storable> to load the dictionary data,
which allows for faster startup times.

=head1 METHODS

There are a number of methods you might find useful to work with the
data once it is in memory. They are included and described in
L<Lingua::ZH::CEDICT|Lingua::ZH::CEDICT>, just in case you want to
use them with one of the other interface modules as well.

=head2 C<importData>

Accepts a Lingua::ZH::CEDICT object as parameter. Stores the data from the
dictionary object inside a Storable file.

=head1 PREREQUISITES

L<Lingua::ZH::Cedict|Lingua::ZH::Cedict>.
L<Storable>.

=head1 AUTHOR

Christian Renz, E<lt>crenz@web42.comE<gt>

=head1 LICENSE

Copyright (C) 2002-2005 Christian Renz. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Lingua::ZH::CEDICT>. L<Storable>.

=cut
