use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::MetaData::BuiltWith;

our $VERSION = '1.004005';

# ABSTRACT: Report what versions of things your distribution was built against

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( carp croak );
use Config qw();
use Moose 2.0;
use Moose qw( with has around );
use MooseX::Types::Moose qw( ArrayRef Bool Str );
use Module::Runtime qw( is_module_name );
use Devel::CheckBin qw( can_run );
use Path::Tiny qw( path );
use namespace::autoclean;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::MetaProvider';







sub mvp_multivalue_args { return qw( exclude include ) }










has _exclude => (
  init_arg => 'exclude',
  is       => 'ro',
  isa      => ArrayRef,
  default  => sub { [] },
  traits   => [qw( Array )],
  handles  => { exclude => 'elements', },
);










has _include => (
  init_arg => 'include',
  is       => 'ro',
  isa      => ArrayRef,
  default  => sub { [] },
  traits   => [qw( Array )],
  handles  => { include => 'elements', },

);









has show_config => ( is => 'ro', isa => 'Bool', default => 0 );









has show_uname => ( is => 'ro', isa => Bool, default => 0 );









has uname_call => ( is => 'ro', isa => Str, default => 'uname' );









has uname_args => ( is => 'ro', isa => Str, default => '-a' );
has _uname_args => (
  init_arg   => undef,
  is         => 'ro',
  isa        => ArrayRef,
  lazy_build => 1,
  traits     => [qw( Array )],
  handles    => { _all_uname_args => 'elements', },
);
has _stash_key => ( is => 'ro', isa => Str, default => 'x_BuiltWith' );



























has 'use_external_file' => (
  is         => 'ro',
  lazy_build => 1,
);

















has 'external_file_name' => (
  is         => 'ro',
  isa        => Str,
  lazy_build => 1,
);

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $payload = $config->{ +__PACKAGE__ } = {};

  $payload->{show_uname}         = $self->show_uname;
  $payload->{_stash_key}         = $self->_stash_key;
  $payload->{show_config}        = $self->show_config;
  $payload->{use_external_file}  = $self->use_external_file;
  $payload->{external_file_name} = $self->external_file_name;

  if ( $self->show_uname ) {
    $payload->{'uname'} = {
      uname_call => $self->uname_call,
      uname_args => $self->_uname_args,
    };
  }

  if ( $self->exclude ) {
    $payload->{exclude} = [ $self->exclude ];
  }
  if ( $self->include ) {
    $payload->{include} = [ $self->include ];
  }

  ## no critic (RequireInterpolationOfMetachars)
  # Self report when inherited.
  $payload->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION unless __PACKAGE__ eq ref $self;
  $payload->{q[$Module::Metadata::VERSION]} = $Module::Metadata::VERSION if $INC{'Module/Metadata.pm'};
  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub _config {
  my $self = shift;
  return () unless $self->show_config;
  my @interesting = qw( git_describe git_commit_id git_commit_date myarchname gccversion osname osver );
  my $interested  = {};
  for my $key (@interesting) {
    ## no critic (ProhibitPackageVars)
    if ( defined $Config::Config{$key} and $Config::Config{$key} ne q{} ) {
      $interested->{$key} = $Config::Config{$key};
    }
  }
  return ( 'perl-config', $interested );
}

sub _uname {
  my $self = shift;
  return () unless $self->show_uname;
  {
    my $str;
    if ( not can_run( $self->uname_call ) ) {
      $self->log( q[can't invoke ] . $self->uname_call . q[ on this device] );
      return ();
    }
    last unless open my $fh, q{-|}, $self->uname_call, $self->_all_uname_args;
    while ( my $line = <$fh> ) {
      chomp $line;
      $str .= $line;
    }
    last unless close $fh;
    return ( 'uname', $str );

  }
  ## no critic ( ProhibitPunctuationVars )

  $self->log(q{WARNING: `uname` invocation failed, omit from metadata});

  return ();

}

sub _build__uname_args {
  my $self = shift;
  ## no critic ( RequireDotMatchAnything RequireExtendedFormatting RequireLineBoundaryMatching )
  return [ grep { defined $_ && $_ ne q{} } split /\s+/, $self->uname_args ];
}

sub _build_use_external_file {
  return;
}

sub _build_external_file_name {
  return 'misc/built_with.json';
}





sub metadata {
  my ($self) = @_;
  return {} unless 'only' eq ( $self->use_external_file || q[] );
  return { $self->_stash_key, { external_file => $self->external_file_name }, };
}

sub _get_prereq_modnames {
  my ($self) = @_;

  my $modnames = {};

  my $prereqs = $self->zilla->prereqs->as_string_hash;
  ## use critic
  if ( not %{$prereqs} ) {
    $self->log(q{WARNING: No prereqs were found, probably a bug});
    return [];
  }
  $self->log_debug( [ '%s phases defined: %s ', scalar keys %{$prereqs}, ( join q{,}, keys %{$prereqs} ) ] );

  for my $phase_name ( keys %{$prereqs} ) {
    my $phase_data = $prereqs->{$phase_name};
    next unless defined $phase_data;
    my $phase_deps = {};
    for my $type ( keys %{$phase_data} ) {
      my $type_data = $phase_data->{$type};
      next unless defined $type_data;
      for my $module ( keys %{$type_data} ) {
        $phase_deps->{$module} = 1;
      }
    }
    $self->log_debug( [ 'Prereqs for %s: %s', $phase_name, join q{,}, keys %{$phase_deps} ] );
    $modnames = { %{$modnames}, %{$phase_deps} };

  }
  return [ sort keys %{$modnames} ];
}

sub _detect_installed {
  my ( undef, $module ) = @_;

  croak('Cannot determine a version if module=undef') if not defined $module;

  return [ undef, undef ] if 'perl' eq $module;

  return [ undef, 'not a valid module name' ] if not is_module_name($module);

  my @pmname = split qr/::|'/, $module; ## no critic (RegularExpressions)
  $pmname[-1] .= '.pm';

  my $path;
  for my $incdir (@INC) {
    next if ref $incdir;
    my $fullpath = path( $incdir, @pmname );
    next unless -e $fullpath;
    next if -d $fullpath;
    $path = $fullpath;
    last;
  }

  return [ undef, 'module was not found in INC' ] if not defined $path;

  require Module::Metadata;
  my $mm = Module::Metadata->new_from_file( $path, collect_pod => 0 );
  return [ undef, 'Module::MetaData could not parse ' . $path ] if not defined $mm;

  my $v = $mm->version($module);
  return [ undef, 'Module::MetaData could not parse a version from ' . $path ] if not $v;

  return [ $v, undef ];

}










sub _metadata {
  my ($self) = @_;
  $self->log_debug(q{Metadata called});
  my $report = $self->_get_prereq_modnames();
  $self->log_debug( 'Found mods: ' . scalar @{$report} );
  my %modtable;
  my %failures;

  for my $module ( @{$report}, $self->include ) {
    my $result = $self->_detect_installed($module);
    $modtable{$module} = $result->[0] if defined $result->[0];
    $failures{$module} = $result->[1] if defined $result->[1];
  }

  for my $badmodule ( $self->exclude ) {
    delete $modtable{$badmodule} if exists $modtable{$badmodule};
    delete $failures{$badmodule} if exists $failures{$badmodule};
  }
  ## no critic ( Variables::ProhibitPunctuationVars )
  my $perlver;

  if ( $] < 5.010000 ) {
    $perlver = { %{ version->parse( version->parse($])->normal ) } };
  }
  else {
    $perlver = { %{$^V} };
  }

  my $result = {
    modules  => \%modtable,
    perl     => $perlver,
    platform => $^O,
    $self->_uname(),
    $self->_config(),
  };

  $result->{failures} = \%failures if keys %failures;

  return $result;
}





sub gather_files {
  my ($self) = @_;

  return unless $self->use_external_file;

  my $type =
      $self->external_file_name =~ /[.]json\z/msix  ? 'JSON'
    : $self->external_file_name =~ /[.]ya?ml\z/msix ? 'YAML'
    :                                                 croak 'Cant guess file type for ' . $self->external_file_name;

  my $code;

  if ( 'JSON' eq $type ) {
    require JSON::MaybeXS;
    require Dist::Zilla::File::FromCode;
    my $json = JSON::MaybeXS->new;
    $json->pretty(1);
    $json->canonical(1);
    $json->convert_blessed(1);
    $json->allow_blessed(1);
    $code = sub {
      local *UNIVERSAL::TO_JSON = sub { "$_[0]" };
      return $json->encode( $self->_metadata );
    };
  }
  if ( 'YAML' eq $type ) {
    require YAML::Tiny;
    $code = sub {
      return YAML::Tiny::Dump( $self->_metadata );
    };
  }

  $self->add_file(
    Dist::Zilla::File::FromCode->new(
      name             => $self->external_file_name,
      code             => $code,
      code_return_type => 'text',
    ),
  );
  return;
}

sub munge_files {
  my ($self) = @_;

  my $munged = {};

  return if 'only' eq ( $self->use_external_file || q[] );

  for my $file ( @{ $self->zilla->files } ) {
    if ( 'META.json' eq $file->name ) {
      require JSON::MaybeXS;
      require CPAN::Meta::Converter;
      my $json = JSON::MaybeXS->new->pretty->canonical(1);
      my $old  = $file->code;
      $file->code(
        sub {
          my $content = $json->decode( $old->() );
          $content->{ $self->_stash_key } = $self->_metadata;
          my $normal = CPAN::Meta::Converter->new($content)->convert( version => $content->{'meta-spec'}->{version} );
          return $json->encode($normal);
        },
      );
      $munged->{'META.json'} = 1;
      next;
    }
    if ( 'META.yml' eq $file->name ) {
      require YAML::Tiny;
      require CPAN::Meta::Converter;
      my $old = $file->code;
      $file->code(
        sub {
          my $content = YAML::Tiny::Load( $old->() );
          $content->{ $self->_stash_key } = $self->_metadata;
          my $normal = CPAN::Meta::Converter->new($content)->convert( version => $content->{'meta-spec'}->{version} );
          return YAML::Tiny::Dump($normal);
        },
      );
      $munged->{'META.yml'} = 1;
      next;
    }
  }
  if ( not keys %{$munged} ) {
    my $message = <<'EOF';
No META.* files to munge.
BuiltWith cannot operate without one in tree prior to it
EOF
    $self->log_fatal($message);
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaData::BuiltWith - Report what versions of things your distribution was built against

=head1 VERSION

version 1.004005

=head1 SYNOPSIS

  [MetaData::BuiltWith]
  include = Some::Module::Thats::Not::In::Preq
  exclude = Some::Module::Youre::Ashamed::Of
  show_uname = 1             ; default is 0
  show_config = 1            ; default is 0
  uname_call = uname         ; the default
  uname_args = -s -r -m -p   ; the default is -a
  use_external_file = only   ; the default is undef

=head1 DESCRIPTION

This module provides extra metadata in your distribution, automatically documenting what versions of dependencies the author was
using at the time of release.

This allows consumers of said distributions to be able to see a range of versions that are "known good" should they experience
problems.

=head1 OPTIONS

=head2 exclude

Specify modules to exclude from version reporting

    exclude = Foo
    exclude = Bar

=head2 include

Specify additional modules to include the version of

    include = Foo
    include = Bar

=head2 show_config

Report "interesting" values from C<%Config::Config>

    show_config = 1 ; Boolean

=head2 show_uname

Report the output from C<uname>

    show_uname = 1 ; Boolean

=head2 uname_call

Specify what the system C<uname> function is called

    uname_call = uname ; String

=head2 uname_args

Specify arguments passed to the C<uname> call.

    uname_args = -a ; String

=head2 use_external_file

This option regulates the optional output to an isolated file.

An external file will be created as long as this value is a true value.

  use_external_file = 1

If this true value is the string C<only>, then it won't also be exported to META.yml/META.json

  use_external_file = only

NOTE:

This will still leave an x_BuiltWith section in your META.*, however, its much less fragile
and will simply be:

   x_BuiltWith: {
      external_file: "your/path/here"
   }

This is mostly a compatibility pointer so any tools traversing a distributions history will know where and when to change
behavior.

=head2 external_file_name

This option controls what the external file will be called in conjunction with C<use_external_file>

Default value is:

  misc/built_with.json

Extensions:

  .json => JSON is used.
  .yml  => YAML is used (untested)
  .yaml => YAML is used (untested)

=head1 METHODS

=head2 mvp_multivalue_args

This module can take, as parameters, any volume of 'exclude' or 'include' arguments.

=head2 munge_files

This module scrapes together the name of all modules that exist in the "C<Prereqs>" section
that Dist::Zilla collects, and then works out what version of things you have,
applies the various include/exclude rules, and ships that data back to Dist::Zilla
via this method. See L<< C<Dist::Zilla>'s C<MetaProvider> role|Dist::Zilla::Role::MetaProvider >> for more details.

=for Pod::Coverage metadata

=for Pod::Coverage gather_files

=head1 EXAMPLE OUTPUT ( C<META.json> )

    "x_BuiltWith" : {
       "modules" : {
          "Dist::Zilla::Role::MetaProvider" : "4.101612",
          "File::Find" : "1.15",
          "File::Temp" : "0.22",
          "Module::Build" : "0.3607",
          "Moose" : "1.07",
          "Test::More" : "0.94"
       },
       "perl" : "5.012000",
       "platform" : "MSWin32"
    },

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
