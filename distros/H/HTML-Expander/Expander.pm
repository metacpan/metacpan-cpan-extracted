#########################################################################
#
# HTML::Expander
# Vladi Belperchinov-Shabanski "Cade"
# <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>
# http://cade.datamax.bg
#
#########################################################################
package HTML::Expander;
use Exporter;
@ISA     = qw( Exporter );

our $VERSION  = '2.7';

use Carp;
use strict;

#########################################################################

sub new
{
  my $pack = shift;
  my $class = ref( $pack ) || $pack;

  my $self = {};

  $self->{ 'TAGS'     } = {}; # tag tables
  $self->{ 'VARS'     } = {}; # var tables
  $self->{ 'INC'      } = {}; # include directories
  $self->{ 'ENV'      } = {}; # local environment, this is free for use

  $self->{ 'MODE'     } = []; # mode stack

  $self->{ 'WARNINGS' } = 0; # set to 1 for debug

  bless  $self, $class;
  return $self;
}

sub DESTROY
{
  my $self = shift;
  # nothing
}

sub define_tag
{
  my $self  = shift;

  confess "invalid arguments count, need MODENAME first" unless @_ % 2;

  my $mode  = shift || 'main';
  my %tags  = @_;

  $self->{ 'TAGS' }{ $mode } ||= {};
  %{ $self->{ 'TAGS' }{ $mode } } = ( %{ $self->{ 'TAGS' }{ $mode } }, %tags );
}

sub define_var
{
  my $self  = shift;

  confess "invalid arguments count, need MODENAME first" unless @_ % 2;

  my $mode  = shift || 'main';
  my %vars  = @_;

  $self->{ 'VARS' }{ $mode } ||= {};
  %{ $self->{ 'VARS' }{ $mode } } = ( %{ $self->{ 'VARS' }{ $mode } }, %vars );
}

sub add_inc_paths
{
  my $self  = shift;
  $self->{ 'INC' }{ $_ }++ for @_;
}

sub del_inc_paths
{
  my $self  = shift;
  delete $self->{ 'INC' }{ $_ } for @_;
}

sub mode_copy
{
  my $self  = shift;
  my $mode = shift; # destination mode

  for my $s ( @_ ) # for each source modes
    {
    # print "DEBUG: mode copy: [$mode] <- [$s]\n";
    while( my ( $k, $v ) = each %{ $self->{ 'TAGS' }{ $s } } )
      {
      # print "DEBUG:         TAG ($k) = ($v)\n";
      $self->define_tag( $mode, $k, $v );
      }
    while( my ( $k, $v ) = each %{ $self->{ 'VARS' }{ $s } } )
      {
      # print "DEBUG:         VAR ($k) = ($v)\n";
      $self->define_var( $mode, $k, $v );
      }
    }
}

sub mode_load
{
  my $self  = shift;
  my $file  = shift;

  my $target = 'main';
  open my $i, $file;
  while(<$i>)
    {
    next if /^\s*[#;]/; # comments
    chomp;
    if ( /^\s*MODE/i )
      {
      $_ = lc $_;
      s/\s+//g; # get rid of whitespace
      my @a = split /[:,]/;
      shift @a; # skip `mode' keyword
      $target = shift @a;
      $self->mode_copy( $target, @a );
      }
    else
      {
      $self->define_tag( $target, lc $1, $2 ) if /^\s*(<\S+)\s+(.*)$/;
      $self->define_var( $target, lc $2, $3 ) if /^\s*(%(\S+))\s+(.*)$/;
      }
    }
  close $i;
}

sub expand
{
  my $self  = shift;
  my $text  = shift;
  my $level = shift || 0;
  my $visited_arg = shift || {};

  my $visited = { %$visited_arg };

  #print "DEBUG: expand (level=$level) [text=$text]\n";

  $text =~ s/\(\%([^\(\)]+)\)/$self->expand_var( $1, $level+1, $visited )/gie;
  #print "DEBUG: ----------------------\n";
  $text =~ s/<([^<>]+)>/$self->expand_tag( $1, $level+1, $visited )/gie;
  #print "DEBUG: expand result: [text=$text]\n";
  return $text;
}

sub expand_var
{
  my $self    = shift;
  my $var     = shift;
  my $level   = shift;
  my $visited_arg = shift;

  my $visited = { %$visited_arg };

  return '***'.undef if $visited->{ "VAR::$var" }++; # avoids recursion
  my $mode = $self->{ 'MODE' }[0] || 'main';
  my $value =    $self->{ 'VARS' }{ $mode }{ $var }
              || $self->{ 'ENV' }{ $var };
  use Data::Dumper; # DEBUG
  print "DEBUG: expand_var: [$var] = ($value)\n".Dumper($visited)."\n";
  return $self->expand( $value, $level + 1, $visited );
}

sub expand_tag
{
  my $self    = shift;
  my $tag_org = shift;
  my $level   = shift;
  my $visited_arg = shift;

  my $visited = { %$visited_arg };

  my %args;
  my ( $tag, $args ) = split /\s+/, $tag_org, 2;
  # print "DEBUG: expand_tag: [$tag] -- ($args)\n";
  my $tag_lc = lc $tag;
  while( $args =~ /\s*([^=]+)(=('([^']*)'|"([^"]*)"|(\S*)))?/g ) # "' # fix string colorization
    {
    my $k = lc $1;
    my $v = $4 || $5 || $6 || 1;
    $args{ $k } = $v;
    # print "DEBUG:          [$k] = ($v)\n";
    }

  if ( $tag_lc eq 'mode' )
    {
    unshift @{ $self->{ 'MODE' } }, ( $args{ 'name' } || 'main' );
    $self->{ 'ENV' }{ '!MODE' } = $self->{ 'MODE' }[0] || 'main';
    return undef;
    }
  elsif ( $tag_lc eq '/mode' )
    {
    shift @{ $self->{ 'MODE' } };
    $self->{ 'ENV' }{ '!MODE' } = $self->{ 'MODE' }[0] || 'main';
    return undef;
    }
  if ( $tag_lc eq 'var' )
    {
    if( $args{ 'set' } eq '' )
      {
      return $self->expand_var( $args{ 'name' }, $level + 1, $visited );
      }
    else
      {
      $self->{ 'ENV' }{ uc $args{ 'name' } } = $args{ 'set' };
      return $args{ 'echo' } ? $args{ 'set' } : undef;
      }
    }
  elsif ( $tag_lc eq 'include' or $tag_lc eq 'inc' )
    {
    my $file_arg = $args{ 'file' };
    if( $file_arg !~ /^[a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]*)?$/ )
      {
      $self->warn( "forbidden include file name  `$file_arg'" );
      return undef
      }
    my $file;
    for( keys %{ $self->{ 'INC' } } )
      {
      $file = $_ . '/' . $file_arg;
      last if -e $file;
      $file = undef;
      }
    return undef if $visited->{ "INC::$file" }++; # avoids recursion
    open( my $i, $file ) || do
      {
      $self->warn( "cannot open file `$file'" );
      return undef;
      };
    my $data = $self->expand( join( '', <$i> ), $level + 1, $visited );
    close( $i );
    return $data;
    }
  elsif ( $tag_lc eq 'exec' )
    {
    my $cmd = $args{ 'cmd' };
    if( ! $self->{ 'EXEC_TAG_ALLOWED' } )
      {
      $self->warn( "exec is forbidden `$cmd'" );
      return undef;
      }

    open( my $i, $cmd . '|' ) || do
      {
      $self->warn( "exec failed `$cmd'" );
      return undef;
      };
    my $data = $self->expand( join( '', <$i> ), $level + 1, $visited );
    close $i;
    return $data;
    }
  else
    {
    $tag = "<$tag>";

    my $mode = $self->{ 'MODE' }[0] || 'main';
    my $value = $self->{ 'TAGS' }{ $mode }{ $tag };
    # print "DEBUG: mode name {$mode}, tag: $tag -> ($value)\n" if defined $value;
    if ( $value and ! $visited->{ "$mode::$tag" } )
      {
      # print "DEBUG:               ---> ($value)\n";
      $visited->{ "$mode::$tag" }++; # avoids recursion
      $value = $self->expand( $value, $level + 1, $visited );
      $value =~ s/\%([a-z_0-9]+)/$args{ lc $1 }/gi;
      my $ret = $self->expand( $value, $level + 1, $visited );
      # print "DEBUG: expand_tag return: [$ret]\n";
      return $ret;
      }
    else
      {
      # print "DEBUG: expand_tag original: [$tag_org]\n";
      return "<$tag_org>";
      }
    }
}

sub warn
{
  my $self = shift;
  return unless $self->{ 'WARNINGS' } || $self->{ 'WARN' };

  carp __PACKAGE__ . ": " . join( ' ', @_ );
}

=pod

=head1 NAME

HTML::Expander - html tag expander with inheritable tag definitions (modes)

=head1 SYNOPSIS

  use HTML::Expander;

  # get new HTML::Expander object;
  my $ex = new HTML::Expander;

  # load mode (tags) definitions
  $ex->mode_load( "/path/to/mode.def.txt" );

  # define some more tags
  $ex->define_tag( 'main', '<name>',  '<h1><font color=%c>' );
  $ex->define_tag( 'main', '</name>', '</font></h1>' );

  # copy `main' into `new' mode
  $ex->mode_copy( 'new', 'main' );

  # define one more tag
  $ex->define_tag( 'new', '<h1>',  '<p><h1>' );
  $ex->define_tag( 'new', '<box>',  '<pre>' );
  $ex->define_tag( 'new', '</box>',  '</pre>' );

  # expand!
  print $ex->expand( "<mode name=new>
                        (current mode is '<var name=!MODE>')
                        <name c=#fff>This is me</name>
                      </mode>
                        (current mode is '<var name=!MODE>')
                        <name>empty</name>
                      1.<var name=TEST>
                      2.<var name=TEST set=opala! echo>
                      3.<var name=TEST>
                      \n" );
  # the result will be:
  #                     <pre>(current mode is 'new')</pre>
  #                     <p><h1><font color=#fff>This is me</font></h1>
  #
  #                     <box>(cyrrent mode is 'main')</box>
  #                     <h1><font color=>empty</font></h1>
  #                   1.
  #                   2.opala!
  #                   3.opala!

  # this should print current date
  $self->{ 'EXEC_TAG_ALLOWED' } = 1; # allow execution of programs
  print $ex->expand( '<exec cmd=date>' ), "\n";
  $self->{ 'EXEC_TAG_ALLOWED' } = 0; # forbid execution of programs (default)

  # add include paths
  $ex->add_inc_paths( '/usr/html/inc', '/opt/test' );
  $ex->del_inc_paths( '.' );
  $ex->{ 'INC' }{ '.' } = 1;
  $ex->{ 'INC' }{ '/usr/html/inc' } = 1;
  $ex->{ 'INC' }{ '/opt/test' } = 1;

  # remove path
  delete $ex->{ 'INC' }{ '/usr/html/inc' };

  # include some file (avoiding recursion if required)
  print $ex->expand( '<inc file=test.pl>' ), "\n";

=head1 DESCRIPTION

HTML::Expander replaces html tags with other text (more tags, so it 'expands':))
with optional arguments. HTML::Expander uses tag tables which are called modes.
Modes can inherit other modes (several ones if needed). The goal is to have
as simple input html document as you need and have multiple different outputs.
For example you may want <box> tag to render either as <pre> or as
<table><tr><td> in two separated modes.

Essentially HTML::Expander works as preprocessor.

The mode file syntax is:

  tag   tag-replacement-string

  MODE: mode-name: inherited-modes-list

  tag   tag-replacement-string

  etc...

inherited-modes-list is comma or semicolon-separated list of modes that
should be copied (inherited) in this mode

The mode file example:

  ### begin mode

  # top-level mode is called `main' and is silently defined by default
  # mode: main

  <head1>   <h1>
  </head1>  </h1>

  <head2>   <h1><font color=#ff0000>
  </head2>  </h1></font>

  MODE: page: main

  <head2>   <h1><font color=#00ff00>

  MODE: edit: page, main

  # actually `page' inherits `main' so it is not really
  # required here to list `main'

  <head2>   <h1><font color=#0000ff><u>

This is not exhaustive example but it is just for example...

=head1 TAG ARGUMENTS

Inside the tag you can define arguments that can be used later during the
interpolation or as argument to the special tags etc.

Arguments cannot contain whitespace unless enclosed in " or ':

  <mytag arg=value>              # correct
  <mytag arg=this is long value> # incorrect!
  <mytag arg='the second try'>   # correct
  <mytag arg="cade's third try"> # correct

There is no way to mix " and ':

  <mytag arg='cade\'s third try'> # incorrect! there is no escape syntax

You can have unary arguments (without value) which, if used, have '1' value.

   <mytag echo> is the same as <mytag echo=1>

=head1 SPECIAL TAGS

There are several tags with special purposes:

  <mode name=name>

Sets current mode to `name' (saves it on the top of the mode stack).

  </mode>

Removes last used mode from the stack (if stack is empty `main' is used).
Both <mode> and </mode> are replaced with empty strings.

  <exec cmd=command>

This tag is replaced with `command's output. 'exec' is forbidden by default.
Using it will lead to empty string returned. To allow it you need to:

  $ex->{ 'EXEC_TAG_ALLOWED' } = 1; # allow execution of programs

($ex is the HTML::Expander object you want to allow execution)
exec must be used only if you produce html pages from static source, i.e. NOT
from end-user source like html forms etc.! To avoid unwanted execution the
program which uses HTML::Expander must encode all <>'s into html special
chars:

  >   must be converted to   &gt;
  <   must be converted to   &lt;

Rule of thumb is: do not use exec! :)

  <include file=incfile>
  or
  <inc file=incfile>

This tag is replaced with `incfile' file's content (which will be
HTML::Expanded recursively).

=head1 VARIABLES/ENVIRONMENT

HTML::Expander object have own 'environment' which is accessed this way:

$ex->{'ENV'}{ 'var-name' } = 'var-value';

i.e. $ex->{'ENV'} is hash reference to the local environment. There is no
special access policy.

There is syntax for variables interpolation. Values are taken from internal
environment table:

  (%VARNAME)

All variables are replaced before tag expansion! This helps to handle this:

  <tag argument=(%VAR) etc.>

If you need to interpolate variable in the tag expansion process (after the
variables interpolation) you need to:

  <var name=VARNAME>

If you need to set variable name during tag interpolation you should:

  <var name=VARNAME set=VALUE>

If you want to set variable and return its value at the same time you have to
use unary 'echo' argument:

  <var name=VARNAME set=VALUE echo>

(%VAR) variables are interpolated before %arg interpolation, so it is safe to
use this:

  <img src=(%WWWROOT)/%src>

=head1 BUGS

Unknown tags are left as-is, this is not bug but if you write non-html tag
which is not defined in mode tables it will passed into the output text.
(see <box> example above for 'main' mode)

If you find bug please contact me, thank you.

=head1 DIAGNOSTICS

HTML::Expander can report warnings if something wrong is going on. This is
assumed to be debugging or diagnostic tool so it is disabled by default.
To enable warnings:

  $ex->{ 'WARNINGS' } = 1;

=head1 TODO

  <empty>

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=head1 VERSION

  $Id: Expander.pm,v 1.18 2006/04/30 00:30:00 cade Exp $

=cut

#########################################################################
#   eof
#########################################################################
1;
