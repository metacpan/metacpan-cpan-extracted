#
# content items used to store metadata.
# main factor here is that these content items cannot, themselves,
# have metadata attached.

package HTML::WebMake::MetadataContent;

use HTML::WebMake::Content;
use Carp;
use strict;
use locale;

use vars        qw{
        @ISA
};

@ISA = qw(HTML::WebMake::Content);


###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = $class->SUPER::new (@_);
  bless ($self, $class);

  $self->{cannot_have_metadata} = 1;
  $self->{no_map} = 1;
  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }
sub vrb { HTML::WebMake::Main::vrb (@_); }

# -------------------------------------------------------------------------

sub as_string {
  my ($self) = @_;
  "\$\[".$self->{name}."\]";
}

# -------------------------------------------------------------------------

sub is_generated_content {
  my ($self) = @_;
  1;
}

# -------------------------------------------------------------------------

sub expand {
  my ($self) = @_;
  return $self->{main}->curly_subst ($self->{name}, $self->{name});
}

sub expand_no_ref {
  my ($self) = @_;
  return $self->{main}->fileless_subst ($self->{name}, '$['.$self->{name}.']');
}

# -------------------------------------------------------------------------

sub get_metadata {
  my ($self, $key) = @_;
  my $val;

  # kludge: ensure metadata clusters beside its parent datum
  # for (full) sitemaps.
  if ($key eq 'score') { $val = '0'; }
  if ($key eq 'declared') { $val = $self->get_declared(); }

  if (!defined $val || $val eq '') {
    $val = $self->{main}->{metadata}->get_default_value ($key);
  }

  $self->{main}->{metadata}->convert_to_type ($key, $val);
}

# -------------------------------------------------------------------------

sub create_extra_metas_if_needed { }
sub load_metadata { }

# -------------------------------------------------------------------------

sub get_score {
  my ($self) = @_;
  return $self->get_metadata ("score");
}

sub get_title {
  my ($self) = @_;
  return $self->get_metadata ("title");
}

# -------------------------------------------------------------------------

=item $modtime = $cont->get_modtime();

Return a content item's modification date, in UNIX time_t format,
ie. seconds since Jan 1 1970.

=cut

sub get_modtime {
  my ($self) = @_;
  return $self->{main}->cached_get_modtime ($self->get_filename());
}

# -------------------------------------------------------------------------

sub get_text_as {
  my ($self, $format) = @_;

  if (!defined $format) {
    carp ($self->as_string().": get_text_as with undef arg");
    return "";
  }

  my $fmt = $self->get_format();
  if (!defined $fmt) {
    carp ($self->as_string().": no format defined");
    return "";
  }

  my $txt = $self->{text};
  if (!defined $txt) { die "undefined text for $self->{name}"; }

  if ($fmt ne $format) {
    $txt = $self->{main}->{format_conv}->convert
	  ($self, $fmt, $format, $txt, 1);
  }

  $self->{main}->subst ($self->{name}, \$txt);

  # always remove leading & trailing whitespace from HTML content.
  if ($format eq 'text/html') {
    $txt =~ s/^\s+//s;$txt =~ s/\s+$//s;
  }

  $txt;
}

# -------------------------------------------------------------------------

sub add_ref_from_url {
}

sub get_url {
  # metadata doesn't have URLs, the content items do
  "";
}

# -------------------------------------------------------------------------

sub is_only_usable_from_deferred_refs {
  my ($self) = @_;
  1;
}

# -------------------------------------------------------------------------

1;
