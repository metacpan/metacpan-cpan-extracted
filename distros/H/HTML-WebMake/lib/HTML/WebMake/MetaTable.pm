#

package HTML::WebMake::MetaTable;

###########################################################################

use Carp;
use strict;

use HTML::WebMake::Main;

use vars	qw{
  	@ISA
	$TARGETS
	$METAS
};

$TARGETS = 1;
$METAS = 2;

###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main) = @_;

  my $self = {
    'main'		=> $main,
  };
  bless ($self, $class);

  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }
sub dbg2 { HTML::WebMake::Main::dbg2 (@_); }

# -------------------------------------------------------------------------

sub set_name_sed_callback {
  my ($self, $sedobj, $sedmethod) = @_;
  $self->{sedobj} = $sedobj;
  $self->{sedmethod} = $sedmethod;
}

# -------------------------------------------------------------------------

sub parse_metatable {
  my ($self, $attrs, $text) = @_;

  my $fmt = $attrs->{format};
  if (!defined $fmt || $fmt eq 'csv') {
    return $self->parse_metatable_csv ($attrs, $text);
  } else {
    return $self->parse_metatable_xml ($attrs, $text);
  }
}

# -------------------------------------------------------------------------

sub parse_metatable_csv {
  my ($self, $attrs, $text) = @_;

  my $delim = $attrs->{delimiter};
  $delim ||= "\t";
  $delim = qr{\Q${delim}\E};

  my @metanames = ();
  my $i;

  foreach my $line (split (/\n/, $text)) {
    my @elems = split (/${delim}/, $line);
    my $contname = shift @elems;
    next unless defined $contname;

    if ($contname eq '.') {
      @metanames = @elems; next;
    }

    $contname = $self->fixname ($contname);

    my $contobj = $self->{main}->{contents}->{$contname};
    if (!defined $contobj) {
      $self->{main}->fail ("<metatable>: cannot find content \${$contname}");
      next;
    }

    if ($#metanames < 0) {
      $self->{main}->fail ("<metatable>: no '.' line in file");
      next;
    }

    for ($i = 0; $i <= $#elems && $i <= $#metanames; $i++) {
      my $metaname = $metanames[$i];
      my $val = $elems[$i];

      $contobj->create_extra_metas_if_needed();
      $contobj->{extra_metas}->{$metaname} = $val;

      dbg2 ("attaching metadata \"$metaname\"=\"$val\" to content \"$contname\"");
    }
  }
}

# -------------------------------------------------------------------------

sub parse_metatable_xml {
  my ($self, $attrs, $text) = @_;

  # trim off text before/after <metaset> chunk
  $text =~ s/^.*?<metaset\b[^>]*?>//gis;
  $text =~ s/<\/\s*metaset\s*>.*$//gis;

  # TODO: once we require an XML parser for XSLT stuff, we should use
  # that here instead of strip_tags.

  my $util = $self->{main}->{util};
  my $src = $attrs->{src}; $src ||= '(.wmk file)';
  $util->set_filename ($src);

  # Right, this is nasty. Perl coredumps here regularly... :( Basically it
  # looks like the nested XML parsing calls tickle a bug in 5.6.0, resulting in
  # a coredump inside malloc() on RedHat 7.1 at least.
  #
  # The workaround that _seems_ to work is to move the parsing of the textblock
  # inside the <target> tags out of that parser loop, by storing them in a hash
  # until the <target> tags are all parsed, then parsing them afterwards.
  # gross and not as efficient, but it works.

  $self->{targetblocks} = { };
  $self->parse_xml_block ($text, $TARGETS);
  # $text = '';

  foreach my $contname (keys %{$self->{targetblocks}}) {
    $contname = $self->fixname ($contname);
    my $contobj = $self->{main}->{contents}->{$contname};
    $text = $self->{targetblocks}->{$contname};
    $self->{tagging_content} = $contobj;
    $self->parse_xml_block ($text, $METAS);
  }

  delete $self->{targetblocks};
  $text = '';
  undef;
}

# -------------------------------------------------------------------------

sub tag_target {
  my ($self, $tag, $attrs, $text) = @_;

  my $contname = $attrs->{'id'};

  my $contobj = $self->{main}->{contents}->{$contname};
  if (!defined $contobj) {
    $self->{main}->fail ("<metatable>: cannot find content \${$contname}");
    return '';
  }

  $self->{targetblocks}->{$contname} = $text;
  '';
}

# -------------------------------------------------------------------------

sub tag_meta {
  my ($self, $tag, $attrs, $text) = @_;
  my $contobj = $self->{tagging_content};
  $contobj->create_extra_metas_if_needed();
  $contobj->{extra_metas}->{$attrs->{'name'}} = $text;
  '';
}

# -------------------------------------------------------------------------

sub parse_xml_block {
  my ($self, $block, $subtags) = @_;
  my $util = $self->{main}->{util};

  $block =~ s/^\s+//gs;
  $block =~ s/^<!--.*?-->//gs;

  if ($subtags eq $TARGETS) {
    $block = $util->strip_tags ($block, "target", $self, \&tag_target, qw(id));
  } elsif ($subtags eq $METAS) {
    $block = $util->strip_tags ($block, "meta", $self, \&tag_meta, qw(name));
  } else {
    die "oops!";
  }

  if ($block =~ /\S/) {
    $block =~ /^(.*?>.{40,40})/s; $block = $1; $block =~ s/\s+/ /gs;
    $self->{main}->fail ("metatable file contains unparseable data at:\n".
              "\t$block ...\"\n");
  }

  1;
}

# -------------------------------------------------------------------------

sub fixname {
  my ($self, $contname) = @_;
  if (defined $self->{sedobj}) {
    $contname = &{$self->{sedmethod}} ($self->{sedobj}, $contname);
  }
  $contname;
}

# -------------------------------------------------------------------------

1;

# METATABLE XML FORMAT
# 
# The idea is to allow tagging of content items with metadata in an XML
# format.
# 
#	 <metaset>
#	  <target id="contentname">
#	    <meta name="title">
#	      This is contentname's title.
#	    </meta>
#	  </target>
#	</metaset>

