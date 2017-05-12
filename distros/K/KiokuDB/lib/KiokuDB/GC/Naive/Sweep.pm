package KiokuDB::GC::Naive::Sweep;
BEGIN {
  $KiokuDB::GC::Naive::Sweep::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::GC::Naive::Sweep::VERSION = '0.57';
use Moose;

use namespace::clean -except => 'meta';

use KiokuDB::GC::Naive::Mark;

with 'KiokuDB::Role::Scan' => { result_class => "KiokuDB::GC::Naive::Sweep::Results" };

{
    package KiokuDB::GC::Naive::Sweep::Results;
BEGIN {
  $KiokuDB::GC::Naive::Sweep::Results::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::GC::Naive::Sweep::Results::VERSION = '0.57';
    use Moose;

    use Set::Object;

    has [qw(garbage)] => (
        isa => "Set::Object",
        is  => "ro",
        default => sub { Set::Object->new },
    );

    __PACKAGE__->meta->make_immutable;
}

has '+scan_ids' => ( default => 1 );

has mark_results => (
    isa => "KiokuDB::GC::Naive::Mark::Results",
    is  => "ro",
    required => 1,
    handles => qr/.*/,
);

sub process_block {
    my ( $self, %args ) = @_;

    my ( $ids, $res ) = @args{qw(block results)};

    my $seen = $self->seen;

    my @garbage = grep { not $seen->includes($_) } @$ids;

    $res->garbage->insert(@garbage);
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::GC::Naive::Sweep

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
