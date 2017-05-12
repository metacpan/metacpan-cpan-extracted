use strict;
use warnings;

package KSx::IndexManager;

use 5.00.004; # KinoSearch requires this
our $VERSION = '0.004';
use base qw(Class::Accessor::Grouped);

__PACKAGE__->mk_group_accessors(simple    => qw(root schema context _lock_fh));
__PACKAGE__->mk_group_accessors(inherited => qw(_plugins));
__PACKAGE__->mk_group_accessors(
  component_class => qw(invindexer_class searcher_class schema_class),
);
__PACKAGE__->invindexer_class('KinoSearch::InvIndexer');
__PACKAGE__->searcher_class('KinoSearch::Searcher');

use KinoSearch::Searcher;
use KinoSearch::InvIndexer;
use KinoSearch::Schema;

use Data::OptList;
use Carp ();
use Scalar::Util ();
use Fcntl qw(:DEFAULT :flock);

sub plugins { @{ $_[0]->_plugins || $_[0]->_plugins([]) } }

sub add_plugins {
  my $class = shift;
  if (Scalar::Util::blessed $class) { 
    Carp::croak "add_plugins is a class method, do not call it on $class";
  }
  my @plugins = $class->plugins;
  for my $opt (@{ Data::OptList::mkopt([@_]) }) {
    my ($plugin, $arg) = @$opt;
    $plugin = "KSx::IndexManager::Plugin::$plugin" 
      unless $plugin =~ s/^\+//;
    eval "require $plugin; 1" or die $@;
    push @plugins, $plugin->new($arg);
  }
  $class->_plugins(\@plugins);
}

sub call_plugins {
  my ($self, $event, $arg, @rest) = @_;
  for my $plugin ($self->plugins) {
    #use Data::Dumper; warn Dumper($plugin);
    $plugin->$event($arg, @rest);
  }
}

sub call_self_plugins {
  my ($self, $event, $arg, @rest) = @_;
  $arg ||= {};
  for my $plugin ($self->plugins) {
    $plugin->$event($self, $arg, @rest);
  }
}

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  $class->call_plugins(before_new => $arg);
  unless ($arg->{schema} ||= $class->schema_class) {
    Carp::croak "schema is mandatory for $class->new";
  }
  my $self = bless $arg => $class;
  $self->call_self_plugins('after_new');
  return $self;
}

sub path {
  my $self = shift;
  my $path = $self->root;
  $self->call_self_plugins(alter_path => \$path);
  return $path;
}

sub open    { shift->invindexer({ mode => 'open'    }) }
sub clobber { shift->invindexer({ mode => 'clobber' }) }

sub invindexer {
  my ($self, $opt) = @_;
  Carp::croak "'mode' argument is mandatory for $self->invindexer"
    unless $opt->{mode};
  my $meth = $opt->{mode};
  return $self->invindexer_class->new(
    invindex => $self->schema->$meth($self->path),
  );
}

sub _load {
  my ($self, $i, $opt) = @_;
  $i->{$self->path} ||= $self->invindexer($opt);
}

sub to_doc {
  my ($self, $obj) = @_;
  return $obj;
}

sub _add_one_doc {
  my ($self, $i, $obj, $opt) = @_;
  my $inv = $self->_load($i, $opt);
  $self->call_self_plugins(before_add_doc => $obj);
  for my $doc ($self->to_doc($obj)) {
    $inv->add_doc($doc);
  }
  # wish we could call it with the new document or something
  $self->call_self_plugins(after_add_doc => $obj);
}

sub add_docs {
  my ($self, $opt, $docs) = @_;
  my $created = 0;
  my $i = {}; # invindex cache by path
  if (ref $docs eq 'ARRAY') {
    $created = @$docs;
    for my $obj (@$docs) {
      $self->_add_one_doc($i, $obj, $opt);
    }
  } elsif (eval { $docs->can('next') }) {
    while (my $obj = $docs->next) {
      $self->_add_one_doc($i, $obj, $opt);
      $created++;
    }
  } else {
    die "unhandled argument: $docs";
  }
  return 0 if $opt->{mode} eq 'open' and not $created;
  $_->finish(
    optimize => $opt->{optimize} || 0,
  ) for values %$i;
  return $created;
}

sub append { shift->add_docs({ mode => 'open'    }, @_) }
sub write  { shift->add_docs({ mode => 'clobber' }, @_) }

sub lockfile { File::Spec->catfile(shift->path, 'mgr.lock') }

sub lock {
  my $self = shift;
  my $file = $self->lockfile;
  my $fh;
  File::Path::mkpath($self->path);
  unless (sysopen($fh, $file, O_RDWR|O_CREAT|O_EXCL)) {
    my $err = $!;
    if (-e $file) {
      sysopen($fh, $file, O_RDWR) or die "can't sysopen $file: $!";
    } else {
      die "can't sysopen $file: $err";
    }
  }
  flock($fh, LOCK_EX|LOCK_NB) or die "$file is already locked";
  $self->_lock_fh($fh);
}

sub unlock {
  my $self = shift;
  my $file = $self->lockfile;
  die "$file is not locked" unless $self->_lock_fh;
  flock($self->_lock_fh, LOCK_UN) or die "can't unlock $file: $!";
}

sub search {
  my $self = shift;
  return $self->searcher->search(@_);
}

sub searcher {
  my $self = shift;
  return $self->searcher_class->new(
    invindex => $self->schema->read($self->path),
  );
}

1;

__END__

=head1 NAME

KSx::IndexManager - high-level invindex management interface

=head1 VERSION

 0.004

=head1 SYNOPSIS

  my $mgr = KSx::IndexManager->new({
    root   => '/path/to/some/dir',
    schema => 'My::Schema',
  });

  my %arg = (type => "animal", id => 17);

  $mgr->context(\%arg);

  $mgr->write(\@docs);
  $mgr->append(\@more_docs);
  my $hits = $mgr->search(%search_arg);

  my $invindexer = $mgr->invindexer;

  my $searcher = $mgr->searcher;

=head1 NOTICE

This module is new and not completely thought out.  The interface may change in
incompatible ways, though I will give big alerts in the changelog when that
happens.  Please use it and give me feedback.  Please do not use it if you want
something that you can install and forget about.

In particular, the plugin interface is likely to change a great deal.

=head1 DESCRIPTION

KSx::IndexManager aims to provide simple access to one or more invindexes that
all share a single schema.

Functionality is intentionally simple and is basically limited to convenient
wrappers around common InvIndexer and Searcher methods.  Additional
functionality can be added through L<plugins|/PLUGINS>.

=head1 CLASS METHODS

=head2 new

  my $mgr = KSx::IndexManager->new(\%data);

Return a new IndexManager.  Possible data keys are L<root|/root>,
L<context|/context>, and L<schema|/schema>; see those method descriptions for
details.

=head2 add_plugins

  My::Manager->add_plugins( $plugin => \%arg, $other_plugin => \%other_arg );

Instantiates one or more plugins and adds them to the manager class.  See
L<PLUGINS|/PLUGINS> for details.

Arguments are a list of pairs, plugin name and hashref of arguments.  See
individual plugin classes for details.

=head2 invindexer_class

=head2 searcher_class

=head2 schema_class

Default to KinoSearch::InvIndexer and KinoSearch::Searcher, respectively.
Setting these to new classes will automatically load those classes; see
L<Class::Accessor::Grouped/set_component_class>.

If you do not set schema_class, you will have to supply a L<schema|/schema>
argument for every object instantiation.

=head1 OBJECT ACCESSORS

=head2 root

Accessor/mutator for the base directory for this Manager.  This directory may
or may not actually be an invindex, depending on the plugins loaded.

=head2 schema

Name of the KinoSearch::Schema-derived class to use.  This argument is
mandatory if you have not set L<schema_class|/schema_class>.

=head2 context

Arbitrary, application-specific data that defines the current context for index
management.  For example, the L<Partition|KSx::IndexManager::Plugin::Partition>
plugin looks at the manager's context to determine which specific invindex to
use.

=head2 path

Returns the path to the manager's invindex, based on C<root> (and possibly
C<context>).  With no plugins loaded, this is probably the same as C<root>.

=head1 WRITING TO INVINDEXES

=head2 write

=head2 append

=head2 add_docs

  $mgr->add_docs(\%options, \@docs);
  $mgr->add_docs(\%options, $doc_iterator);

  $mgr->write(\@docs);
  $mgr->append(\@docs);

Add documents to an invindex.  This combines invindexer creation, document
addition, and invindexer finishing all in one call.

Currently the only valid option is C<mode>, which may be one of 'clobber' or
'open'.

C<write> and C<append> are convenient wrappers around C<add_docs> with the
'clobber' and 'open' modes, respectively.

The documents to be added may be passed in an arrayref or an iterator.  Any
object with a 'next' method will be treated as an iterator and used until
exhausted.

Returns the number of objects processed.

=head2 to_doc

  my $doc = $mgr->to_doc($obj);

Given some object, convert it into a document suitable for passing to the
invindexer's L<add_doc|KinoSearch::InvIndexer/add_doc> method.

The structure of the object is manager-subclass dependent.  The default
C<to_doc> is to do nothing, meaning that the object should be a hashref whose
keys correspond to the schema class' fields.

You almost certainly want to override this in your manager subclass.

=head2 clobber

=head2 open

=head2 invindexer

  my $invindexer = $mgr->invindexer({ mode => $mode });

Open a new invindexer with the given mode, which may be one of 'clobber' or
'open'.

C<clobber> and C<open> are convenient wrappers around C<invindexer> with the
'clobber' and 'open' modes, respectively.

=head2 lock

=head2 unlock

=head2 lockfile

  $mgr->lock;
  # do some stuff
  $mgr->unlock;

You should never have to use these methods.

C<lock> and C<unlock> open and call C<flock()> on the file 'mgr.lock' in the
manager's C<path>.  Writing to the invindex calls these methods implicitly.

If the lockfile is already locked, C<lock> will die.

=head1 READING FROM INVINDEXES

=head2 searcher

=head2 search

  my $searcher = $mgr->searcher;

  my $hits = $mgr->search(%args);

Retrieve a searcher (using C<searcher_class>).

C<search> is a shortcut for C<< $mgr->searcher->search >>.

=begin dev

=head2 plugins

=head2 call_plugins

=head2 call_self_plugins

=end dev

=head1 PLUGINS

A manager class can add any number of plugins.  Plugin names are assumed to be
under C<KSx::IndexManager::Plugin::> unless they are prepended with a '+'
(C<+My::KSx::Plugin>).

Plugins can be added multiple times, possibly with different arguments.  See
L<KSx::IndexManager::Plugin::Partition> for an example.

See L<KSx::IndexManager::Plugin> for details of what plugins can do, and see
L<add_plugin|/add_plugin> for details of adding them.

=head1 SEE ALSO

L<KinoSearch>

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ksx-indexmanager at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=KSx-IndexManager>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc KSx::IndexManager

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/KSx-IndexManager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/KSx-IndexManager>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=KSx-IndexManager>

=item * Search CPAN

L<http://search.cpan.org/dist/KSx-IndexManager>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Listbox.com, who sponsored the original version of this module.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
