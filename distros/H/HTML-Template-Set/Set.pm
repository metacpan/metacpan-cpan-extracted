# HTML::Template::Set
#
# description: Filter/Wrapper for HTML::Template to include TMPL_SET tags
#   that will set params. There is also functionality to associate the
#   environment variables (%ENV) to TMPL_VAR tags prefixed with 'ENV_', I
#   figured adding this here made sense since the module name is ::Set and
#   it is 'setting' the paramaters.
#
# author: David J Radunz <dj@boxen.net>
#
# $Id: Set.pm,v 1.9 2004/05/01 08:26:56 dj Exp $

package HTML::Template::Set;

use strict;
use warnings;

# BEGIN BLOCK {{{
BEGIN {
  ## Modules
  # CPAN
  use HTML::Template;
  use Carp qw(croak confess carp);

  # Base
  use base 'HTML::Template';

  ## Constants
  use constant TRUE  => 1;
  use constant FALSE => 0;

  ## Variables
  use vars(qw($VERSION));

  $VERSION = do { my @r=(q$Revision: 1.9 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
  $HTML::Template::Set::VERSION = $VERSION;
}
# }}}


# Init Functions {{{
sub new {
  my $pkg = shift;

  # check hashworthyness
  if (@_ % 2) {
    croak("HTML::Template::Set->new() called with odd number of option ".
      "parameters - should be of the form option => value");
  }

  # set defaults for our internal options
  my %default_options = (
    set_order_bottom_up      => FALSE,
    associate_env            => FALSE,
    env_names_to_lower_case  => FALSE,
    chomp_after_set          => TRUE
  );

  my %options = _merge_opts(\%default_options, {@_});

  # check for unsupported options file_cache and shared_cache
  if ($options{file_cache} or $options{shared_cache}) {
    croak("HTML::Template::Set->new() : sorry, this module won't work with ".
      "file_cache or shared_cache modes.  This will hopefully be fixed in an ".
      "upcoming version.");
  }

  # push on our filter, one way or another.
  if (exists $options{filter}) {
    # CODE => ARRAY
    $options{filter} = [ { 'sub'    => $options{filter},
                           'format' => 'scalar'         } ]
      if ref($options{filter}) eq 'CODE';

    # HASH => ARRAY
    $options{filter} = [ $options{filter} ]
      if ref($options{filter}) eq 'HASH';

    unless (ref($options{filter}) eq 'ARRAY') {
      # unrecognized
      croak("HTML::Template::Set->new() : bad format for filter argument. ".
        "Please check the HTML::Template docs for the allowed forms.");
    }
  }

  # push onto ARRAY
  my %set_params = ();
  push(@{$options{filter}}, {
    'sub'    => sub { _set_filter(\%set_params, \%options, @_); },
    'format' => 'scalar'
  });

  # default global_vars on
  unless (exists $options{global_vars}) {
    $options{global_vars} = 1;
  }

  # create an HTML::Template object, catch the results to keep error
  # message line-numbers helpful.
  my $self;
  eval {
    $self = $pkg->SUPER::new(%options,
      _set_params => \%set_params
    );
  };
  if ($@) {
    croak("HTML::Template::Set->new() : Error creating HTML::Template object".
      " : ". $@);
  }

  unless (exists $set_params{___loaded_set_params}) {
    # pull set_params out of the parse_stack for cache mode.
    if ($self->{options}->{cache}) {
      my $parse_stack = $self->{parse_stack};
      my $set_params = ${$parse_stack}[-1];

      if (defined $set_params and ref $set_params eq 'HASH') {
        $self->{options}->{_set_params} = $set_params;
        if ($self->{options}->{debug}) {
          print STDERR "### HTML::Template::Set Debug ### loaded set params ".
            "from cache\n";
        }
      }
    }
  }

  # merge the TMPL_SET params as VAR's
  $self->_merge_set_params();

  return $self;
}

sub _merge_opts {
  my ($defaults, $args) = @_;

  return unless ((defined $defaults && ref $defaults eq 'HASH')
    or (defined $args and ref $args eq 'HASH'));

  my %opts = %$defaults;

  foreach my $key (keys %$args) {
    $opts{$key} = $args->{$key};
  }

  return %opts;
}
# }}}


# Set Filter Function {{{
sub _set_filter {
  my ($set_params, $options, $text) = @_;

  # return unless there is some text to parse
  return unless ($$text);

  # the rtext is the text that is returned after sucking out the set tags
  my @rtext = ();

  # the setstack is a temporary stack containing pending sets
  # waiting for a /set.
  my @setstack = ();

  # the setparamstack is a temorary stack containing all sets for this
  # template, it is used later to set the real set_params (depending on the
  # set_order_*)
  my $setparamstack = {};

  # all the tags that need NAMEs:
  my %need_names = map { $_ => 1 }
    qw(TMPL_SET);

  # initilize the lineno counter
  my $lineno = 1;

  # now split up template on '<', leaving them in
  my @chunks = split(m/(?=<)/, $$text);

  # loop through chunks, filling up pstack
  my $last_chunk =  $#chunks;
  for (my $chunk_number = 0;
            $chunk_number <= $last_chunk;
            $chunk_number++) {
    next unless defined $chunks[$chunk_number];
    my $chunk = $chunks[$chunk_number];

    # a general regex to match any and all TMPL_* tags
    if ($chunk =~ /^<
                    (?:!--\s*)?
                    (
                      \/?[Tt][Mm][Pp][Ll]_
                      (?:
                         (?:[Ss][Ee][Tt])
                      )
                    ) # $1 => $which - start of the tag

                    \s*

                    # NAME attribute
                    (?:
                      (?:
                        [Nn][Aa][Mm][Ee]
                        \s*=\s*
                      )?
                      (?:
                        "([^">]*)"  # $2 => double-quoted NAME value "
                        |
                        '([^'>]*)'  # $3 => single-quoted NAME value
                        |
                        ([^\s=>]*)  # $4 => unquoted NAME value
                      )
                    )?

                    \s*

                    (?:--)?>
                    (.*) # $5 => $post - text that comes after the tag
                   $/sx) {

      my $which = uc($1); # which tag is it

      # what name for the tag?  undef for a /tag at most, one of the
      # following three will be defined
      my $name = defined $2 ? $2 : defined $3 ? $3 : defined $4 ? $4 : undef;

      my $post = $5; # what comes after on the line

      # allow mixed case in filenames, otherwise flatten
      $name = lc($name)
        unless (not defined $name or $options->{case_sensitive});

      # croak if we need a name and didn't get one
      if ($need_names{$which} and (not defined $name or not length $name)) {
        croak("HTML::Template::Set->new() : No NAME given to a $which at".
          "line ". $lineno. "\n");
      }

      # parse tags
      if ($which eq 'TMPL_SET') {
        if ($options->{debug}) {
          print STDERR "### HTML::Template::Set Debug ### line $lineno : ".
            "$which start\n";
        }

        if (@setstack > 0) {
          croak("HTML::Template::Set->new() : Sorry, currently nested ".
            "TMPL_SET tags are not permitted: at line ". $lineno);
        }

        if (exists $setparamstack->{$name}) {
          croak("HTML::Template::Set->new() : found duplicate TMPL_SET for ".
            $name. " at line ". $lineno);
        }

        # initilize the paramater
        $setparamstack->{$name} = undef;

        push(@setstack, $name);

        # trim space before the TMPL_SET tag
        if (@rtext > 0) {
          $rtext[-1] =~ s/([^ \t]*)[ \t]*$/$1/;
        }
      } elsif ($which eq '/TMPL_SET') {
        if ($options->{debug}) {
          print STDERR "### HTML::Template::Set Debug ### line $lineno : $which end\n";
        }

        $name = pop(@setstack);

        unless ($name) {
          croak("HTML::Template::Set->new() : found </TMPL_SET> with no ".
            "matching <TMPL_SET> at line ". $lineno);
        }

        if ($post) {
          if ($options->{chomp_after_set}) {
            $post =~ s/^\s*(\n|\r\n)//;
          } else {
            $post =~ s/^[ ]*(\n|\r\n)//;
          }
        }
      }

      # either add post to the setparamstack or the rtext
      if (defined($post)) {
        my ($set_name) = @setstack;
        if ($set_name) {
          $setparamstack->{$set_name} .= $post;
        } else {
          push(@rtext, $post);
        }
      }
    } else { # just your ordinary markup
      # either add the chunk to the setparamstack or the rtext
      # push the rest and get next chunk
      if (defined($chunk)) {
        my ($set_name) = @setstack;
        if ($set_name) {
          $setparamstack->{$set_name} .= $chunk;
        } else {
          push(@rtext, $chunk);
        }
      }
    }

    # count newlines in chunk and advance line count
    $lineno += scalar(@{[$chunk =~ m/(\n)/g]});
  } # next CHUNK

  # Set the text to our parsed text
  $$text = join('', @rtext);

  # merge the setparamstack back to the main set_params
  if (%{$setparamstack}) {
    foreach my $param (keys %{$setparamstack}) {
      if (exists $set_params->{$param}) {
        if ($options->{set_order_bottom_up}) {
          $set_params->{$param} = $setparamstack->{$param};
        }
      } else {
        $set_params->{$param} = $setparamstack->{$param};
      }
    }
  }

  unless (exists $set_params->{___loaded_set_params}) {
    $set_params->{___loaded_set_params} = TRUE;
  }

  return;
}
# }}}


# Merge Functions {{{
sub _merge_set_params {
  my ($self) = @_;
  my $set_params = $self->{options}->{_set_params};
  my $param_map = $self->{param_map};

  return unless (defined $set_params and ref $set_params eq 'HASH'
    and %$set_params);

  foreach my $key (keys %{$set_params}) {
    next if ($key eq '___loaded_set_params');

    my $value = $set_params->{$key};
    my $name = $self->_initilize_set_param($key);

    # Check the TMPL_SET tag for TMPL_VAR's initilizing them and replacing
    # them with a smaller string [#SVAR #].
    $value =~ s/<TMPL_VAR\s*NAME=["']?(.+?)["']?\s*>/$self->_initilize_set_param($1, 1)/ge;

    # Set the VAR (this will not overload any $tmpl->param calls in the
    # script as its run before any of them are made.
    ${$param_map->{$name}} = $value;
  }
}

sub _initilize_set_param {
  my ($self, $param, $tag) = @_;
  my $param_map = $self->{param_map};

  if (exists $param_map->{$param}) {
    my $var = $param_map->{$param};
    unless (ref $var eq 'HTML::Template::VAR') {
      croak("HTML::Template->new() : Already used param name ". $param.
        " as a TMPL_LOOP, found in a TMPL_SET");
    }
  } else {
    # Make a new VAR
    $param_map->{$param} = HTML::Template::VAR->new();
  }

  return ($tag) ?
    '[#SVAR '. $param. '#]' : $param;
}

sub _merge_env_params {
  my ($self) = @_;
  my $param_map = $self->{param_map};

  foreach my $key (keys %ENV) {
    my $name;
    if (exists $self->{options}->{case_sensitive}
      and $self->{options}->{case_sensitive}) {
      $name = (exists $self->{options}->{env_names_to_lower_case}
        and $self->{options}->{env_names_to_lower_case}) ?
          'env_'. lc($key) : 'ENV_'. $key;
    } else {
      $name = 'env_'. lc($key);
    }
    if (exists $param_map->{$name}) {
      my $var = $param_map->{$name};
      if (ref $var eq 'HTML::Template::VAR') {
        ${$param_map->{$name}} = $ENV{$key};
      } else {
        croak("HTML::Template->new() : Already used param name ". $name.
          " as a TMPL_LOOP, while associating ENV");
      }
    }
  }
}
# }}}


# Overloaded Param Function {{{
sub param {
  my ($self, @args) = @_;

  if (@args == 1) {
    return $self->_get_translated_set_tag($args[0]);
  } else {
    return $self->SUPER::param(@args);
  }
}

sub _get_translated_set_tag {
  my ($self, $param) = @_;
  my $options = $self->{options};
  my $set_params = $options->{_set_params};

  unless (exists $options->{case_sensitive} and $options->{case_sensitive}) {
    $param = lc($param);
  }

  my $value = $self->SUPER::param($param);

  # dont bother translating anything but set params
  return $value unless (exists $set_params->{$param});

  # translate the VAR tags in the SET
  if ($value) {
    $value =~
      s/\Q[#SVAR \E(.+?)\Q#]\E/$self->_get_param_in_set($param, $1)/ge;
  }

  return $value;
}

sub _get_param_in_set {
  my ($self, $set_name, $param) = @_;
  my $options = $self->{options};
  my $param_map = $self->{param_map};

  return undef unless ($param);

  if ($set_name eq $param) {
    croak("HTML::Template::Set : Cannot have TMPL_VAR within ".
      "TMPL_SET of the same name: ". $set_name);
  }

  if (exists $param_map->{$param}) {
    return (${$param_map->{$param}}) ? ${$param_map->{$param}} : '';
  } else {
    if ($options->{associate_env} and $param =~ /^env_(.+?)$/i) {
      my $env = $1;
      if ($env) {
        return $ENV{uc($env)};
      }
    }
    croak("HTML::Template::Set : Tried to set non-existent ".
      "TMPL_VAR: ". $param. " in TMPL_SET: ". $set_name.
      " (this should never occur.. hmmm)");
  }
}
# }}}


# Overloaded Output Function {{{
#   for filling in TMPL_VAR's in params (put there via TMPL_SET)
sub output {
  my ($self, @args) = @_;
  my $parse_stack = $self->{parse_stack};
  my $options = $self->{options};
  my $set_params = $options->{_set_params};

  # pull set_params out of the parse_stack for cache mode so HTML::Template
  # doesnt try and process them.
  if ($options->{cache}) {
    pop @$parse_stack;
  }

  # merge the ENV hash params as VAR's
  if (exists $self->{options}->{associate_env} and
    $self->{options}->{associate_env}) {
      $self->_merge_env_params();
  }

  if (ref $set_params eq 'HASH') {
    foreach my $name (keys %{$set_params}) {
      next if ($name eq '___loaded_set_params');

      # looks silly, but sub param is overloaded to translate vars in the
      # set tag :)
      $self->SUPER::param( $name => $self->param($name) );
    }
  }

  my $output = $self->SUPER::output(@args);

  if ($options->{cache}) {
    push @$parse_stack, $set_params;
  }

  return $output;
}


# }}}


# Overloaded Cache Function {{{
sub _commit_to_cache {
  my ($self, @args) = @_;
  my $parse_stack = $self->{parse_stack};
  my $options = $self->{options};

  push @$parse_stack, $options->{_set_params};

  if ($options->{debug}) {
    print STDERR "### HTML::Template::Set Debug ### commited set params to ".
      "cache\n";
  }

  return $self->SUPER::_commit_to_cache(@args);
}
# }}}

1;

__END__

=pod

=head1 NAME

HTML::Template::Set - HTML::Template extension adding set support

=head1 SYNOPSIS

in your HTML:

  <TMPL_SET NAME="handler">apples_to_oranges</TMPL_SET>
  <TMPL_SET NAME="title">Apples Are Green</TMPL_SET>
  <HTML>
    <HEAD>
      <TITLE><TMPL_VAR NAME="title"></TITLE>
    </HEAD>

    <BODY>
      <H1><TMPL_VAR NAME="title"></H1>
      <HR>
      <BR>
      <B>You authenticated as: </B> <TMPL_VAR NAME="ENV_REMOTE_USER"><BR><BR>
      <TMPL_IF NAME="oranges">You prefer oranges</TMPL_IF>
    </BODY>
  </HTML>

in your script:

  use HTML::Template::Set;

  my $tmpl = new HTML::Template::Set(
    filename      => 'foo.tmpl',
    associate_env => 1
  );

  my $handler = $tmpl->param('handler');
  if ($handler and $handler eq 'apples_to_oranges') {
    $tmpl->param('oranges' => 1);
  }

  print $tmpl->output();

=head1 DESCRIPTION

This module provides an extension to HTML::Template that allows params to be
set in the template. This is purely an addition - all the normal
HTML::Template options, syntax and behaviors will still work.
See L<HTML::Template> for details.

The TMPL_SET tags are parsed into params as the HTML::Template object is
constructed, so they will be available in your script right away. You can
have TMPL_VAR tags inside TMPL_SET tags which are translated each time param
is called, and translated upon output.

TMPL_SET tags can span multiple lines, the only caveat being that you cannot
nest a TMPL_SET within a TMPL_SET (and at the moment I can see no reason why
you would want to).

The basic syntax is as follows:

  <TMPL_SET NAME="mouse">Mickey Mouse Inc 2004</TMPL_SET>

You can also have:

  <TMPL_SET NAME="mouse">
    Mickey Mouse Inc 2004
  </TMPL_SET>

The only thing to note about the above example is that all whitespace after
the TMPL_SET tag untill the /TMPL_SET tag is retained. So if you do not wish
to have whitespace in your document please use the former example.

The following is also permissable:

  <TMPL_SET NAME="info">
    Information: <TMPL_VAR NAME="description">
    Server Name: <TMPL_VAR NAME="ENV_SERVER_NAME">
  </TMPL_SET>

In this example the TMPL_VAR tags are parsed and translated when 'param' or
'output' is called. That means in your script you can update the param as many
times as you like and have the TMPL_SET param automatically updated (this can
also be seen as a downside if you wanted a constant TMPL_SET tag, i may add
an option in future to allow for this).

When a TMPL_SET tag is parsed its stripped from the document unlike TMPL_VAR's
and TMPL_IF's that leave whitespace in their place. This was done because in
every case I can think of having alot of TMPL_SET tags will result in a chunk
of whitespace left in the document (which is unsightly).

=head1 MOTIVATION

I had a mod_perl application that worked in an opposite direction, that being
the templates were handled by a 'handler'. So for the 'handler' to know how to
handle the template I needed to set a paramater in the template. The old
templating system I was using supported this, but didnt handle nested if's
very well and I wanted to use HTML::Template. I decided I would write this
module, now I can have <TMPL_SET NAME="handler">index</TMPL_SET> and sub
index will be called to handle my template.


=head1 BASIC SYNTAX

A TMPL_SET tag is essentially the same format as a TMPL_IF tag, however it
cannot be nested and obviously does a very different thing.

  <TMPL_SET NAME="one">1</TMPL_SET>

  <TMPL_VAR NAME="one">

  <TMPL_SET NAME="two">two is not <TMPL_VAR NAME="one"></TMPL_SET>

Environment variables can be used just like any other param, except they are
prefixed by 'ENV_'.

  <TMPL_VAR NAME="ENV_REMOTE_ADDR">

  <TMPL_IF NAME="ENV_HTTPS"> </TMPL_IF>

=head1 OPTIONS

=over 4

=item TMPL_SET Options

=over 4

=item *

set_order_bottom_up - if set to 1 the order the params are set by TMPL_SET
changes so that the last included file's TMPL_SET becomes the param
(usually I prefer the first file to be where I set the param from so I can set
defaults in the included file). Defaults to 0.

=item *

chomp_after_set - if set to 1 all empty lines after a /TMPL_SET tag are
taken out of the final output (I find this useful if I want to put a space
between my TMPL_SET tags and the HTML markup, but dont want that space in
the HTML it spits out). Defaults to 1.

=back

=item ENV Options

=over 4

=item *

associate_env - if set to 1 once 'output' is called the %ENV hash will be
associated with any params that match 'ENV_{ENV KEY}' (i.e. ENV_SERVER_NAME).
Defaults to 0.

=item *

env_names_to_lower_case - if set to 1 all ENV_ params will be in lowercase
(instead of ENV_SERVER_NAME it will be env_server_name). This only applies
when the HTML::Template option case_sensitive is on (as you can specify upper
or lower, or mixed case if its not turned on). Defaults to 0.

=back

=back

=head1 CAVEATS

Currently the module forces the HTML::Template global_vars option to
be set. This is because the TMPL_SET params and the ENV_ params will not
work inside loops otherwise, as they have no scoping at all. If you for some
reason do not want global vars to be turned on you need to manually turn it off
but keep in mind the TMPL_SET params and ENV_ params will not be available in
your loops.

Wrapping a TMPL_SET inside a TMPL_IF will at the moment have no effect, and likewise putting a TMPL_IF, TMPL_LOOP or anything other than a TMPL_VAR inside a TMPL_SET will just spit out the tags as is.

=head1 NOTES

If you are getting an error and cant work out what file its occuring on the
best idea is to turn debug on (see L<HTML::Template> for how to do this).
The reason being, when the TMPL_SET's are parsed the filter has no idea what
file is being processed as its not passed that information, so with debug
turned on you will be able to see what the last INCLUDE loaded was and the
line number in the error message will make more sense.

=head1 BUGS

I am aware of no bugs - if you find one, just drop me an email and i'll
try and nut it out (or email a patch, that would be tops!).

=head1 CREDITS

I would like to thank the author of HTML::Template for writing such a
useful perl module:

   Sam Tregar

=head1 SEE ALSO

L<HTML::Template>

=head1 AUTHOR

David J Radunz <dj@boxen.net>

=head1 LICENSE

HTML::Template::Set : HTML::Template extension adding set support

Copyright (C) 2004 David J Radunz (dj@boxen.net)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

