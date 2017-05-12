package Dist::Zilla::Plugin::FileKeywords;
# ABSTRACT: Expand $$Keywords$$ in your files.

use Moose;
use Moose::Autobox;

BEGIN
  {
    $Dist::Zilla::Plugin::FileKeywords::VERSION
      = substr '$$Version: 0.02 $$', 11, -3;
  }

use Data::Dumper;

with
  ( 'Dist::Zilla::Role::FileMunger'
  , 'Dist::Zilla::Role::FileFinderUser' =>
      { default_finders => [ ':InstallModules', ':ExecFiles' ] }
  );

sub mvp_multivalue_args { qw(includes excludes keywords plugins) }
sub mvp_aliases
  {
    return
      { include => 'includes'
      , exclude => 'excludes'
      , keyword => 'keywords'
      , plugin  => 'plugins'
      }
  }

has debug      =>
  ( is	       => 'rw'
  , isa	       => 'Bool'
  , default    => 0
  , trigger    => \&_update_debug
  );

has includes =>
  ( is	     => 'ro'
  , isa	     => 'ArrayRef'
  , default  => sub{ return ['.*'] }
  );

has excludes =>
  ( is	     => 'ro'
  , isa	     => 'ArrayRef'
  , default  => sub{ return ['.t$'] }
  );

# Restrict defined keywords to this list.
# not yet implemented.
has keywords =>
  ( is	     => 'ro'
  , isa	     => 'ArrayRef'
  );

has plugins  =>
  ( is	     => 'ro'
  , isa	     => 'ArrayRef'
  , default  => sub{ return ['Standard'] }
  );

# private attributes

has keylist  =>
  ( is       => 'rw'
  , isa      => 'HashRef'
  , init_arg => undef
  , default  => sub{ return {} }
  );

has delim    =>
  ( is	     => 'rw'
  , isa	     => 'ArrayRef'
  , init_arg => undef
  , default  => sub{ ['$$','$$'] }
  );

# Triggers
sub _update_debug
  { my ($self,$arg) = @_;

    $self->log_debug("Setting Debug to $arg");
    $self->logger->set_debug($arg);
    $self->log_debug("Debug now set to $arg");
    return $arg;
  }

# Utility Routines
sub matches
  { my ($file,$arr) = @_;

    ($file =~ m/$_/ && return 1) for @$arr;
    return 0;
  }

sub expand
  { $_ = $_[0];

    s/$$/\$\$/g;
    return $_;
  }

sub keyval
  { my ($self,$file,$beg,$hid,$keyword,$delim,$value,$end) = @_;
    my $keylist = $self->keylist;
    my $newval	= expand($$keylist{$keyword}->value($file,$keyword));

    if( defined $hid )
      {
	return $newval
	  if( !defined($delim) || length($delim) < 2 );

	my $len = length("$beg$hid$keyword$delim $value $end");
	return sprintf("%-${len}.${len}s",$newval);
      }

    return $beg.$keyword.': '.$newval.' '.$end
      if( !defined($delim) || length($delim) < 2 );

    my $len = defined($value) ? length($value) : 0;
    my $tag = ( length($newval) > $len ) ? '#' : ' ';

    return sprintf("$beg$keyword$delim %-${len}.${len}s$tag$end",$newval);
  }

# Methods
sub munge_file
  { my ($self, $file) = @_;
    my $keylist	      = $self->keylist;
    my @delim	      = $self->delim->flatten;

    # not happy about recomputing $rex all the time,
    # but I wasn't happy with the workarounds I tried either
    my $alt  = '(?:'.$keylist->keys->join('|').')';
    my $rex  = qr/(\Q$delim[0]\E)(:)?($alt)(?:(::?)\s(.*?)\s)?(\Q$delim[1]\E)/;
    my $name = $file->name;
    my $contents = $file->content;

    $self->log_debug("Matching $rex against $name");
    # What follows doesn't work if the $file isa FromCode file.
    # In that case we should build a closure around the existing
    # FromCode code and set that to be the new code attribute, but
    # that's more work than I wanna do right now.
    if( $contents =~ s/$rex/$self->keyval($file,$1,$2,$3,$4,$5,$6)/eg )
      {
	$self->log_debug("File $name modified");
	$file->content($contents);
      }
    else
      { $self->log_debug("File $name unchanged"); }
    return;
  }


sub munge_files
  { my ($self)	= @_;
    my @plugins	= @{ $self->plugins };
    my $keylist = $self->keylist;

    for my $plugspec (@plugins)
      { my ($plugin,$args) =
	  ($plugspec =~ m/^\s*([\w:]+)(?:\(([^)]+)\))?\s*$/g);

	die("Cannot Parse: $plugspec") unless defined $plugin;

	my $arghash = { zilla => $self->zilla };

	$$arghash{import} = [ split(/\w+/,$args) ] if defined $args;

	my $class = "Dist::Zilla::Plugin::FileKeywords::$plugin";

	$self->log_debug("Loading: $class");
	Class::MOP::load_class($class);

	my $obj	= $class->new($arghash);
	foreach my $key (@{$obj->keylist})
	  {
	    die("Double definition of keyword \"$key\"")
	      if exists $$keylist{$key};
	    $$keylist{$key} = $obj;
	  }
      }

    for my $file (@{$self->zilla->files})
      {
	$self->munge_file($file)
	  if    matches($file->name, $self->includes)
	  and ! matches($file->name, $self->excludes);
      }
  }


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::FileKeywords - expand $$Keywords$$ in your files.

=head1 VERSION

version 1.0

=head1 DESCRIPTION

This plugin is a file_munger. It processes a list of files (by default
all files in the distribution) and replaces all occurances of known
keywords with their expansions.

It does this is in a manner similar to how Subversion manages
keywords. In particular it looks for keywords in the forms:

  $$KEYWORD$$
  $$KEYWORD: Stuff $$
  $$KEYWORD::    Stuff $$

  $$:KEYWORD$$
  $$:KEYWORD: Stuff $$
  $$:KEYWORD::    Stuff $$

Keywords are matched in a case-sensitive manner and only constructs
containing defined keywords are modified. If no colon follows the
opening '$$' delimeters then the text between the two '$$' delimeters
are replaced with the Keyword, one or more colons (:) and the
expansion of the keyword, with a space on either side.

In the first two cases a single colon and space follows the keyword
and the full expansion appears, however long, followed by a space and
the closing '$$' delimeter. If the expansion should contain '$$' by
any chance, it will be expanded as '\$\$'.

In the third case a pair of colons and a space follows the keyword and
the expansion is truncated, if necessary, so the final construct is no
bigger (in characters) than what it replaces. If it is necessary to
truncate the expansion, then the final character before the closing
delimeter will be a hatch (#) rather than a space.

When a colon follows the opening delimeter, then the entire text of
the keyword form, including the delimeters, is replaced by the keyword
expansion. In the final version, where there are two colons, the
keyword expansion is padded with spaces, or truncated, to occupy the
exact same number of characters as the form that is being
replaced. Note that in the case of truncation, no '#' will be provided.

Actual keywords are defined in plugins in the
Dist::Zilla::Plugin::FileKeywords:: namespace. Currently the only
plugin is Dist::Zilla::Plugin::FileKeywords::Standard and the only two
keywords it defines are Version (equal to dzil's idea of the current
version number) and Distribution (always equal to 'unknown' for now).

plugins need to be loaded with one or more 'plugin' arguments that
list a plugin name, optionally followed by a list of keywords in
parens.

  plugins = Standard(Version Distribution) Weird(Chicken)
  plugins = Weirder

Currently all keywords in all mentioned plugins are made active. In
the future more plugins will appear and some of the stubs for dealing
with which sets of plugins/keywords are active will be made to
actually do something.

One can also control which files get processed by using the 'include'
and 'exclude' file regular expressions. All files are processed that
match an include regex and do not match any exclude regexes.

=head1 AUTHOR

Stirling Westrup <swestrup@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Stirling Westrup.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

