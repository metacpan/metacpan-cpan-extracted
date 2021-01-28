package Pod::Weaver::Section::Version;
# ABSTRACT: add a VERSION pod section
$Pod::Weaver::Section::Version::VERSION = '4.015';
use Moose;
with 'Pod::Weaver::Role::Section';
with 'Pod::Weaver::Role::StringFromComment';

use Module::Runtime qw(use_module);
use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod This section plugin will produce a hunk of Pod meant to indicate the version of
#pod the document being viewed, like this:
#pod
#pod   =head1 VERSION
#pod
#pod   version 1.234
#pod
#pod It will do nothing if there is no C<version> entry in the input.
#pod
#pod =attr header
#pod
#pod The title of the header to be added.
#pod (default: "VERSION")
#pod
#pod =cut

has header => (
  is      => 'ro',
  isa     => 'Str',
  default => 'VERSION',
);

use DateTime;
use Moose::Util::TypeConstraints;

my $MARKER;
BEGIN { $MARKER = "\x{2316}" }

use String::Formatter 0.100680 stringf => {
  -as => '_format_version',

  input_processor => 'require_single_input',
  string_replacer => 'method_replace',
  codes => {
    v => sub { $_[0]->{version} },
    V => sub { $_[0]->{version}
                . ($_[0]->{is_trial}
                   ? (defined $_[1] ? $_[1] : '-TRIAL') : '') },

    d => sub {
      use_module( 'DateTime', '0.44' ); # CLDR fixes
      DateTime->from_epoch(epoch => $^T, time_zone => $_[0]->{self}->time_zone)
              ->format_cldr($_[1]),
    },
    r => sub { $_[0]->{zilla}->name },
    m => sub {
      return $_[0]->{module} if defined $_[0]->{module};
      $_[0]->{self}->log_fatal([
        "%%m format used for Version section, but no package declaration found in %s",
        $_[0]->{filename},
      ]);
    },

    T => sub { $MARKER },
    n => sub { "\n" },
    s => sub { q{ } },
    t => sub { "\t" },
  },
};

# Needed by Config::MVP.
sub mvp_multivalue_args { 'format' }

#pod =attr format
#pod
#pod The string to use when generating the version string.
#pod
#pod Default: version %v
#pod
#pod The following variables are available:
#pod
#pod =begin :list
#pod
#pod * v - the version
#pod
#pod * V - the version, suffixed by "-TRIAL" if a trial release
#pod
#pod * d - the CLDR format for L<DateTime>
#pod
#pod * n - a newline
#pod
#pod * t - a tab
#pod
#pod * s - a space
#pod
#pod * r - the name of the dist, present only if you use L<Dist::Zilla> to generate
#pod       the POD!
#pod
#pod * m - the name of the module, present only if L<PPI> parsed the document and it
#pod       contained a package declaration!
#pod
#pod * T - special: at the beginning of the line, followed by any amount of
#pod       whitespace, indicates that the line should only be included in trial
#pod       releases; otherwise, results in a fatal error
#pod
#pod =end :list
#pod
#pod If multiple strings are supplied as an array ref, a line of POD is
#pod produced for each string.  Each line will be separated by a newline.
#pod This is useful for splitting longer text across multiple lines in a
#pod C<weaver.ini> file, for example:
#pod
#pod   ; weaver.ini
#pod   [Version]
#pod   format = version %v
#pod   format =
#pod   format = This module's version numbers follow the conventions described at
#pod   format = L<semver.org|http://semver.org/>.
#pod   format = %T
#pod   format = %T This is a trial release!
#pod
#pod =cut

subtype 'Pod::Weaver::Section::Version::_Format',
  as 'ArrayRef[Str]';

coerce 'Pod::Weaver::Section::Version::_Format',
  from 'Str',
  via { [ $_ ] };

has format => (
  is  => 'ro',
  isa => 'Pod::Weaver::Section::Version::_Format',
  coerce => 1,
  default => 'version %v',
);

#pod =attr is_verbatim
#pod
#pod A boolean value specifying whether the version paragraph should be verbatim or not.
#pod
#pod Default: false
#pod
#pod =cut

has is_verbatim => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

#pod =attr time_zone
#pod
#pod The timezone to use when using L<DateTime> for the format.
#pod
#pod Default: local
#pod
#pod =cut

has time_zone => (
  is  => 'ro',
  isa => 'Str', # should be more validated later -- apocal
  default => 'local',
);

#pod =method build_content
#pod
#pod   my @pod_elements = $section->build_content(\%input);
#pod
#pod This method is passed the same C<\%input> that goes to the C<weave_section>
#pod method, and should return a list of pod elements to insert.
#pod
#pod In almost all cases, this method is used internally, but could be usefully
#pod overridden in a subclass.
#pod
#pod =cut

sub build_content {
  my ($self, $input) = @_;
  return unless $input->{version};

  my %args = (
    self     => $self,
    version  => $input->{version},
    filename => $input->{filename},
  );
  $args{zilla} = $input->{zilla} if exists $input->{zilla};

  $args{is_trial} = exists $input->{is_trial} ? $input->{is_trial}
                  : $args{zilla}              ? $args{zilla}->is_trial
                  :                             undef;

  if ( exists $input->{ppi_document} ) {
    my $pkg_node = $input->{ppi_document}->find_first('PPI::Statement::Package');
    $args{module}
        = $pkg_node
        ? $pkg_node->namespace
        : $self->_extract_comment_content($input->{ppi_document}, 'PODNAME')
        ;
  }

  my $content = q{};
  LINE: for my $format (@{ $self->format }) {
    my $line = _format_version($format, \%args);
    next if $line =~ s/^$MARKER\s*// and ! $args{is_trial};

    Carp::croak("%T format used inside line") if $line =~ /$MARKER/;

    $content .= "$line\n";
  }

  if ( $self->is_verbatim ) {
    $content = Pod::Elemental::Element::Pod5::Verbatim->new({
      content => "  $content",
    });
  } else {
    $content = Pod::Elemental::Element::Pod5::Ordinary->new({
      content => $content,
    });
  }

  return ($content);
}

sub weave_section {
  my ($self, $document, $input) = @_;
  return unless $input->{version};

  my @content = $self->build_content($input);

  $self->log_debug('adding ' . $self->header . ' section to pod');

  push @{ $document->children },
    Pod::Elemental::Element::Nested->new({
      command  => 'head1',
      content  => $self->header,
      children => \@content,
    });
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Version - add a VERSION pod section

=head1 VERSION

version 4.015

=head1 OVERVIEW

This section plugin will produce a hunk of Pod meant to indicate the version of
the document being viewed, like this:

  =head1 VERSION

  version 1.234

It will do nothing if there is no C<version> entry in the input.

=head1 ATTRIBUTES

=head2 header

The title of the header to be added.
(default: "VERSION")

=head2 format

The string to use when generating the version string.

Default: version %v

The following variables are available:

=over 4

=item *

v - the version

=item *

V - the version, suffixed by "-TRIAL" if a trial release

=item *

d - the CLDR format for L<DateTime>

=item *

n - a newline

=item *

t - a tab

=item *

s - a space

=item *

r - the name of the dist, present only if you use L<Dist::Zilla> to generate the POD!

=item *

m - the name of the module, present only if L<PPI> parsed the document and it contained a package declaration!

=item *

T - special: at the beginning of the line, followed by any amount of whitespace, indicates that the line should only be included in trial releases; otherwise, results in a fatal error

=back

If multiple strings are supplied as an array ref, a line of POD is
produced for each string.  Each line will be separated by a newline.
This is useful for splitting longer text across multiple lines in a
C<weaver.ini> file, for example:

  ; weaver.ini
  [Version]
  format = version %v
  format =
  format = This module's version numbers follow the conventions described at
  format = L<semver.org|http://semver.org/>.
  format = %T
  format = %T This is a trial release!

=head2 is_verbatim

A boolean value specifying whether the version paragraph should be verbatim or not.

Default: false

=head2 time_zone

The timezone to use when using L<DateTime> for the format.

Default: local

=head1 METHODS

=head2 build_content

  my @pod_elements = $section->build_content(\%input);

This method is passed the same C<\%input> that goes to the C<weave_section>
method, and should return a list of pod elements to insert.

In almost all cases, this method is used internally, but could be usefully
overridden in a subclass.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
