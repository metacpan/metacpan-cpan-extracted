package KiokuDB::LinkChecker;
BEGIN {
  $KiokuDB::LinkChecker::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::LinkChecker::VERSION = '0.57';
use Moose;
# ABSTRACT: Reference consistency checker

use KiokuDB::LinkChecker::Results;

use namespace::clean -except => 'meta';

with 'KiokuDB::Role::Scan' => { result_class => "KiokuDB::LinkChecker::Results" };

sub process_block {
    my ( $self, %args ) = @_;

    my ( $block, $res ) = @args{qw(block results)};

    my ( $seen, $root, $referenced, $unreferenced, $missing, $broken ) = map { $res->$_ } qw(seen root referenced unreferenced missing broken);

    my $backend = $self->backend;

    foreach my $entry ( @$block ) {
        my $id = $entry->id;

        $seen->insert($id);
        $root->insert($id) if $entry->root;

        unless ( $referenced->includes($id) ) {
            $unreferenced->insert($id);
        }

        my @ids = $entry->referenced_ids;

        my @new = grep { !$referenced->includes($_) && !$seen->includes($_) } @ids;

        my %exists;
        @exists{@new} = $backend->exists(@new) if @new;

        if ( my @missing = grep { not $exists{$_} } @new ) {
            $self->v("\rfound broken entry: " . $entry->id . " (references nonexisting IDs @missing)\n");
            $missing->insert(@missing);
            $broken->insert($entry->id);
        }

        $referenced->insert(@ids);
        $unreferenced->remove(@ids);
    }
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::LinkChecker - Reference consistency checker

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    use KiokuDB::LinkChecker;

    my $l = KiokuDB::LinkChecker->new(
        backend => $b,
    );

    my @idw = $l->missing->members; # referenced but not in the DB

=head1 DESCRIPTION

This is the low level link checker used by L<KiokuDB::Cmd::Command::FSCK>.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
