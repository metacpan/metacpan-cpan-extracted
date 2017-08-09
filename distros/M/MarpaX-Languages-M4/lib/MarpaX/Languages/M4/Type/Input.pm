use Moops;

# PODNAME: MarpaX::Languages::M4::Type::Input

# ABSTRACT: M4 Input type

library MarpaX::Languages::M4::Type::Input declares M4Input {

    our $VERSION = '0.019'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    declare M4Input, as ConsumerOf ['MarpaX::Languages::M4::Role::Input'];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Type::Input - M4 Input type

=head1 VERSION

version 0.019

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
