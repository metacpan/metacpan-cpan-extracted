package Forest::Tree::Roles::HasNodeFormatter;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

has 'node_formatter' => (
    is      => 'rw',
    isa     => 'CodeRef|Str',
    lazy    => 1,
    default => sub {
        sub { (shift)->node  || 'undef' }
    }
);

sub format_node {
    my ( $self, $node, @args ) = @_;

    my $fmt = $self->node_formatter;

    $node->$fmt(@args);
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Roles::HasNodeFormatter - Simple role for custom node formatters

=head1 DESCRIPTION

Simple role for nodes that have custom formatters

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
