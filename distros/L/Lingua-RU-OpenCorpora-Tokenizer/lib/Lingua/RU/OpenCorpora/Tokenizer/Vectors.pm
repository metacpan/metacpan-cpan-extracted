package Lingua::RU::OpenCorpora::Tokenizer::Vectors;

use strict;
use warnings;
use parent 'Lingua::RU::OpenCorpora::Tokenizer::List';

our $VERSION = 0.06;

use File::ShareDir qw(dist_dir);

sub new {
    my($class, $args) = @_;

    $args             ||= {};
    $args->{data_dir} ||= dist_dir('Lingua-RU-OpenCorpora-Tokenizer');

    my $self = $class->SUPER::new('vectors', $args);

    $self;
}

sub in_list { $_[0]->{data}{$_[1]} }

sub _parse_list {
    my($self, $list) = @_;

    chomp @$list;
    $self->{data} = +{ map split, @$list };

    return;
}

1;

__END__

=head1 NAME

Lingua::RU::OpenCorpora::Tokenizer::Vectors - represents a file with vectors

=head1 DESCRIPTION

This module inherits most of its code from L<Lingua::RU::OpenCorpora::Tokenizer::List>.

The reason to put this code into a separate class is that vectors file has a slightly different format and needs to be processed in a slightly different manner.

=head1 METHODS

=head2 new([$args])

Constructor.

Takes an optional hashref with arguments:

=over 4

=item data_dir

Path to the directory where vectors file is stored. Defaults to distribution directory (see L<File::ShareDir>).

=back

=head2 in_list($vector)

Given a vector, checks if there is a probability value defined for it.

Returns probability or undef correspondingly.

=head1 SEE ALSO

L<Lingua::RU::OpenCorpora::Tokenizer::List>

L<Lingua::RU::OpenCorpora::Tokenizer::Updater>

L<Lingua::RU::OpenCorpora::Tokenizer>

=head1 AUTHOR

OpenCorpora team L<http://opencorpora.org>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
