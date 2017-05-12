use 5.006;    # our
use strict;
use warnings;

package MetaPOD::Extractor;

our $VERSION = 'v0.4.0';

# ABSTRACT: Extract MetaPOD declarations from a file.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( extends has );
extends 'Pod::Eventual';













## no critic (Bangs::ProhibitDebuggingModule)
use Data::Dump qw(pp);
use Carp qw(croak);

has formatter_regexp => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {

    # _Pulp__5010_qr_m_propagate_properly
    ## no critic (Compatibility::PerlMinimumVersionAndWhy)
    return qr/MetaPOD::([^[:space:]]+)/sxm;
  },
);

has version_regexp => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {

    # _Pulp__5010_qr_m_propagate_properly
    ## no critic (Compatibility::PerlMinimumVersionAndWhy)
    return qr/(v[[:digit:].]+)/sxm;
  },
);

has regexp_begin_with_version => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my $formatter_regexp = $_[0]->formatter_regexp;
    my $version_regexp   = $_[0]->version_regexp;

    # _Pulp__5010_qr_m_propagate_properly
    ## no critic (Compatibility::PerlMinimumVersionAndWhy)
    return qr{ ^ ${formatter_regexp} \s+ ${version_regexp} \s* $ }smx;
  },
);

has regexp_begin => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my $formatter_regexp = $_[0]->formatter_regexp;

    # _Pulp__5010_qr_m_propagate_properly
    ## no critic (Compatibility::PerlMinimumVersionAndWhy)
    return qr{ ^ ${formatter_regexp} \s* $ }smx;
  },
);

has regexp_for_with_version => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my $formatter_regexp = $_[0]->formatter_regexp;
    my $version_regexp   = $_[0]->version_regexp;

    # _Pulp__5010_qr_m_propagate_properly
    ## no critic (Compatibility::PerlMinimumVersionAndWhy)
    return qr{ ^ ${formatter_regexp} \s+ ${version_regexp} \s+ ( .*$ ) }smx;
  },
);

has regexp_for => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my $formatter_regexp = $_[0]->formatter_regexp;

    # _Pulp__5010_qr_m_propagate_properly
    ## no critic (Compatibility::PerlMinimumVersionAndWhy)
    return qr{ ^ ${formatter_regexp} \s+ ( .* $ ) $ }smx;
  },
);

has end_segment_callback => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    return sub { };
  },
);







has segment_cache => (
  is      => ro  =>,
  lazy    => 1,
  writer  => 'set_segment_cache',
  builder => sub { {} },
);







has segments => (
  is      => ro  =>,
  lazy    => 1,
  writer  => 'set_segments',
  builder => sub { [] },
);













has in_segment => (
  is      => ro  =>,
  lazy    => 1,
  writer  => 'set_in_segment',
  clearer => 'unset_in_segment',
  builder => sub { undef },
);







sub begin_segment {
  my ( $self, $format, $version, $start_line ) = @_;
  $self->set_segment_cache(
    {
      format     => $format,
      start_line => $start_line,
      ( defined $version ? ( version => $version ) : () ),
    },
  );
  $self->set_in_segment(1);
  return $self;
}







sub end_segment {
  my ($self) = @_;
  my $segment = $self->segment_cache;
  push @{ $self->segments }, $segment;
  $self->set_segment_cache( {} );
  $self->unset_in_segment();
  my $cb = $self->end_segment_callback;
  $cb->($segment);
  return $self;
}







sub append_segment_data {
  my ( $self, $segment_data ) = @_;
  $self->segment_cache->{data} ||= q{};
  $self->segment_cache->{data} .= $segment_data;
  return $self;
}







sub add_segment {
  my ( $self, $format, $version, $section_data, $start_line ) = @_;
  my $segment = {};
  $segment->{format}     = $format;
  $segment->{version}    = $version if defined $version;
  $segment->{data}       = $section_data;
  $segment->{start_line} = $start_line if defined $start_line;

  push @{ $self->segments }, $segment;
  my $cb = $self->end_segment_callback;
  $cb->($segment);

  return $self;
}







sub handle_begin {
  my ( $self, $event ) = @_;
  if ( $self->in_segment ) {
    croak '=begin MetaPOD:: cannot occur inside =begin MetaPOD:: at line ' . $event->{start_line};
  }
  if ( $event->{content} =~ $self->regexp_begin_with_version ) {
    return $self->begin_segment( $1, $2, $event->{start_line} );
  }
  if ( $event->{content} =~ $self->regexp_begin ) {
    return $self->begin_segment( $1, undef, $event->{start_line} );
  }
  return $self->handle_ignored($event);
}







sub handle_end {
  my ( $self, $event ) = @_;
  chomp $event->{content};
  my $statement = q{=} . $event->{command} . q{ } . $event->{content};

  if ( not $self->in_segment and not $event->{content} =~ $self->regexp_begin ) {
    return $self->handle_ignored($event);
  }

  if ( $self->in_segment ) {
    my $expected_end = '=end MetaPOD::' . $self->segment_cache->{format};
    if ( $statement ne $expected_end ) {
      croak "$statement seen but expected $expected_end at line " . $event->{start_line};
    }
    return $self->end_segment();
  }
  if ( $event->{content} =~ $self->regexp_begin ) {
    croak "unexpected $statement without =begin MetaPOD::$1 at line" . $event->{start_line};
  }
  return $self->handle_ignored($event);
}







sub handle_for {
  my ( $self, $event ) = @_;
  if ( $event->{content} =~ $self->regexp_for_with_version ) {
    return $self->add_segment( $1, $2, $3, $event->{start_line} );
  }
  if ( $event->{content} =~ $self->regexp_for ) {
    return $self->add_segment( $1, undef, $2, $event->{start_line} );
  }
  return $self->handle_ignored($event);
}







sub handle_cut {
  my ( $self, $element ) = @_;
  return $self->handle_ignored($element);
}







sub handle_text {
  my ( $self, $element ) = @_;
  return $self->handle_ignored($element) unless $self->in_segment;
  return $self->append_segment_data( $element->{content} );
}







sub handle_ignored {
  my ( $self, $element ) = @_;
  if ( $self->in_segment ) {
    croak 'Unexpected type ' . $element->{type} . ' inside segment ' . pp($element) . ' at line' . $element->{start_line};
  }
}







sub handle_event {
  my ( $self, $event ) = @_;
  for my $command (qw( begin end for cut )) {
    last unless 'command' eq $event->{type};
    next unless $event->{command} eq $command;
    my $method = $self->can( 'handle_' . $command );
    return $self->$method($event);
  }
  if ( 'text' eq $event->{type} ) {
    return $self->handle_text($event);
  }
  return $self->handle_ignored($event);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Extractor - Extract MetaPOD declarations from a file.

=head1 VERSION

version v0.4.0

=head1 METHODS

=head2 set_segment_cache

    $extactor->set_segment_cache({})

=head2 set_segments

    $extractor->set_segments([])

=head2 set_in_segment

    $extractor->set_in_segment(1)

=head2 unset_in_segment

    $extractor->unset_in_segment()

=head2 begin_segment

    $extractor->begin_segment( $format, $version, $start_line );

=head2 end_segment

    $extractor->end_segment();

=head2 append_segment_data

    $extractor->append_segment_data( $string_data )

=head2 add_segment

    $extractor->add_segment( $format, $version, $data, $start_line );

=head2 handle_begin

    $extractor->handle_begin( $POD_EVENT );

=head2 handle_end

    $extractor->handle_end( $POD_EVENT );

=head2 handle_for

    $extractor->handle_for( $POD_EVENT );

=head2 handle_cut

    $extractor->handle_cut( $POD_EVENT );

=head2 handle_text

    $extractor->handle_text( $POD_EVENT );

=head2 handle_ignored

    $extractor->handle_ignored( $POD_EVENT );

=head2 handle_event

    $extractor->handle_event( $POD_EVENT );

=begin MetaPOD::JSON v1.1.0

{
    "namespace": "MetaPOD::Extractor",
    "inherits" : "Pod::Eventual",
    "interface": "class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
