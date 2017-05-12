use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::ExpandINI;

our $VERSION = '0.003003';

# ABSTRACT: Read an INI file and expand bundles as you go.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Moo 1.000008 qw( has );
use Scalar::Util qw( blessed );
use Dist::Zilla::Util::BundleInfo 1.001000;

has '_data' => (
  is      => 'rw',
  lazy    => 1,
  default => sub { [] },
);

has '_reader_class' => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    require Dist::Zilla::Util::ExpandINI::Reader;
    return 'Dist::Zilla::Util::ExpandINI::Reader';
  },
  handles => {
    _read_file   => read_file   =>,
    _read_string => read_string =>,
    _read_handle => read_handle =>,
  },
);
has '_writer_class' => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    require Dist::Zilla::Util::ExpandINI::Writer;
    return 'Dist::Zilla::Util::ExpandINI::Writer';
  },
  handles => {
    _write_file   => write_file   =>,
    _write_string => write_string =>,
    _write_handle => write_handle =>,
  },
);

has 'include_does' => (
  is      => 'ro',
  default => sub { [] },
);

has 'exclude_does' => (
  is      => 'ro',
  default => sub { [] },
);

my $valid_comment_types = {
  'all'        => 1,
  'none'       => 1,
  'authordeps' => 1,
};

has 'comments' => (
  is  => 'rw',
  isa => sub { croak 'comments accepts all, none or authordeps' unless exists $valid_comment_types->{ $_[0] } },
  default => sub { return 'all' },
);

sub _load_file {
  my ( $self, $name ) = @_;
  $self->_data( $self->_read_file($name) );
  return;
}

sub _load_string {
  my ( $self, $content ) = @_;
  $self->_data( $self->_read_string($content) );
  return;
}

sub _load_handle {
  my ( $self, $handle ) = @_;
  $self->_data( $self->_read_handle($handle) );
  return;
}

sub _store_file {
  my ( $self, $name ) = @_;
  $self->_write_file( $self->_data, $name );
  return;
}

sub _store_string {
  my ($self) = @_;
  return $self->_write_string( $self->_data );
}

sub _store_handle {
  my ( $self, $handle ) = @_;
  $self->_write_handle( $self->_data, $handle );
  return;
}










sub filter_file {
  my ( $class, $input_fn, $output_fn ) = @_;
  my $self = $class;
  if ( not blessed $class ) {
    $self = $class->new;
  }
  local $self->{_data} = {};    # contamination avoidance.
  $self->_load_file($input_fn);
  $self->_expand();
  $self->_store_file($output_fn);
  return;
}









sub filter_handle {
  my ( $class, $input_fh, $output_fh ) = @_;
  my $self = $class;
  if ( not blessed $class ) {
    $self = $class->new;
  }
  local $self->{_data} = {};    # contamination avoidance.
  $self->_load_handle($input_fh);
  $self->_expand();
  $self->_store_handle($output_fh);
  return;
}









sub filter_string {
  my ( $class, $input_string ) = @_;
  my $self = $class;
  if ( not blessed $class ) {
    $self = $class->new;
  }
  local $self->{_data} = {};    # contamination avoidance.
  $self->_load_string($input_string);
  $self->_expand();
  return $self->_store_string;
}

sub _includes_module {
  my ( $self, $module ) = @_;
  return 1 unless @{ $self->include_does };
  require Module::Runtime;
  Module::Runtime::require_module($module);
  for my $include ( @{ $self->include_does } ) {
    return 1 if $module->does($include);
  }
  return;
}

sub _excludes_module {
  my ( $self, $module ) = @_;
  return unless @{ $self->exclude_does };
  require Module::Runtime;
  Module::Runtime::require_module($module);
  for my $exclude ( @{ $self->exclude_does } ) {
    return 1 if $module->does($exclude);
  }
  return;
}

sub _include_module {
  my ( $self, $module ) = @_;
  return unless $self->_includes_module($module);
  return if $self->_excludes_module($module);
  return 1;
}

sub _expand {
  my ($self) = @_;
  my @out;
  my @in = @{ $self->_data };
  while (@in) {
    my $tip = shift @in;

    $tip->{comment_lines} = $self->_clean_comment_lines( $tip->{comment_lines} );

    if ( $tip->{name} and '_' eq $tip->{name} ) {
      push @out, $tip;
      next;
    }
    if ( $tip->{package} and $tip->{package} !~ /\A\@/msx ) {
      push @out, $tip;
      next;
    }

    # Handle bundle
    my $bundle = Dist::Zilla::Util::BundleInfo->new(
      bundle_name    => $tip->{package},
      bundle_payload => $tip->{lines},
    );
    for my $plugin ( $bundle->plugins ) {
      next unless $self->_include_module( $plugin->module );
      my $rec = { package => $plugin->short_module };
      $rec->{name}  = $plugin->name;
      $rec->{lines} = [ $plugin->payload_list ];
      push @out, $rec;
    }

    # Inject any comments from under a bundle
    $out[-1]->{comment_lines} = $tip->{comment_lines};

  }
  $self->_data( \@out );
  return;
}

sub _clean_comment_lines {
  my ( $self, $lines ) = @_;
  return $lines if q[all] eq $self->comments;
  return [ grep { /\A\s*authordep\s+/msx } @{$lines} ] if q[authordeps] eq $self->comments;
  return [];
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::ExpandINI - Read an INI file and expand bundles as you go.

=head1 VERSION

version 0.003003

=head1 SYNOPSIS

  # Write a dist.ini with a bundle anywhere you like
  my $string = <<"EOF";
  name = Foo
  version = 1.000

  [@Some::Author]
  EOF

  path('dist.ini.meta')->spew($string);

  # Generate a copy with bundles inlined.
  use Dist::Zilla::Util::ExpandINI;
  Dist::Zilla::Util::ExpandINI->filter_file( 'dist.ini.meta' => 'dist.ini' );

  # Hurrah, dist.ini has all the things!

  # Advanced Usage:
  my $filter = Dist::Zilla::Util::ExpandINI->new(
    include_does => [ 'Dist::Zilla::Role::FileGatherer', ],
    exclude_does => [ 'Dist::Zilla::Role::Releaser', ],
  );
  $filter->filter_file( 'dist.ini.meta' => 'dist.ini' );

=head1 DESCRIPTION

This module builds upon the previous work L<< C<:Util::BundleInfo>|Dist::Zilla::Util::BundleInfo >> ( Which can extract
configuration from a bundle in a manner similar to how C<dzil> does it ) and integrates it with some I<very> minimal C<INI>
handling to provide a tool capable of generating bundle-free C<dist.ini> files from bundle-using C<dist.ini> files!

At present its very naïve and only keeps semantic ordering, and I've probably gotten something wrong due to cutting the
complexity of Config::MVP out of the loop.

But at this stage, bundles are the I<only> thing modified in transit.

Every thing else is practically a token-level copy-paste.

=head1 METHODS

=head2 C<filter_file>

                                           #  $source   , $dest
  Dist::Zilla::Util::ExpandINI->filter_file('source.ini','target.ini');

Reads C<$source>, performs expansions, and emits C<$dest>

=head2 C<filter_handle>

  Dist::Zilla::Util::ExpandINI->filter_handle($reader,$writer);

Reads C<$reader>, performs expansions, and emits to C<$writer>

=head2 C<filter_string>

  my $return = Dist::Zilla::Util::ExpandINI->filter_string($source);

Decodes C<$source>, performs expansions, and returns expanded source.

=head1 ATTRIBUTES

=head2 C<include_does>

An C<ArrayRef> of C<Role>s to include in the emitted C<INI> from the source C<INI>.

If this C<ArrayRef> is empty, all C<Plugin>s will be included.

This is the default behavior.

  ->new( include_does => [ 'Dist::Zilla::Role::VersionProvider', ] );

( C<API> Since C<0.002000> )

=head2 C<exclude_does>

An C<ArrayRef> of C<Role>s to I<exclude> from the emitted C<INI>.

If this C<ArrayRef> is empty, I<no> C<Plugin>s will be I<excluded>

This is the default behavior.

  ->new( exclude_does => [ 'Dist::Zilla::Role::Releaser', ] );

( C<API> Since C<0.002000> )

=head2 C<comments>

This attribute controls how comments are handled.

=over 4

=item *

C<all> - All comments are copied ( B<Default> )

=item *

C<authordeps> - Only comments that look like C<Dist::Zilla> C<AuthorDeps> are copied.

=item *

C<none> - No comments are copied.

=back

( C<API> Since C<0.003000> )

=head1 COMMENT PRESERVATION

Comments are ( since C<v0.002000> ) arbitrarily supported in a very basic way.
But the behavior may be surprising.

  [SectionHeader]
  BODY
  [SectionHeader]
  BODY

Is how C<Config::INI> understands its content. So comment parsing is implemented as

  BODY:
    comments: [ "A", "B", "C" ],
    params:   [ "x=y","foo=bar" ]

So:

  [Header]
  ;A
  x = y ; Trailing Note
  ;B
  foo = bar ; Trailing Note

  ;Remark About Header2
  [Header2]

Is re-serialized as:

  [Header]
  ;A
  ;B
  ;Remark About Header2
  x = y
  foo = bar

  [Header2]

This behavior may seem surprising, but its surprising only if you
have assumptions about how C<INI> parsing works.

This also applies and has strange effects with bundles:

  [Header]
  x = y

  ; CommentAboutBundle
  [@Bundle]
  ; More Comments About Bundle

  [Header2]

This expands as:

  [Header]
  ; CommentAboutBundle
  x = y

  [BundleHeader1]
  arg = value

  [BundleHeader2]
  arg = value

  [BundleHeader3]
  ; More Comments About Bundle
  arg = value

  [Header2]

And also note, at this time, only whole-line comments are preserved. Suffix comments are stripped.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
