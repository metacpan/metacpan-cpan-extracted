use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Author::KENTNL::TravisCI;

our $VERSION = '0.001004';

# ABSTRACT: A specific subclass of TravisCI that does horrible things

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( extends has around );
extends 'Dist::Zilla::Plugin::TravisCI';

use Path::Tiny qw(path);

has skip_perls => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has fail_perls => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { ['5.8'] } );

around mvp_multivalue_args => sub {
  my ( $orig, $self, @args ) = @_;
  return ( $self->$orig(@args), qw( skip_perls fail_perls ) );
};

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{skip_perls} = $self->skip_perls;
  $localconf->{fail_perls} = $self->fail_perls;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;





sub modify_travis_yml {
  my ( $self, %yaml ) = @_;
  my $allow_failures = [
    ( map { +{ perl => $_ } } @{ $self->fail_perls } ),
    { env => 'STERILIZE_ENV=0 RELEASE_TESTING=1 AUTHOR_TESTING=1' },
    { env => 'STERILIZE_ENV=0 DEVELOPER_DEPS=1' },
  ];

  my (%skip_perls) = map { $_ => 1 } @{ $self->skip_perls };
  my (@sterile_perls) = grep { not exists $skip_perls{$_} } '5.8', '5.10', '5.20';
  my (@normal_perls) = grep { not exists $skip_perls{$_} } '5.8', '5.10', '5.12', '5.14', '5.16', '5.20', '5.21';

  my $include = [
    { perl => '5.21', env => 'STERILIZE_ENV=0 COVERAGE_TESTING=1' },
    { perl => '5.21', env => 'STERILIZE_ENV=1' },
    ( map { +{ perl => $_, env => 'STERILIZE_ENV=0' } } @normal_perls ),
    ( map { +{ perl => $_, env => 'STERILIZE_ENV=1' } } @sterile_perls ),
    { perl => '5.21', env => 'STERILIZE_ENV=0 DEVELOPER_DEPS=1' },
    { perl => '5.21', env => 'STERILIZE_ENV=0 RELEASE_TESTING=1 AUTHOR_TESTING=1' },
  ];
  $yaml{matrix} = {
    allow_failures => $allow_failures,
    include        => $include,
  };
  $yaml{before_install} = [
    'perlbrew list',
    ## no critic (ValuesAndExpressions::RestrictLongStrings)
    'time git clone --depth 10 https://github.com/kentfredric/travis-scripts.git maint-travis-ci',
    'time git -C ./maint-travis-ci reset --hard master',
    'time perl ./maint-travis-ci/branch_reset.pl',
    'time perl ./maint-travis-ci/sterilize_env.pl',
  ];
  $yaml{install} = [
    'time perl ./maint-travis-ci/install_deps_early.pl',
    'time perl ./maint-travis-ci/autoinstall_dzil.pl',
    'time perl ./maint-travis-ci/install_deps_2.pl',
  ];
  $yaml{before_script} = [ 'time perl ./maint-travis-ci/before_script.pl', ];
  $yaml{script}        = [ 'time perl ./maint-travis-ci/script.pl', ];
  $yaml{after_failure} = [ 'perl ./maint-travis-ci/report_fail_ctx.pl', ];
  $yaml{branches}      = { only => [ 'master', 'builds', 'releases', ] };
  $yaml{sudo}          = 'false';
  delete $yaml{perl};

  my $script = path( $self->zilla->root, 'maint', 'travisci.pl' )->absolute->stringify;
  {
    if ( -e $script ) {
      local ( $@, $! );    ## no critic (Variables::RequireInitializationForLocalVars)
      my $callback = do $script;
      $self->log_fatal("$@ $!") if $@ or $!;
      $self->log_fatal('Did not return a callback') unless ref $callback;
      $callback->( \%yaml );
    }
  }
  return %yaml;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::KENTNL::TravisCI - A specific subclass of TravisCI that does horrible things

=head1 VERSION

version 0.001004

=head1 DESCRIPTION

B<NO USER SERVICEABLE PARTS INSIDE>

B<CHOKING HAZARD>

=for Pod::Coverage modify_travis_yml

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
