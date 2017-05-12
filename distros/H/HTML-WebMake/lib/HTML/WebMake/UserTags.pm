# Allow the definition of user tags in WebMake files, like so:
# 
# <{mkthumb name="${from}" delim=","}>...text...</{mkthumb}>
# <{alone name="${from}" }/>

package HTML::WebMake::UserTags;

###########################################################################


use Carp;
use strict;

use HTML::WebMake::Main;

use vars	qw{
  	@ISA
};

# -------------------------------------------------------------------------




###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main) = @_;

  my $self = {
    'main'		=> $main,

    'tags'		=> { },
    'tags_defined'	=> 0,
    'tag_names'		=> [ ],

    'prefmt_tags'	=> { },
    'prefmt_tags_defined' => 0,
    'prefmt_tag_names'	=> [ ],

    'wmk_tags'		=> { },
    'wmk_tags_defined'	=> 0,
    'wmk_tag_names'	=> [ ],
  };

  bless ($self, $class);

  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }

# -------------------------------------------------------------------------

sub def_tag {
  my ($self, $is_empty, $is_wmk, $is_prefmt, $name, $fn, @reqd_attrs) = @_;

  my $tag = { };
  if ($is_empty) {
    $tag->{is_empty} = 1;
    $tag->{pattern} = qr{\<\{?${name}(?:\s([^>]*?)|)\s*\/\}?\>}is;
  } else {
    $tag->{is_empty} = 0;
    $tag->{pattern} =
	qr{\<\{?${name}(?:\s([^>]*?)|)\s*\}?\>(.*?)\<\/\{?${name}\s*\}?\>}is;
  }

  @{$tag->{reqd_attrs}} = @reqd_attrs;
  $tag->{handler_fn} = $fn;

  if ($is_wmk) {
    push (@{$self->{wmk_tag_names}}, $name);
    $self->{wmk_tags_defined}++;
    $self->{wmk_tags}->{$name} = $tag;
    dbg ("Defined new WebMake tag: <$name>");

  } elsif ($is_prefmt) {
    push (@{$self->{prefmt_tag_names}}, $name);
    $self->{prefmt_tags_defined}++;
    $self->{prefmt_tags}->{$name} = $tag;
    dbg ("Defined new preformat content tag: <$name>");

  } else {
    push (@{$self->{tag_names}}, $name);
    $self->{tags_defined}++;
    $self->{tags}->{$name} = $tag;
    dbg ("Defined new content tag: <$name>");
  }

  '';
}

# -------------------------------------------------------------------------

sub subst_tags {
  my ($self, $from, $str) = @_;
  return $self->_subst_tags($from, $str, 0, 0);
}

sub subst_wmk_tags {
  my ($self, $from, $str) = @_;
  return $self->_subst_tags($from, $str, 1, 0);
}

sub subst_preformat_tags {
  my ($self, $from, $str) = @_;
  return $self->_subst_tags($from, $str, 0, 1);
}

sub _subst_tags {
  my ($self, $from, $str, $is_wmk, $is_prefmt) = @_;
  my @tags;
  my $tag;

  if ($is_wmk) {
    return unless ($self->{wmk_tags_defined});
    @tags = @{$self->{wmk_tag_names}};

  } elsif ($is_prefmt) {
    return unless ($self->{prefmt_tags_defined});
    @tags = @{$self->{prefmt_tag_names}};

  } else {
    return unless ($self->{tags_defined});
    @tags = @{$self->{tag_names}};
  }

  my $foundatag = 0;
  foreach my $tagname (@tags) {
    next unless (defined $tagname);
    if ($is_wmk) {
      $tag = $self->{wmk_tags}->{$tagname};
    } elsif ($is_prefmt) {
      $tag = $self->{prefmt_tags}->{$tagname};
    } else {
      $tag = $self->{tags}->{$tagname};
    }

    next unless ($$str =~ /\<${tagname}\b/is);

    # been deprecated for a while. take it out
    # next unless ($$str =~ /\<\{?${tagname}[\s>}]/is);
    # if ($$str =~ /\<\{${tagname}/is) {	#}
    # warn "$from: <{${tagname}}> deprecated, use <${tagname}> instead\n";
    # }

    $foundatag = 1;
    my $pat = $tag->{pattern};
    if ($tag->{is_empty}) {
      $$str =~ s/${pat}/ $self->call_tag ($tag, $from, $tagname, $1, ''); /gies;
    } else {
      $$str =~ s/${pat}/ $self->call_tag ($tag, $from, $tagname, $1, $2); /gies;
    }
  }

  return $foundatag;
}

# -------------------------------------------------------------------------

sub call_tag {
  my ($self, $tag, $from, $tagname, $argtext, $text) = @_;
  local ($_) = '';

  my $util = $self->{main}->{util};
  my $attrs = $util->parse_xml_tag_attributes ($tagname,
  	defined ($argtext) ? $argtext : '',
  	$from, @{$tag->{reqd_attrs}});
  if (!defined $attrs) { return ''; }

  if ($self->{main}->{paranoid}) {
    return "\n(Paranoid mode on - perl code evaluation prohibited.)\n";
  }

  my $pl = $self->{main}->getperlinterp();

  $pl->enter_perl_call();
  my $ret = eval {
    package main;
    &{$tag->{handler_fn}} ($tagname, $attrs, $text, $pl);
  };
  $pl->exit_perl_call();

  if (!defined $ret) {
    warn "<$tagname> code failed: $@\n";
    $ret = '';
  }
  $ret;
}

# -------------------------------------------------------------------------

1;
