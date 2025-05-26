package Dist::Zilla::Stash::OnePasswordLogin 0.002;
# ABSTRACT: get login credentials from 1Password

#pod =head1 OVERVIEW
#pod
#pod This is a stash class, one of the less-often seen kinds of Dist::Zilla
#pod components.  It's expected that you'll use it for things that expect a "Login"
#pod stash credential, like the UploadToCPAN plugin.  Starting with Dist::Zilla
#pod v6.032, you can use any Login credential (not just a PAUSE-specific) one for
#pod the UploadToCPAN plugin.  You need to configure the stash in your home
#pod directory's dzil configuration, probably C<~/.dzil/config.ini>, like this:
#pod
#pod   [%OnePasswordLogin / %PAUSE]
#pod   item = op://Vault Name/PAUSE Credential Name
#pod
#pod If you've got a "username" and "password" field on that vault item, this should
#pod just work!
#pod
#pod This uses L<Password::OnePassword::OPCLI> under the hood.  You'll need to have
#pod that installed, and you'll need to be able to authenticate with 1Password,
#pod meaning that this stash isn't useful for automated build-and-release pipelines.
#pod
#pod =cut

use Moose;
use Dist::Zilla::Pragmas;

use Password::OnePassword::OPCLI;

has item => (
  reader   => '_item_str',
  isa      => 'Str',
  required => 1,
);

has _item => (
  is => 'ro',
  init_arg => undef,
  lazy     => 1,
  default  => sub ($self) {
    my $one_pw = Password::OnePassword::OPCLI->new;
    my $struct = $one_pw->get_item($self->_item_str);

    my $field_aref = $struct->{fields};
    my %fields = map {; $_->{id} => $_->{value} } @$field_aref;

    return \%fields;
  },
);

sub username ($self) { $self->_item->{username} }
sub password ($self) { $self->_item->{password} }

with 'Dist::Zilla::Role::Stash::Login';
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Stash::OnePasswordLogin - get login credentials from 1Password

=head1 VERSION

version 0.002

=head1 OVERVIEW

This is a stash class, one of the less-often seen kinds of Dist::Zilla
components.  It's expected that you'll use it for things that expect a "Login"
stash credential, like the UploadToCPAN plugin.  Starting with Dist::Zilla
v6.032, you can use any Login credential (not just a PAUSE-specific) one for
the UploadToCPAN plugin.  You need to configure the stash in your home
directory's dzil configuration, probably C<~/.dzil/config.ini>, like this:

  [%OnePasswordLogin / %PAUSE]
  item = op://Vault Name/PAUSE Credential Name

If you've got a "username" and "password" field on that vault item, this should
just work!

This uses L<Password::OnePassword::OPCLI> under the hood.  You'll need to have
that installed, and you'll need to be able to authenticate with 1Password,
meaning that this stash isn't useful for automated build-and-release pipelines.

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

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
