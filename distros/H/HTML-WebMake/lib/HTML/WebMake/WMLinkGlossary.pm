#

package HTML::WebMake::WMLinkGlossary;

###########################################################################


use Carp;

use strict;

use HTML::WebMake::Main;
use HTML::WebMake::SiteCache;
use Text::EtText::LinkGlossary;

use vars	qw{
  	@ISA
};

@ISA = qw(Exporter Text::EtText::LinkGlossary);


###########################################################################

sub new ($$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main, $cache) = @_;

  my $self = {
    'main'		=> $main,
    'cache'		=> $cache,
  };
  bless ($self, $class);

  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }

# -------------------------------------------------------------------------

sub open {
  my ($self) = @_;
  # already open, ignored
} 

sub close {
  my ($self) = @_;
  # ignored for this implementation
}

# -------------------------------------------------------------------------

sub get_link {
  my ($self, $name) = @_;

  # is it a $(url_ref)?
  if ($name =~ /^\$\(.*\)$/) { return $name; }

  $self->{db}{'L#'.$name};
}

sub put_link {
  my ($self, $name, $url) = @_;
  $self->{db}{'L#'.$name} = $url;
}

# -------------------------------------------------------------------------

sub get_auto_link {
  my ($self, $name) = @_;
  $self->{db}{'A#'.$name};
}

sub put_auto_link {
  my ($self, $name, $url) = @_;
  $self->{db}{'A#'.$name} = $url;
}

# -------------------------------------------------------------------------

sub get_auto_link_keys {
  my ($self) = @_;
  local ($_);

  $_ = $self->{db}{'LinkKeys'};
  if (defined $_) { return split (/#/); }

  # no keys entry there -- better create one.
  # This is a migration process, so should only happen once per
  # cache file.
  my @keys = ();
  foreach (keys %{$self->{db}}) {
    next unless (/^A\#(.+)$/);
    push (@keys, $1);
  }

  @keys;
}

# -------------------------------------------------------------------------

sub add_auto_link_keys {
  my ($self, @newkeys) = @_;
  my @keys = $self->get_auto_link_keys();

  my %key_uniq = ();
  foreach my $key (@keys, @newkeys) { $key_uniq{$key} = 1; }

  $self->{db}{'LinkKeys'} = join ('#', keys %key_uniq);
}

# -------------------------------------------------------------------------

1;
