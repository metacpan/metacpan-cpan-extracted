package Dist::Zilla::App::Command::gl 1.0002;

use Modern::Perl;
use Cwd qw(cwd);
use Dist::Zilla::App -command;

## no critic qw(ProhibitAmbiguousNames)
sub abstract    {'use the GitLab plugins from the command-line'}
sub description {'Use the GitLab plugins from the command-line'}
sub usage_desc  {'%c %o [ update | create [<repository>] ]'}

## no critic qw(ProhibitCommaSeparatedStatements)
sub opt_spec {
   [
      'profile|p=s', 'name of the profile to use',
      { default => 'default' }
   ],

      [
      'provider|P=s', 'name of the profile provider to use',
      { default => 'Default' }
      ],
      ;
}
## use critic
sub execute {
   my ( $self, $opt, $arg ) = @_;

   my $zilla = $self->zilla;

   $_->gather_files
      for eval { Dist::Zilla::App->VERSION('7.000') }
      ? $zilla->plugins_with( -FileGatherer )
      : @{ $zilla->plugins_with( -FileGatherer ) };

   if ( $arg->[0] eq 'create' ) {
      require Dist::Zilla::Dist::Minter;

      my $minter = Dist::Zilla::Dist::Minter->_new_from_profile(
         [ $opt->provider, $opt->profile ], {
            chrome => $self->app->chrome,
            name   => $zilla->name,
         },
      );

      my $create = _find_plug( $minter, 'GitLab::Create' );
      my $root   = cwd();
      my $repo   = $arg->[1];
      $create->after_mint(
         {
            mint_root   => $root,
            repo        => $repo,
            description => $zilla->abstract
         }
      );
   }
   elsif ( $arg->[0] eq 'update' ) {
      _find_plug( $zilla, 'GitLab::Update' )->after_release;
   }
}

sub _find_plug {
   my ( $self, $name ) = @_;

   foreach ( @{ $self->plugins } ) {
      return $_ if $_->plugin_name =~ /$name/;
   }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::gl - Use the GitLab plugins from the command-line

=head1 VERSION

version 1.0002

=head1 SYNOPSIS

    # create a new GitLab repository for your dist
    $ dzil gl create [<repository>]

    # update GitLab repo information
    $ dzil gl update

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Use the GitLab plugins from the command-line

