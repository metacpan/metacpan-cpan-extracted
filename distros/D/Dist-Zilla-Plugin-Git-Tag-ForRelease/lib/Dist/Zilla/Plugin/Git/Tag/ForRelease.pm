package Dist::Zilla::Plugin::Git::Tag::ForRelease;
# ABSTRACT: Create a Release Tag Before Building the Distribution.

use Moose;

BEGIN
  {
    $Dist::Zilla::Plugin::Git::Tag::ForRelease::VERSION
      = substr '$$Version: v0.05 $$', 11, -3;
  }

use Git;
use Perl::Version;

with
  ( 'Dist::Zilla::Role::BeforeBuild'
  , 'Dist::Zilla::Role::AfterRelease'
  , 'Dist::Zilla::Role::VersionProvider'
  );

my $cleanup_hook = undef;

# Public attributes

# Git repository location. Defaults to current dir.
has repo_dir =>
  ( is       =>	'ro'
  , isa      => 'Str'
  , default  => '.'
  , init_arg => 'repository'
  );

# tag to put on the very first commit, if it doesn't exist.
has base_version =>
  ( is	      => 'ro'
  , isa	      => 'Str'
  , default   => '0.00'
  );

has alpha_format =>
  ( is	      => 'ro'
  , isa       => 'Str'
  , default   => '%d.%02d_%03d'
  );

has version_format =>
  ( is	      => 'ro'
  , isa       => 'Str'
  , default   => '%d.%02d'
  );

# String prepended to the version, to create a tag.
has tag_prefix =>
  ( is	       => 'ro'
  , isa	       => 'Str'
  , default    => 'v'
  );

# Regex matching those tags to consider
has matches   =>
  ( is	      => 'ro'
  , isa       => 'Str'
  , predicate => 'has_matches'
  );

# Flag to tag a release, even if --trial has been specified
has tag_trials =>
  ( is	       => 'rw'
  , isa	       => 'Bool'
  , default    => 0
  );

# should we output log_debug calls.
has debug      =>
  ( is	       => 'rw'
  , isa	       => 'Bool'
  , default    => 0
  , trigger    => \&_update_debug
  );

# internal attributes

has command    =>
  ( is	       => 'ro'
  , isa	       => 'Dist::Zilla::App::Command'
  , default    => sub { $App::Cmd::active_cmd; }
  , init_arg   => undef
  );

has repo       =>
  ( is	       => 'ro'
  , isa	       => 'Git::Wrapper'
  , lazy_build => 1
  , init_arg   => undef
  );

has is_trial   =>
  ( is	       => 'rw'
  , isa	       => 'Bool'
  , lazy_build => 1
  , init_arg   => undef
  );

# Object representing the version we tag with.
has verobj     =>
  ( is	       => 'ro'
  , isa	       => 'Perl::Version'
  , lazy_build => 1
  , init_arg   => undef
  );

# This is the version string we tag with
has version    =>
  ( is	       => 'ro'
  , isa	       => 'Str'
  , lazy_build => 1
  , init_arg   => undef
  );

# will we actually commit a tag
has will_tag =>
  ( is	     => 'rw'
  , isa	     => 'Bool'
  , default  => 1
  );

# Triggers
sub _update_debug
  { my ($self,$arg) = @_;

    $self->log_debug("Setting Debug to $arg");
    $self->logger->set_debug($arg);
    $self->log_debug("Debug now set to $arg");
    return $arg;
  }

sub _build_is_trial
  { my $self = shift;

    return $self->zilla->is_trial;
  }

sub _build_repo
  { my $self = shift;

    return Git::Wrapper->new($self->repo_dir);
  }

sub _build_verobj
  { my $self  = shift;
    my ($cmd) = ($self->command =~ m/::([^:]+)=[^:]*$/);

    $self->is_trial(1) unless( $cmd eq 'release' );

    my $git	= $self->repo;
    my $descopt =
      { abbrev  => 40
      , long    => 1
      , tags    => 1
      };

    $$descopt{match} = $self->matches if has_matches();

    my ($desc) = eval { $git->describe( my $x={%$descopt} ) };
    my ($tag, $count, $commit);
    if( $@ )
      {	my $e = $@->error;

	die unless $e =~ m/No names found/;
	if( $self->is_trial && !$self->tag_trials)
	  {
	    $self->logger->log_fatal
	      ( "No previous tags found, and in trial mode\n"
	      . "Please create a base tag, run release without --trial,\n"
	      . "or turn on the tag_trials flag in dist.ini"
	      );
	  }

	$tag = $self->tag_prefix.$self->base_version;
	$self->logger->log_debug("Creating a base tag: $tag");
	my ($base) = $git->rev_list({reverse => 1},'HEAD');
	$self->logger->log_debug("Base commit is: $base");
	$git->tag({m => "Base Tag for Tagging Releases"}, $tag, $base);
	($desc) = $git->describe( my $x={%$descopt} );
      }

    $self->logger->log_debug("Describe: $desc");
    ($tag,$count,$commit) = ($desc =~  m/^(.*)-(\d+)-g([0-9a-f]{40})$/);
    $self->logger->log_debug("Desc: $tag, $count, $commit");

    my $version = Perl::Version->new( $tag );

    if( !$count )
      {
	$self->logger->log("Already Tagged. Not tagging again.");
	$self->will_tag(0);
	return $version;
      }

    if( $self->is_trial )
      {
	$version->alpha($count);
	$self->will_tag(0) unless $self->tag_trials;
      }
    else
      { $version->inc_version(); }
    return $version;
  }

sub _build_version
  { my $self = shift;

    my $ver = $self->verobj;

    my $fmt = $self->is_trial
      ? $self->alpha_format
      : $self->version_format;

    my $str = sprintf($fmt,$ver->components,$ver->alpha);
    $self->logger->log("Version String is: $str");
    return $str;
  }

# this is called the first time anyone tries to access
# $self->zilla->version.
sub provide_version{ return $_[0]->version; }

sub before_build
  { my $self  = shift;
    my ($cmd) = ($self->command =~ m/::([^:]+)=[^:]*$/);
    return unless ($cmd eq 'release');

    my $tag = $self->tag_prefix.$self->version;

    $self->logger->log
      ( ($self->will_tag ? "Tagging With: " : "Pretending to Tag: ")
	. $tag
      );
    return unless $self->will_tag;
    my $git = $self->repo;
    $git->tag({m => "Tagged for Release", a => 1},$tag);

    $cleanup_hook = sub
      {
	$self->logger->log("Removing Tag because Release did not complete.");
	$git->tag({d => 1}, $tag);
      };
  }

sub after_release
  {
    # Prevent erasure of the tag in the exit block.
    $cleanup_hook = undef;
  }


# This gets run at program exit.
END{ &$cleanup_hook if defined $cleanup_hook; }

__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Git::Tag::ForRelease -
Create a Release Tag Before Building the Distribution.

=head1 VERSION

version v0.05

=head1 SYNOPSIS

In your F<dist.ini>:

  [Git::Check]           ; Check that everything has been checked in.
  [Git::Tag::ForRelease] ; Create a new release version tag.

=head1 DESCRIPTION

This plugin attempts to tag the current repository with an appropriate
new version number.

=head1 ATTRIBUTES

=head2 repo_dir

The Git repository location. Defaults to the current dir.

=head2 base_version

The version number to use for the very first commit, if one doesn't
exist. defaults to '0.00';

=head2 alpha_format

The sprintf string to use to generate an alpha version. Defaults to
'%d.%02d_%03d'

=head2 version_format

The sprintf string to use to generate a regular version
number. Defaults to '%d.%02d'

=head2 tag_prefix

This string is prepended to the version number to form the tag name to
tag the repository with. Defaults to 'v'

=head2 matches

This is a regex string that is used when searching the repository for
the latest tag to increment. Only the latest tag matching this regex
will count as a version tag to be incremented. By default this value
is empty, so all tags are considered to be version tags.

=head2 tag_trials

Normally, a release built with the 'dzil release --trial' command does
not result in an actual tag being committed to the repository, unless
this attribute has been set.

=head2 debug

If turned on, the plugin will produce some debugging output while working.

=head1 AUTHOR

Stirling Westrup <swestrup@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Stirling Westrup.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
