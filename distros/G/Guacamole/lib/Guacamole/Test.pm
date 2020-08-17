package Guacamole::Test;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: What Guacamole uses to test itself
$Guacamole::Test::VERSION = '0.007';
use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Guacamole;
use Guacamole::Dumper qw/dump_tree/;

use Exporter "import";

our @EXPORT = qw(
    parses
    parses_as
    parsent
    done_testing
);

sub parses {
    my ($text) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @trees;
    eval { @trees = Guacamole->parse($text); }
    or do { diag($@); };

    # debugging
    # use DDP;
    # my @dumped_trees = map dump_tree($_), @trees;
    # p @dumped_trees;

    is( scalar(@trees), 1, "'$text': parsed unambiguously" );
    return \@trees;
}

sub parses_as {
    my ( $text, $user_trees ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $trees             = parses($text);
    my @dumped_trees      = map dump_tree($_), @{$trees};
    my @dumped_user_trees = map dump_tree($_), @{$user_trees};

    is_deeply(
        \@dumped_user_trees,
        \@dumped_trees,
        "'$text': parsed exactly as expected",
    );
}

sub parsent {
    my ($text) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @trees;
    my $res = eval {
        @trees = Guacamole->parse($text);
        1;
    };
    my $err = $@;
    ok( !defined $res && defined $err, "'$text': did not parse" );

    foreach my $tree (@trees) {
        diag( dump_tree($tree) );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Guacamole::Test - What Guacamole uses to test itself

=head1 VERSION

version 0.007

=head1 SYNOPSIS

You don't really need to use this.

=head1 WHERE'S THE REST?

Working on it.

=head1 SEE ALSO

L<Guacamole>

=head1 AUTHORS

=over 4

=item *

Sawyer X

=item *

Vickenty Fesunov

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
