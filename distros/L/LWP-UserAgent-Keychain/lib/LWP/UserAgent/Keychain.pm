package LWP::UserAgent::Keychain;

use strict;
use 5.8.1;
our $VERSION = '0.01';

use Mac::Glue ':all';
use base qw( LWP::UserAgent );

my $keychain = Mac::Glue->new("Keychain Scripting");

sub get_basic_credentials {
    my($self, $realm, $uri, $isproxy) = @_;

    for my $key ($keychain->obj(keys => keychain => "Login.keychain")->get) {
        if ($key->prop('class')->get eq 'cint' and
            $key->prop('server')->get eq $uri->host and
            $key->prop('protocol')->get eq $uri->scheme) {

            my $username = $key->prop('account')->get;
            my $password = $key->prop('password')->get;
            return ($username, $password);
        }
    }

    return (undef, undef);
}

1;
__END__

=encoding utf-8

=for stopwords LWP

=head1 NAME

LWP::UserAgent::Keychain - UserAgent that looks up passwords on Mac OS X keychain

=head1 SYNOPSIS

  use LWP::UserAgent::Keychain;

  my $ua = LWP::UserAgent::Keychain->new;
  $ua->get("http://proteceted.example.com/");

=head1 DESCRIPTION

LWP::UserAgent::Keychain is a LWP UserAgent object and it tries to
lookup username and password on Mac OS X keychain when it encounters
the page secured under HTTP basic or digest authentication.

By default, the tries to find the Internet Key in the keychain named
Login.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mac::Glue>, L<LWP>

=cut
