use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Impl

# ABSTRACT: M4 implementation role

role MarpaX::Languages::M4::Role::Impl {

    our $VERSION = '0.019'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    use MarpaX::Languages::M4::Role::Builtin;
    use MarpaX::Languages::M4::Role::Logger;
    use MarpaX::Languages::M4::Role::Parser;

    requires 'impl_quote';
    requires 'impl_unquote';
    requires 'impl_appendValue';
    requires 'impl_value';
    requires 'impl_valueRef';
    requires 'impl_parseIncremental';
    requires 'impl_parseIncrementalFile';
    requires 'impl_parse';
    requires 'impl_unparsed';
    requires 'impl_setEoi';
    requires 'impl_eoi';
    requires 'impl_raiseException';
    requires 'impl_program';
    requires 'impl_file';
    requires 'impl_line';
    requires 'impl_rc';
    requires 'impl_isImplException';
    requires 'impl_macroExecuteHeader';
    requires 'impl_macroExecuteNoHeader';
    requires 'impl_macroExecute';
    requires 'impl_macroCallId';
    requires 'impl_reloadState';
    requires 'impl_freezeState';
    requires 'impl_nbInputProcessed';
    requires 'impl_readFromStdin';
    requires 'impl_canLog';
    requires 'impl_debugFile';
    requires 'impl_nestingLimit';

    with 'MarpaX::Languages::M4::Role::Builtin';
    with 'MarpaX::Languages::M4::Role::Logger';
    with 'MarpaX::Languages::M4::Role::Parser';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Impl - M4 implementation role

=head1 VERSION

version 0.019

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
