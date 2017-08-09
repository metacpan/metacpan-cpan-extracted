use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Parser

# ABSTRACT: M4 Macro Parser role

role MarpaX::Languages::M4::Role::Parser {

    our $VERSION = '0.019'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    requires 'parser_isWord';
    requires 'parser_isComment';
    requires 'parser_isQuotedstring';
    requires 'parser_isMacro';
    requires 'parser_isCharacter';
    requires 'parser_tokensPriority';
    requires 'parser_parse';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Parser - M4 Macro Parser role

=head1 VERSION

version 0.019

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
