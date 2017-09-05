use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Builtin

# ABSTRACT: M4 Builtin role

role MarpaX::Languages::M4::Role::Builtin {

    our $VERSION = '0.020'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    #
    # Only the POSIX builtins are explicitely listed
    # here. Extensions per implementation are
    # of course allowed.
    #
    requires 'builtin_define';
    requires 'builtin_undefine';
    requires 'builtin_defn';
    requires 'builtin_pushdef';
    requires 'builtin_popdef';
    requires 'builtin_indir';
    requires 'builtin_builtin';
    requires 'builtin_ifdef';
    requires 'builtin_ifelse';
    requires 'builtin_shift';
    requires 'builtin_dumpdef';
    requires 'builtin_traceon';
    requires 'builtin_traceoff';
    requires 'builtin_debugmode';
    requires 'builtin_debugfile';
    requires 'builtin_dnl';
    requires 'builtin_changequote';
    requires 'builtin_changecom';
    requires 'builtin_changeword';
    requires 'builtin_m4wrap';
    requires 'builtin_include';
    requires 'builtin_sinclude';
    requires 'builtin_divert';
    requires 'builtin_undivert';
    requires 'builtin_divnum';
    requires 'builtin_len';
    requires 'builtin_index';
    requires 'builtin_regexp';
    requires 'builtin_substr';
    requires 'builtin_translit';
    requires 'builtin_patsubst';
    requires 'builtin_format';
    requires 'builtin_incr';
    requires 'builtin_decr';
    requires 'builtin_eval';
    requires 'builtin_syscmd';
    requires 'builtin_esyscmd';
    requires 'builtin_sysval';
    requires 'builtin_mkstemp';
    requires 'builtin_maketemp';
    requires 'builtin_errprint';
    requires 'builtin___file__';
    requires 'builtin___line__';
    requires 'builtin___program__';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Builtin - M4 Builtin role

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
