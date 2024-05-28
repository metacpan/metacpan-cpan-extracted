package Dist::Zilla::App::Command::new 6.032;
# ABSTRACT: mint a new dist

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod Creates a new Dist-Zilla based distribution under the current directory.
#pod
#pod   $ dzil new Main::Module::Name
#pod
#pod There are two arguments, C<-p> and C<-P>. C<-P> specify the minting profile
#pod provider and C<-p> - the profile name.
#pod
#pod The default profile provider first looks in the
#pod F<~/.dzil/profiles/$profile_name> and then among standard profiles, shipped
#pod with Dist::Zilla. For example:
#pod
#pod   $ dzil new -p work Corporate::Library
#pod
#pod This command would instruct C<dzil> to look in F<~/.dzil/profiles/work> for a
#pod F<profile.ini> (or other "profile" config file).  If no profile name is given,
#pod C<dzil> will look for the C<default> profile.  If no F<default> directory
#pod exists, it will use a very simple configuration shipped with Dist::Zilla.
#pod
#pod   $ dzil new -P Foo Corporate::Library
#pod
#pod This command would instruct C<dzil> to consult the Foo provider about the
#pod directory of 'default' profile.
#pod
#pod Furthermore, it is possible to specify the default minting provider and profile
#pod in the F<~/.dzil/config.ini> file, for example:
#pod
#pod   [%Mint]
#pod   provider = FooCorp
#pod   profile = work
#pod
#pod =cut

sub abstract { 'mint a new dist' }

sub usage_desc { '%c new %o <ModuleName>' }

sub opt_spec {
  [ 'profile|p=s',  'name of the profile to use' ],

  [ 'provider|P=s', 'name of the profile provider to use' ],

  # [ 'module|m=s@', 'module(s) to create; may be given many times'         ],
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  require MooseX::Types::Perl;

  $self->usage_error('dzil new takes exactly one argument') if @$args != 1;

  my $name = $args->[0];

  $name =~ s/::/-/g if MooseX::Types::Perl::is_ModuleName($name)
               and not MooseX::Types::Perl::is_DistName($name);

  $self->usage_error("$name is not a valid distribution name")
    unless MooseX::Types::Perl::is_DistName($name);

  $args->[0] = $name;
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $dist = $arg->[0];

  my $stash = $self->app->_build_global_stashes;
  my $mint_stash = $stash->{'%Mint'};

  my $provider = $opt->provider // ($mint_stash && $mint_stash->provider) // 'Default';
  my $profile = $opt->profile // ($mint_stash && $mint_stash->profile) // 'default';

  require Dist::Zilla::Dist::Minter;
  my $minter = Dist::Zilla::Dist::Minter->_new_from_profile(
    [ $provider, $profile ],
    {
      chrome  => $self->app->chrome,
      name    => $dist,
      _global_stashes => $stash,
    },
  );

  $minter->mint_dist({
    # modules => $opt->module,
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::new - mint a new dist

=head1 VERSION

version 6.032

=head1 SYNOPSIS

Creates a new Dist-Zilla based distribution under the current directory.

  $ dzil new Main::Module::Name

There are two arguments, C<-p> and C<-P>. C<-P> specify the minting profile
provider and C<-p> - the profile name.

The default profile provider first looks in the
F<~/.dzil/profiles/$profile_name> and then among standard profiles, shipped
with Dist::Zilla. For example:

  $ dzil new -p work Corporate::Library

This command would instruct C<dzil> to look in F<~/.dzil/profiles/work> for a
F<profile.ini> (or other "profile" config file).  If no profile name is given,
C<dzil> will look for the C<default> profile.  If no F<default> directory
exists, it will use a very simple configuration shipped with Dist::Zilla.

  $ dzil new -P Foo Corporate::Library

This command would instruct C<dzil> to consult the Foo provider about the
directory of 'default' profile.

Furthermore, it is possible to specify the default minting provider and profile
in the F<~/.dzil/config.ini> file, for example:

  [%Mint]
  provider = FooCorp
  profile = work

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
