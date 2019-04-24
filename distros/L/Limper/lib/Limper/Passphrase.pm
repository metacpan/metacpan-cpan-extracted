package Limper::Passphrase;
$Limper::Passphrase::VERSION = '0.014';
use 5.10.0;
use strict;
use warnings;

1;

__END__

=head1 NAME

Limper::Passphrase - generate and use passphrases with Limper

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  use Authen::Passphrase;
  use Authen::Passphrase::BlowfishCrypt;
  #use Limper::Passphrase;
  use Limper;               # this must come after all extensions

  post '/password' => {
    # get $passphrase and $user somehow
    my $ppr = Authen::Passphrase::BlowfishCrypt->new(cost => 8, salt_random => 1, passphrase => $passphrase);
    # store $ppr->as_rfc2307 for user
  };

  post '/login' => {
    # get $passphrase and $user somehow
    if (Authen::Passphrase->from_rfc2307($user->{passphrase})->match($passphrase)) {
      # set some cookies or something
      'Logged in';
    } else {
      status 401;
      'Unauthorized';
    }
  };

  limp;

=head1 DESCRIPTION

B<Limper::Passphrase> shows you how to deal with passphrases with L<Limper>,
and nothing more.  You might as well use L<M>, but this has documentation.

This also serves to show that you B<don't need to make everything a plugin
for Limper>.  If it's not messing with the request, response, or hooks, it
should not be a plugin.

=head1 EXPORTS

Nothing additional is exported.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Limper>

L<Limper::Extending>

L<M>

=cut
