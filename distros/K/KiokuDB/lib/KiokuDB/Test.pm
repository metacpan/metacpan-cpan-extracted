package KiokuDB::Test;
BEGIN {
  $KiokuDB::Test::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::VERSION = '0.57';
use strict;
use warnings;
# ABSTRACT: Reusable tests for KiokuDB backend authors.

use Scalar::Util qw(blessed);
use Test::More;

use Module::Pluggable::Object;

use namespace::clean;

use Sub::Exporter -setup => {
    exports => [qw(run_all_fixtures)],
    groups  => { default => [-all] },
};

my $mp = Module::Pluggable::Object->new(
    search_path => "KiokuDB::Test::Fixture",
    require     => 1,
);

my @fixtures = sort { $a->sort <=> $b->sort } $mp->plugins;

sub run_all_fixtures {
    my ( $with ) = @_;

    my $get_dir = blessed($with) ? sub { $with } : $with;

    for ( 1 .. ( $ENV{KIOKUDB_REPEAT_FIXTURES} || 1 ) ) {
        require List::Util and @fixtures = List::Util::shuffle(@fixtures) if $ENV{KIOKUDB_SHUFFLE_FIXTURES};
        foreach my $fixture ( @fixtures ) {
            next if $ENV{KIOKUDB_FIXTURE} and $fixture->name ne $ENV{KIOKUDB_FIXTURE};
            $fixture->new( get_directory => $get_dir )->run;
        }
    }
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test - Reusable tests for KiokuDB backend authors.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    use Test::More;

    use KiokuDB::Test;

    use KiokuDB::Backend::MySpecialBackend;

    my $b = KiokuDB::Backend::MySpecialBackend->new( ... );

    run_all_fixtures( KiokuDB->new( backend => $b ) );

    done_testing();

=head1 DESCRIPTION

This module loads and runs L<KiokuDB::Test::Fixture>s against a L<KiokuDB>
directory instance.

=head1 EXPORTS

=over 4

=item run_all_fixtures $dir

=item run_all_fixtures sub { return $dir }

Runs all the L<KiokuDB::Test::Fixture> objects against your dir.

If you need a new instance of L<KiokuDB> for every fixture, pass in a code
reference.

This will load all the modules in the L<KiokuDB::Test::Fixture> namespace, and
run them against your directory.

Fixtures generally check for backend roles and skip unless the backend supports
that set of features.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
