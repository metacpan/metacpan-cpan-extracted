use strict;
use warnings;
package Dist::Zilla::App::Command::version 6.015;
# ABSTRACT: display dzil's version

use Dist::Zilla::App -command;
use App::Cmd::Command::version;
BEGIN {
  ## parent and base dont work here. ??? -- kentnl 2014-10-31
  our @ISA;
  unshift @ISA, 'App::Cmd::Command::version';
}

#pod =head1 SYNOPSIS
#pod
#pod Print dzil version
#pod
#pod   $ dzil --version or $dzil version
#pod
#pod =cut

sub version_for_display {
  my $version_pkg = $_[0]->version_package;
  my $version = ( $version_pkg->VERSION ?
                  $version_pkg->VERSION :
                 'dev' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::version - display dzil's version

=head1 VERSION

version 6.015

=head1 SYNOPSIS

Print dzil version

  $ dzil --version or $dzil version

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
