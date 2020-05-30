package Dist::Zilla::Role::AfterBuild 6.015;
# ABSTRACT: something that runs after building is mostly complete

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role have their C<after_build> method called once all
#pod the files have been written out.  It is passed a hashref with the following
#pod data:
#pod
#pod   build_root - the directory in which the dist was built
#pod
#pod =cut

requires 'after_build';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::AfterBuild - something that runs after building is mostly complete

=head1 VERSION

version 6.015

=head1 DESCRIPTION

Plugins implementing this role have their C<after_build> method called once all
the files have been written out.  It is passed a hashref with the following
data:

  build_root - the directory in which the dist was built

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
