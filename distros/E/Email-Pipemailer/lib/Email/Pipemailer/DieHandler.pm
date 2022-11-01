use strict;
use warnings;
package Email::Pipemailer::DieHandler 1.002;
# ABSTRACT: do not die embarassingly if you screw up your pipemailer

#pod =head1 SYNOPSIS
#pod
#pod   #!/usr/bin/perl
#pod   use Email::Pipemailer::DieHandler -install;
#pod   use strict;
#pod   use warnings;
#pod
#pod   # your code goes here
#pod
#pod Always put the DieHandler before B<anything> else.  You want there to be
#pod B<absolutely> no condition that will cause a bounce, right?  That includes
#pod failure to compile.
#pod
#pod This is also legal:
#pod
#pod   use Email::Pipemailer::DieHandler -install => { logger => sub { ... } };
#pod
#pod The error will be passed to the sub.
#pod
#pod =cut

sub import {
  my ($self, $install, $arg) = @_;
  return unless $install and $install eq '-install';

  $arg ||= {};
  my $logger = $arg->{logger} || sub {};

  $SIG{__DIE__} = sub {
    return if $^S; # don't interfere with evals
    my ($e) = @_;
    defined $^S and eval { $logger->($e); };
    $! = 75;
    die $e;
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::Pipemailer::DieHandler - do not die embarassingly if you screw up your pipemailer

=head1 VERSION

version 1.002

=head1 SYNOPSIS

  #!/usr/bin/perl
  use Email::Pipemailer::DieHandler -install;
  use strict;
  use warnings;

  # your code goes here

Always put the DieHandler before B<anything> else.  You want there to be
B<absolutely> no condition that will cause a bounce, right?  That includes
failure to compile.

This is also legal:

  use Email::Pipemailer::DieHandler -install => { logger => sub { ... } };

The error will be passed to the sub.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
