use 5.14.0;
use strict;
use warnings;

package Dist::Iller::DocType::Global;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Settings used in multiple other DocTypes
our $VERSION = '0.1411';

use Dist::Iller::Elk;
use Path::Tiny;
use Types::Standard qw/ArrayRef Str/;
with qw/
    Dist::Iller::DocType
/;

has distribution_name => (
    is => 'rw',
    isa => Str,
    predicate => 1,
);

sub comment_start { }

sub filename { }

sub phase { 'first' }

sub to_hash { {} }

sub parse {
    my $self = shift;
    my $yaml = shift;

    if(exists $yaml->{'distribution_name'}) {
        $self->distribution_name($yaml->{'distribution_name'});
    }
}

sub to_string { }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::DocType::Global - Settings used in multiple other DocTypes

=head1 VERSION

Version 0.1411, released 2020-01-01.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
