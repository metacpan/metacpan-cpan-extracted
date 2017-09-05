use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Macros

# ABSTRACT: M4 Macros role

role MarpaX::Languages::M4::Role::Macros {

    our $VERSION = '0.020'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    requires 'macros_isEmpty';
    requires 'macros_push';
    requires 'macros_pop';
    requires 'macros_set';
    requires 'macros_get';
    requires 'macros_elements';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Macros - M4 Macros role

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
