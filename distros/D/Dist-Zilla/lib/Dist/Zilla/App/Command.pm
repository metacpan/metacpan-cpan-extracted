package Dist::Zilla::App::Command 6.032;
# ABSTRACT: base class for dzil commands

use Dist::Zilla::Pragmas;

use App::Cmd::Setup -command;

#pod =method zilla
#pod
#pod This returns the Dist::Zilla object in use by the command.  If none has yet
#pod been constructed, one will be by calling C<< Dist::Zilla->from_config >>.
#pod
#pod (This method just delegates to the Dist::Zilla::App object!)
#pod
#pod =cut

sub zilla {
  return $_[0]->app->zilla;
}

#pod =method log
#pod
#pod This method calls the C<log> method of the application's chrome.
#pod
#pod =cut

sub log {
  $_[0]->app->chrome->logger->log($_[1]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command - base class for dzil commands

=head1 VERSION

version 6.032

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

=head1 METHODS

=head2 zilla

This returns the Dist::Zilla object in use by the command.  If none has yet
been constructed, one will be by calling C<< Dist::Zilla->from_config >>.

(This method just delegates to the Dist::Zilla::App object!)

=head2 log

This method calls the C<log> method of the application's chrome.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
