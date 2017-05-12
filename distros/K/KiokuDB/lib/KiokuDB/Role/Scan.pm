package KiokuDB::Role::Scan;
BEGIN {
  $KiokuDB::Role::Scan::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::Scan::VERSION = '0.57';
use MooseX::Role::Parameterized 0.10;
# ABSTRACT: A role for entry scanning.

use namespace::clean -except => 'meta';

parameter result_class => (
    isa => "Str",
    is  => "ro",
    required => 1,
);

role {
    my $meta = shift;

    my $result_class = $meta->result_class;

    with qw(KiokuDB::Role::Verbosity);

    has backend => (
        does => "KiokuDB::Backend::Role::Scan",
        is   => "ro",
        required => 1,
    );

    has scan_all => (
        isa => "Bool",
        is  => "ro",
        default => 1,
    );

    has scan_ids => (
        isa => "Bool",
        is  => "ro",
    );

    has entries => (
        does => "Data::Stream::Bulk",
        is   => "ro",
        lazy_build => 1,
    );

    sub _build_entries {
        my $self = shift;

        my $backend = $self->backend;

        my $set = $self->scan_all ? "all" : "root";
        my $type = $self->scan_ids ? "entry_ids" : "entries";

        my $method = join("_", $set, $type);

        $backend->$method;
    }

    has [qw(block_callback entry_callback)] => (
        isa => "CodeRef|Str",
        is  => "ro",
    );

    has results => (
        isa => $result_class,
        is  => "ro",
        handles => qr/.*/,
        lazy_build => 1,
    );

    requires "process_block";

    method _build_results => sub {
        my $self = shift;

        my $res = $result_class->new;

        my $i = my $j = 0;

        while ( my $next = $self->entries->next ) {
            $i += @$next;
            $j += @$next;

            if ( $j > 13 ) { # luv primes
                $j = 0;
                $self->v("\rscanning... $i");
            }

            $self->process_block( block => $next, results => $res );
        }

        $self->v("\rscanned $i entries      \n");

        return $res;
    }
};

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::Scan - A role for entry scanning.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package My::Entry::Processor;
    use Moose;

    with 'KiokuDB::Role::Scan' => { result_class => "My::Entry::Processor::Results" };

    sub process_block {
        my ( $self, %args ) = @_;

        $args{results}; # intermediate results

        foreach my $entry ( @{ $args{block} } ) {

        }
    }



    my $scan = My::Entry::Processor->new(
        backend => $some_backend,
    );

    my $res = $scan->results;

    $res->foo;

    $scan->foo; # delegates to result

=head1 DESCRIPTION

This role is used by classes like L<KiokuDB::LinkChecker> to scan the whole
database and computing summary results.

=head1 ROLE PARAMETERS

=over 4

=item result_class

The class of the results.

Will be used when creating the results initially by calling C<new> and also
sets up an attribute with delegations.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
