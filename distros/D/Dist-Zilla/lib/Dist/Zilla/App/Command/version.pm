package Dist::Zilla::App::Command::version 6.032;
# ABSTRACT: display dzil's version

use Dist::Zilla::Pragmas;

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

version 6.032

=head1 SYNOPSIS

Print dzil version

  $ dzil --version or $dzil version

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
