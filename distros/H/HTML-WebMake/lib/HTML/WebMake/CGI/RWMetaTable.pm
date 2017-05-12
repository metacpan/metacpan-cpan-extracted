#
# RWMetaTable -- a read-write version of MetaTable.pm for XML metatables.

package HTML::WebMake::CGI::RWMetaTable;

###########################################################################

use Carp;
use strict;
use locale;

use HTML::WebMake::Main;
use HTML::WebMake::Util;

use vars	qw{
  	@ISA $TARGETS $METAS $METATABLEFNAME
};

$TARGETS = 1;
$METAS = 2;
$METATABLEFNAME = "metadata.xml";

###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    'tbl'		=> { }
  };
  bless ($self, $class);

  $self;
}

# -------------------------------------------------------------------------

sub get_metatable_filename {
  my ($self, $filebase) = @_;
  my $metatable = $filebase."/".$METATABLEFNAME;
  return $metatable;
}

sub read_metatable_file {
  my ($self, $filebase) = @_;
  my $metatable = $filebase."/".$METATABLEFNAME;

  if (open (MIN, "<$metatable")) {
    $self->parse_text (join ('', <MIN>));
    close MIN;
  }

  $self->get_parsed_metatable();
}

sub lock_metatable_file {
  my ($self, $filebase) = @_;
  my $metatable = $filebase."/".$METATABLEFNAME;
  my $lock = $metatable.".lock";
  my $failed = 1;

  for my $try (1..10) {
    if (!-f $lock && open (LOCK, ">$lock")) {
      $failed = 0; last;
    }
    warn ("cannot lock {WMROOT}/$METATABLEFNAME, retrying (try $try)...\n");
    sleep (1);
  }

  if ($failed) { return 0; }

  print LOCK $$;
  close LOCK;
  return 1;
}

sub unlock_metatable_file {
  my ($self, $filebase) = @_;
  my $metatable = $filebase."/".$METATABLEFNAME;
  my $lock = $metatable.".lock";

  unlink $lock;
}

sub rewrite_metatable_file {
  my ($self, $filebase) = @_;
  my $metatable = $filebase."/".$METATABLEFNAME;

  if (!open (META, ">$metatable.new")) {
    warn ("cannot write to {WMROOT}/$METATABLEFNAME.new!");
    return 0;
  }
  print META $self->get_text ();
  if (!close META) {
    return 0;
  }

  if ((-f $metatable && !unlink ($metatable))
      || !rename ("$metatable.new", $metatable))
  {
    return 0;
  }

  return 1;
}

# -------------------------------------------------------------------------

sub parse_text {
  my ($self, $text) = @_;

  my $attrs = $self->{attrs};

  # trim off text before/after <metaset> chunk
  $text =~ s/^.*?<metaset\b[^>]*?>//gis;
  $text =~ s/<\/\s*metaset\s*>.*$//gis;

  # TODO: once we require an XML parser for XSLT stuff, we should use
  # that here instead of strip_tags.

  $self->{util} = new HTML::WebMake::Util();
  my $src = $attrs->{src}; $src ||= '(metatable)';
  $self->{util}->set_filename ($src);

  $self->{tbl} = { };

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
    $self->{tbl}->{$contname} = { };
    $self->{tagging_content} = $contname;
    $self->parse_xml_block ($self->{targetblocks}->{$contname}, $METAS);
  }

  delete $self->{targetblocks};
  $text = '';
  undef;
}

# -------------------------------------------------------------------------

sub get_parsed_metatable {
  my ($self) = @_;
  $self->{tbl};
}

# -------------------------------------------------------------------------

sub get_text {
  my ($self) = @_;
  local ($_);

  $_ = "<metaset>\n";
  foreach my $contname (sort keys %{$self->{tbl}}) {
    $_ .= "  <target id=\"".$contname."\">\n";

    foreach my $metaname (sort keys %{$self->{tbl}->{$contname}}) {
      $_ .= "    <meta name=\"".$metaname."\">".
      		$self->{tbl}->{$contname}->{$metaname}."</meta>\n";
    }

    $_ .= "  </target>\n";
  }
  $_ .= "</metaset>\n";
  $_;
}

# -------------------------------------------------------------------------

sub tag_target {
  my ($self, $tag, $attrs, $text) = @_;

  $self->{targetblocks}->{$attrs->{'id'}} = $text;
  '';
}

# -------------------------------------------------------------------------

sub tag_meta {
  my ($self, $tag, $attrs, $text) = @_;

  my $contname = $self->{tagging_content};
  my $name = lc $attrs->{'name'};
  $self->{tbl}->{$contname}->{$name} = $text;
  '';
}

# -------------------------------------------------------------------------

sub parse_xml_block {
  my ($self, $block, $subtags) = @_;
  my $util = $self->{util};

  $block =~ s/^\s+//gs;

  1 while $block =~ s/<\{!--.*?--\}>//gs;       # WebMake comments.
  1 while $block =~ s/^<!--.*?-->//gs;          # XML-style comments.

  while ($block =~ /\S/) {
    my $lastblock = $block;

    if ($subtags eq $TARGETS) {
      $block = $util->strip_tags ($block, "target", $self, \&tag_target, qw(id));
    } elsif ($subtags eq $METAS) {
      $block = $util->strip_tags ($block, "meta", $self, \&tag_meta, qw(name));
    } else {
      die "oops!";
    }

    if ($block eq $lastblock && $block =~ /\S/) {
      $block =~ /^(.*?>.{40,40})/s; $block = $1; $block =~ s/\s+/ /gs;
      warn ("metatable file contains unparseable data at:\n".
		"\t$block ...\"\n");
    }
  }

  1;
}

# -------------------------------------------------------------------------

sub dbg { HTML::WebMake::Main::dbg (@_); }

1;
