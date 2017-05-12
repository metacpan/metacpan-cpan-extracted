use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Logger

# ABSTRACT: M4 Logger role

role MarpaX::Languages::M4::Role::Logger {

    our $VERSION = '0.017'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    requires 'logger_error';
    requires 'logger_warn';
    requires 'logger_debug';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Logger - M4 Logger role

=head1 VERSION

version 0.017

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
