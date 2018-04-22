package Dist::Zilla::Role::AfterRelease 6.012;
# ABSTRACT: something that runs after release is mostly complete

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role have their C<after_release> method called once
#pod the release is done. The archive filename, if one was built, is passed as the
#pod sole argument.
#pod
#pod =cut

requires 'after_release';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::AfterRelease - something that runs after release is mostly complete

=head1 VERSION

version 6.012

=head1 DESCRIPTION

Plugins implementing this role have their C<after_release> method called once
the release is done. The archive filename, if one was built, is passed as the
sole argument.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
