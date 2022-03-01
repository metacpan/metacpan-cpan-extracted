package Git::Lint::Test;

use strict;
use warnings;

use parent 'Test::More';

our $VERSION = '0.010';

sub import {
    my $class = shift;
    my %args  = @_;

    if ( $args{tests} ) {
        $class->builder->plan( tests => $args{tests} )
            unless $args{tests} eq 'no_declare';
    }
    elsif ( $args{skip_all} ) {
        $class->builder->plan( skip_all => $args{skip_all} );
    }

    Test::More->export_to_level(1);

    require Test::Warnings;

    return;
}

sub override {
    my %args = (
        package => undef,
        name    => undef,
        subref  => undef,
        @_,
    );

    eval "require $args{package}";

    my $fullname = sprintf "%s::%s", $args{package}, $args{name};

    no strict 'refs';
    no warnings 'redefine', 'prototype';
    *$fullname = $args{subref};

    return;
}

1;

__END__

=pod

=head1 NAME

Git::Lint::Test - testing module for Git::Lint

=head1 SYNOPSIS

 use Git::Lint::Test;

 ok($got eq $expected, $test_name);

=head1 DESCRIPTION

C<Git::Lint::Test> sets up the testing environment and modules needed for tests.

Methods from C<Test::More> are exported and available for the tests.

=head1 SUBROUTINES

=over

=item override

Overrides subroutines

ARGS are C<package>, C<name>, and C<subref>.

 Git::Lint::Test::override(
     package => 'Git::Lint::Check::Commit',
     name    => '_against',
     subref  => sub { return 'HEAD' },
 );

=back

=head1 AUTHOR

Blaine Motsinger C<blaine@renderorange.com>

=cut
