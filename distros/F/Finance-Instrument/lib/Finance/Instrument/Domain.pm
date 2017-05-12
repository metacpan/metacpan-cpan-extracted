package Finance::Instrument::Domain;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Moose;
use methods;
use File::ShareDir ();
use YAML::Syck qw(LoadFile);
use Text::CSV;
use Finance::Instrument::Exchange;

has instruments => (is => "rw", isa => "HashRef", default => sub { {} });
has exchanges => (is => "rw", isa => "HashRef",
                  traits  => ['Hash'],
                  default => sub { {} },
                  handles   => {
                      get_exchange     => 'get'
                  });

my $GLOBAL;

method global {
    $GLOBAL ||= __PACKAGE__->new;
}

method load_default_exchanges {
    my $file = File::ShareDir::dist_file('Finance-Instrument', 'iso10383_mic.csv');
    open my $fh, '<:encoding(utf8)', $file or die "$file: $!";
    my $csv = Text::CSV->new;
    my $header = $csv->getline( $fh );
    my %header_map = (
        'MIC' => 'code',
        'INSTITUTION DESCRIPTION' => 'name',
        'CC' => 'country',
        'ACR' => 'abbr',
    );
    while ( my $row = $csv->getline( $fh ) ) {
        my $entry = {};
        @{$entry}{@$header} = @$row;
        Finance::Instrument::Exchange->new(
            domain => $self,
            map { $header_map{$_} => $entry->{$_} } keys %header_map
        );
    }
}


method add_exchange($ex) {
    $self->exchanges->{ $ex->code } = $ex;
}

method load_instrument($args) {
    my $type = delete $args->{type};
    $type = 'Finance::Instrument::'.$type
        unless $type =~ s/^\+//;
    Class::Load::load_class($type);

    unless (ref $args->{exchange}) {
        my $exchange_name = delete $args->{exchange};
        $args->{exchange} = $self->exchanges->{$exchange_name}
            ||= Finance::Instrument::Exchange->new( name => $exchange_name,
                                                    code => $exchange_name,
                                                    domain => $self);
    }

    $type->new(%$args, domain => $self);
}

method load_instrument_from_yml($file) {
    $self->load_instrument(LoadFile($file));
}

method load_default_instrument($name) {
    $self->load_instrument_from_yml(File::ShareDir::dist_file('Finance-Instrument', $name.'.yml'));
}

method add($i) {
    $self->instruments->{ $i->exchange->code.'.'.$i->code } = $i;
}

method get($name) {
    $self->instruments->{ $name };
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Finance::Instrument -

=head1 SYNOPSIS

  use Finance::Instrument;

=head1 DESCRIPTION

Finance::Instrument is

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
