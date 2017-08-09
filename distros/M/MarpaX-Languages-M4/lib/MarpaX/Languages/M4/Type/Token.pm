use Moops;

# PODNAME: MarpaX::Languages::M4::Type::Token

# ABSTRACT: M4 Token type

library MarpaX::Languages::M4::Type::Token declares M4Token {

    our $VERSION = '0.019'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    declare M4Token, as Enum [qw/COMMENT QUOTEDSTRING WORD CHARACTER/];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Type::Token - M4 Token type

=head1 VERSION

version 0.019

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
