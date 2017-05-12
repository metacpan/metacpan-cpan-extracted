package Finance::Instrument::Exchange;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Moose;
use methods;

has domain => (is => "ro", isa => "Finance::Instrument::Domain", weak_ref => 1,
               default => sub { Finance::Instrument::Domain->global });

has name => (is => "ro", isa => "Str");
has abbr => (is => "ro", isa => "Str");
has code => (is => "ro", isa => "Str");

has attributes => (is => "rw", isa => "HashRef",
                   traits  => ['Hash'],
                   default => sub { {} },
                   handles   => {
                       attr     => 'accessor'
                   });

method BUILD {
    $self->domain->add_exchange($self);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Finance::Instrument::Futures -

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
