use Moops;

# PODNAME: MarpaX::Languages::M4::Role::Input

# ABSTRACT: M4 Input role

role MarpaX::Languages::M4::Role::Input {

    our $VERSION = '0.017'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    requires 'input_push';
    requires 'input_resize';
    requires 'input_rename';
    requires 'input_consumed';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Role::Input - M4 Input role

=head1 VERSION

version 0.017

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
