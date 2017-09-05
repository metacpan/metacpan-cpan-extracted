use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Macro

# ABSTRACT: M4 Macro role

role MarpaX::Languages::M4::Role::Macro {

    our $VERSION = '0.020'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    requires 'macro_name';
    requires 'macro_execute';
    requires 'macro_expansion';
    requires 'macro_needParams';
    requires 'macro_paramCanBeMacro';
    requires 'macro_postMatchLengthExecute';
    requires 'macro_isBuiltin';
    requires 'macro_clone';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Macro - M4 Macro role

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
