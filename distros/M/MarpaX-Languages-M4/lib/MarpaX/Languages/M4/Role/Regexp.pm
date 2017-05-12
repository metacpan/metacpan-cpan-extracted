use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Regexp

# ABSTRACT: M4 Regexp role

role MarpaX::Languages::M4::Role::Regexp {

    our $VERSION = '0.017'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    requires 'regexp_compile';
    requires 'regexp_lpos';
    requires 'regexp_lpos_count';
    requires 'regexp_lpos_get';
    requires 'regexp_rpos';
    requires 'regexp_rpos_count';
    requires 'regexp_rpos_get';
    requires 'regexp_exec';
    requires 'regexp_substitute';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Regexp - M4 Regexp role

=head1 VERSION

version 0.017

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
