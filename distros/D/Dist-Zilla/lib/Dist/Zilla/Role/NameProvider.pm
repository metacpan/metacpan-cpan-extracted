package Dist::Zilla::Role::NameProvider 6.011;
# ABSTRACT: something that provides a name for the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role must provide a C<provide_name> method that
#pod will be called when setting the dist's name.
#pod
#pod If a NameProvider offers a name but one has already been set, an
#pod exception will be raised.  If C<provide_name> returns undef, it will be
#pod ignored.
#pod
#pod =cut

requires 'provide_name';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::NameProvider - something that provides a name for the dist

=head1 VERSION

version 6.011

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_name> method that
will be called when setting the dist's name.

If a NameProvider offers a name but one has already been set, an
exception will be raised.  If C<provide_name> returns undef, it will be
ignored.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
