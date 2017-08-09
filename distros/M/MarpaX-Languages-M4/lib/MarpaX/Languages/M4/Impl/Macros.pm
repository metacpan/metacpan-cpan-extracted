use Moops;

# PODNAME: MarpaX::Languages::M4::Impl::Macros

# ABSTRACT: M4 Macro list generic implementation

class MarpaX::Languages::M4::Impl::Macros {
    use MarpaX::Languages::M4::Role::Macros;
    use MarpaX::Languages::M4::Type::Macro -all;
    use MooX::HandlesVia;

    our $VERSION = '0.019'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    has _macrosList => (
        is          => 'rwp',
        isa         => ArrayRef [M4Macro],
        default     => sub { [] },
        handles_via => 'Array',
        handles     => {
            macros_isEmpty  => 'is_empty',
            macros_push     => 'push',
            macros_pop      => 'pop',
            macros_set      => 'set',
            macros_get      => 'get',
            macros_elements => 'elements'
        }
    );

    with 'MarpaX::Languages::M4::Role::Macros';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Impl::Macros - M4 Macro list generic implementation

=head1 VERSION

version 0.019

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
