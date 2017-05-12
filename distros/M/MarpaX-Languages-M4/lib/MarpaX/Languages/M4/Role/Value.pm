use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Value

# ABSTRACT: M4 Macro Parse Value role

role MarpaX::Languages::M4::Role::Value {

    our $VERSION = '0.017'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    requires 'value_concat';
    requires 'value_push';
    requires 'value_elements';
    requires 'value_firstElement';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Value - M4 Macro Parse Value role

=head1 VERSION

version 0.017

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
