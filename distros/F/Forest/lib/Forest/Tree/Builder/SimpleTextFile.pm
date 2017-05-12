package Forest::Tree::Builder::SimpleTextFile;
use Moose;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

no warnings 'recursion';

with qw(Forest::Tree::Builder::Callback); # for compatibility with overriding create_new_subtree, otherwise invisible

has fh => (
    isa => "FileHandle",
    is  => "ro",
    required => 1,
);

has 'tab_width' => (
    is      => 'rw',
    isa     => 'Int',
    default => 4
);

has 'parser' => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    builder => 'build_parser',
);

sub build_parser {
    return sub {
        my ($self, $line) = @_;
        my ($indent, $node) = ($line =~ /^(\s*)(.*)$/);
        my $depth = ((length $indent) / $self->tab_width);
        return ($depth, $node);
    }
}

sub parse_line { $_[0]->parser->(@_) }

sub _build_subtrees {
    my $self = shift;

    my $cur_children = [];
    my @stack;

    my $fh = $self->fh;

    while ( defined(my $line = <$fh>) ) {

        chomp($line);

        next if !$line || $line =~ /^#/;

        my ($depth, $node, @rest) = $self->parse_line($line);

        if ( $depth > @stack ) {
            if ( $depth = @stack + 1 ) {
                push @stack, $cur_children;
                $cur_children = $cur_children->[-1]{children} = [];
            } else {
                die "Parse Error : the difference between the depth ($depth) and " .
                    "the tree depth (" . scalar(@stack)  . ") is too much (" .
                    ($depth - @stack) . ") at line:\n'$line'";
            }
        } elsif ( $depth < @stack ) {
            while ( $depth < @stack ) {
                foreach my $node ( @$cur_children ) {
                    $node = $self->create_new_subtree(%$node);
                }

                $cur_children = pop @stack;
            }
        }

        push @$cur_children, { node => $node, @rest };
    }

    while ( @stack ) {
        $_ = $self->create_new_subtree(%$_) for @$cur_children;
        $cur_children = pop @stack;
    }

    return [ map { $self->create_new_subtree(%$_) } @$cur_children ];
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=head1 NAME

Forest::Tree::Builder::SimpleTextFile - Parse trees from indented ASCII files

=head1 SYNOPSIS

    use Path::Class;

    my $file = file($path);

    my $builder = Forest::Tree::Builder::SimpleTextFile->new(
        fh => $file->openr,
    );

    my $tree = $builder->tree;

=head1 DESCRIPTION

This module replaces L<Forest::Tree::Reader::SimpleTextFile> with a declarative
api instead of an imperative one.

=head1 ATTRIBUTES

=over 4

=item fh

The filehandle to read from.

Required.

=item parser

A coderef that parses a single line from C<fh> and returns the node depth and
its value.

Defaults to space indented text. See also L</tab_width>.

=item tab_width

The indentation level for the default parser. Defaults to 4, which means that
four spaces equate to one level of nesting.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


