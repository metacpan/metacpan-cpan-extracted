use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Author::KENTNL::MinimumPerl;

# ABSTRACT: The MinimumPerl Plugin with a few hacks

our $VERSION = '2.025021';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moose qw( has extends override around );
use Dist::Zilla::Plugin::MinimumPerl 1.004;
extends 'Dist::Zilla::Plugin::MinimumPerl';
use namespace::autoclean;

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  if ( $self->meta->find_attribute_by_name('detected_perl')->has_value($self) ) {
    $localconf->{detected_perl} = $self->detected_perl;
  }
  if ( $self->meta->find_attribute_by_name('fiveten')->has_value($self) ) {
    $localconf->{fiveten} = $self->fiveten;
  }

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

has 'detected_perl' => (
  is         => 'rw',
  isa        => 'Object',
  lazy_build => 1,
);

has 'fiveten' => (
  isa     => 'Bool',
  is      => 'rw',
  default => sub { undef },
);

override register_prereqs => sub {
  my ($self) = @_;

  my $minperl = $self->minperl;

  $self->log_debug( [ 'Minimum Perl is v%s', $minperl ] );
  $self->zilla->register_prereqs( { phase => 'runtime' }, perl => $minperl->stringify, );
};

no Moose;
__PACKAGE__->meta->make_immutable;

sub _3part_check {
  my ( $self, $file, $pmv, $minver ) = @_;
  my $perl_required = version->parse('5.10.0');
  return $minver if $minver >= $perl_required;
  my $document            = $pmv->Document;
  my $version_declaration = sub {
    $_[1]->isa('PPI::Token::Symbol') and $_[1]->content =~ /::VERSION\z/msx;
  };
  my $version_match = sub {
    'PPI::Token::Quote::Single' eq $_[1]->class and $_[1]->parent->find_any($version_declaration);
  };
  my (@versions) = @{ $document->find($version_match) || [] };
  for my $versiondecl (@versions) {
    next
      if $minver >= $perl_required;
    ## no critic (ProhibitStringyEval)
    my $v = eval $versiondecl;
    if ( $v =~ /\A\d+[.]\d+[.]/msx ) {
      $minver = $perl_required;
      $self->log_debug( [ 'Upgraded to %s due to %s having x.y.z', $minver, $file->name ] );
    }
  }
  return $minver;
}

sub _build_detected_perl {
  my ($self) = @_;
  my $minver;

  foreach my $file ( @{ $self->found_files } ) {

    # TODO should we scan the content for the perl shebang?
    # Only check .t and .pm/pl files, thanks RT#67355 and DOHERTY
    next unless $file->name =~ /[.](?:t|p[ml])\z/imsx;

    # TODO skip "bad" files and not die, just warn?
    my $pmv = Perl::MinimumVersion->new( \$file->content );
    if ( not defined $pmv ) {
      $self->log_fatal( [ 'Unable to parse \'%s\'', $file->name ] );
    }
    my $ver = $pmv->minimum_version;
    if ( not defined $ver ) {
      $self->log_fatal( [ 'Unable to extract MinimumPerl from \'%s\'', $file->name ] );
    }
    if ( ( not defined $minver ) or $ver > $minver ) {
      $self->log_debug( [ 'Increasing perl dep to %s due to %s', $ver, $file->name ] );
      $minver = $ver;
    }
    if ( $self->fiveten ) {
      $ver = $self->_3part_check( $file, $pmv, $minver );
      if ( "$ver" ne "$minver" ) {
        $self->log_debug( [ 'Increasing perl dep to %s due to 3-part in %s', $ver, $file->name ] );
        $minver = $ver;
      }
    }
  }

  # Write out the minimum perl found
  if ( defined $minver ) {
    return $minver;
  }
  return $self->log_fatal('Found no perl files, check your dist?');
}







sub minperl {
  require version;
  my $self = shift;
  if ( not $self->_has_perl ) {
    return $self->detected_perl;
  }
  my ($x) = version->parse( $self->perl );
  my ($y) = $self->detected_perl;
  if ( $x > $y ) {
    return $x;
  }
  return $y;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::KENTNL::MinimumPerl - The MinimumPerl Plugin with a few hacks

=head1 VERSION

version 2.025021

=head1 METHODS

=head2 C<minperl>

Returns the maximum of either the version requested for Perl, or the version detected for Perl.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Author::KENTNL::MinimumPerl",
    "interface":"class",
    "inherits":"Dist::Zilla::Plugin::MinimumPerl"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
