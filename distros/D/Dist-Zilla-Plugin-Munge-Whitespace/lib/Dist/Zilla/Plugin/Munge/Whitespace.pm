use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Munge::Whitespace;

our $VERSION = '0.001001';

# ABSTRACT: Strip superfluous spaces from pesky files.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has with around );
use Dist::Zilla::Role::FileMunger 1.000;    # munge_file

with 'Dist::Zilla::Role::FileMunger';

has 'preserve_trailing' => ( is => 'ro', isa => 'Bool',     lazy => 1, default => sub { undef } );
has 'preserve_cr'       => ( is => 'ro', isa => 'Bool',     lazy => 1, default => sub { undef } );
has 'filename'          => ( is => 'ro', isa => 'ArrayRef', lazy => 1, default => sub { [] } );
has 'match'             => ( is => 'ro', isa => 'ArrayRef', lazy => 1, default => sub { [] } );

has '_match_expr'    => ( is => 'ro', isa => 'RegexpRef', lazy_build => 1 );
has '_eol_kill_expr' => ( is => 'ro', isa => 'RegexpRef', lazy_build => 1 );

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  for my $attr (qw( preserve_trailing preserve_cr filename match )) {
    next unless $self->meta->find_attribute_by_name($attr)->has_value($self);
    $localconf->{$attr} = $self->can($attr)->($self);
  }

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;







sub mvp_multivalue_args { return qw{ filename match } }

sub munge_file {
  my ( $self, $file ) = @_;
  return unless $file->name =~ $self->_match_expr;
  if ( $file->isa('Dist::Zilla::File::FromCode') ) {
    return $self->_munge_from_code($file);
  }
  return $self->_munge_static($file);
}

sub _build__match_expr {
  my ($self)    = @_;
  my (@matches) = @{ $self->match };
  if ( scalar @{ $self->filename } ) {
    unshift @matches, sprintf q[\A(?:%s)\z], join q[|], map { quotemeta } @{ $self->filename };
  }
  my $combined = join q[|], @matches;

  ## no critic (RegularExpressions::RequireDotMatchAnything)
  ## no critic (RegularExpressions::RequireLineBoundaryMatching)
  ## no critic (RegularExpressions::RequireExtendedFormatting)

  return qr/$combined/;
}

sub _build__eol_kill_expr {
  my ($self) = @_;

  ## no critic (RegularExpressions::RequireDotMatchAnything)
  ## no critic (RegularExpressions::RequireLineBoundaryMatching)
  ## no critic (RegularExpressions::RequireExtendedFormatting)

  my $bad_bits = qr//;
  my $end_line;
  if ( not $self->preserve_trailing ) {

    # Add horrible spaces to end
    $bad_bits = qr/[\x{20}\x{09}]+/;
  }
  if ( $self->preserve_cr ) {

    # preserve CR keeps the CR optional as part of the EOL lookahead.
    $end_line = qr/(?=\x{0D}?\x{0A}|\z)/;
  }
  else {
    # No-preserve CR swallows any CRs directly before the EOL lookahead.
    $end_line = qr/\x{0D}?(?=\x{0A}|\z)/;
  }

  return qr/${bad_bits}${end_line}/;
}

sub _munge_string {
  my ( $self, $name, $string ) = @_;
  $self->log_debug( [ 'Stripping trailing whitespace from %s', $name ] );

  if ( $self->preserve_cr and $self->preserve_trailing ) {

    # Noop, both EOL transformations
  }
  else {
    ## no critic (RegularExpressions::RequireDotMatchAnything)
    ## no critic (RegularExpressions::RequireLineBoundaryMatching)
    ## no critic (RegularExpressions::RequireExtendedFormatting)

    my $expr = $self->_eol_kill_expr;
    $string =~ s/$expr//g;
  }
  return $string;
}

sub _munge_from_code {
  my ( $self, $file ) = @_;
  if ( $file->can('code_return_type') and 'text' ne $file->code_return_type ) {
    $self->log_debug( [ 'Skipping %s: does not return text', $file->name ] );
    return;
  }
  $self->log_debug( [ 'Munging FromCode (prep): %s', $file->name ] );
  my $orig_coderef = $file->code();
  $file->code(
    sub {
      $self->log_debug( [ 'Munging FromCode (write): %s', $file->name ] );
      my $content = $file->$orig_coderef();
      return $self->_munge_string( $file->name, $content );
    },
  );
  return;
}

sub _munge_static {
  my ( $self, $file ) = @_;
  $self->log_debug( [ 'Munging Static file: %s', $file->name ] );
  my $content = $file->content;
  $file->content( $self->_munge_string( $file->name, $content ) );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Munge::Whitespace - Strip superfluous spaces from pesky files.

=head1 VERSION

version 0.001001

=head1 DESCRIPTION

This plugin can be used with Dist::Zilla to remove remove white-space from selected files.

In its default mode of operation, it will strip trailing white-space from the selected files in the following forms:

=over 4

=item * C<0x20>: The literal space character

=item * C<0x9>: The literal tab character, otherwise known as C<\t>

=item * C<0xD>: The Carriage Return character, otherwise known as C<\r> ( But only immediately before a \n )

=back

=for comment nobody cares

=for Pod::Coverage mvp_multivalue_args munge_file

=head1 USAGE

  [Munge::Whitespace]
  filename = LICENSE  ; *Cough*: https://github.com/Perl-Toolchain-Gang/Software-License/pull/30
  filename = Changes
  match    = lib/*.pm

  ; Power User Options
  ;          Note: turning both of these options on at present would be idiotic.
  ;          unless you like applying substituion regex to whole files just to duplicate a string
  preserve_trailing = 1 ; Don't nom trailing \s and \t
  preserve_cr       = 1 ; Don't turn \r\n into \n

Note: This is just a standard munger, and will munge any files it gets told to munge.

It will not however write files out anywhere or make your source tree all pretty.

It will however scrub the files you have on their way out to your dist, or on their way out
to any other plugins you might have, like L<< C<CopyFromRelease>|Dist::Zilla::Plugin::CopyFilesFromRelease >>
or L<< C<CopyFromBuild>|Dist::Zilla::Plugin::CopyFilesFromBuild >>, and a smart player can probably combine
parts of this with either of those and have their dist automatically cleaned up for them when they run C<dzil build>.

They might also enjoy the luxurious benefits of having sensitive white-space accidentally sent to a magical wonderland,
which breaks their code, or have a glorious race condition where something important they were working on and hadn't
gotten committed to git yet get eaten due to the file on disk getting updated, and their editor dutifully rejoicing
and prompting to reload their file, which may make them respond to the pavlovian conditioning to click "OK",
followed by much wailing and gnashing of teeth.

Please enjoy our quality product, from the team at FootGuns Inc.

=head1 TODO

=over 4

=item * C<finder> support.

I figured I could, but C<YKW,FI>.

=item * tests

Would be useful. But dogfood for now.

=item * indentation normalization

Sounds like work.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
