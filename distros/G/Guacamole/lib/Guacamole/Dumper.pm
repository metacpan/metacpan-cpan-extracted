package Guacamole::Dumper;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Dump Guacamole ASTs
$Guacamole::Dumper::VERSION = '0.007';
use strict;
use warnings;

use List::Util qw/any sum/;
use Exporter "import";

our @EXPORT_OK = qw/dump_tree/;

sub dump_tree {
    my ($tree, $offset) = @_;
    return join "", map "$_\n", _dump_tree_inner($tree, "", $offset);
}

sub _dump_tree_inner {
    my ($tree, $indent, $offset) = @_;
    $indent //= "";
    $offset //= "  ";

    ref $tree eq 'HASH'
        or die "Bad token object: $tree";

    my $head = $tree->{
        $tree->{'type'} eq 'lexeme'
        ? 'value'
        : 'name'
    };

    my @tail = $tree->{'type'} eq 'lexeme'
             ? ()
             : @{ $tree->{'children'} };

    if ( any { ref $_ } @tail ) {
        my @rest = map { ref $_ ? _dump_tree_inner($_, "$indent$offset", $offset) : "$indent$offset'$_'" } @tail;

        my @clean = map { s/^\s+//r } @rest;
        if (sum(map length, @clean) < 40) {
            my @items = ($head, @clean);
            return ("$indent(@items)");
        }

        $rest[-1] .= ")";
        return ("$indent($head", @rest);
    } else {
        my @tailq = map "'$_'", @tail;
        my @items = ($head, @tailq);
        return ("$indent(@items)");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Guacamole::Dumper - Dump Guacamole ASTs

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Gaucamole;
    use Guacamole::Dump qw< dump_tree >;
    dump_tree( Gaucamole->parse($string) );

=head1 WHERE'S THE REST?

Soon.

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
