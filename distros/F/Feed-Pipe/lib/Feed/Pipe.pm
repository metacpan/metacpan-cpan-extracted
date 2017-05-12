package Feed::Pipe;
$Feed::Pipe::VERSION = '1.004';
use Moo;

use DateTime;
use DateTime::Format::HTTP;
use XML::Feed;
use XML::Atom;
use XML::Atom::Feed;
$XML::Atom::DefaultVersion = 1.0;
$XML::Atom::ForceUnicode = 1;

has id => (
  is => 'rw',
  lazy => 1,
  builder => sub {
    require Data::UUID;
    my $gen = Data::UUID->new;
    return 'urn:' . $gen->to_string($gen->create());
  },
);

has title => (
  is => 'rw',
  default => "Combined Feed",
);

has updated => (
  is => 'rw',
  lazy => 1,
  builder => sub { DateTime->now() },
);

sub count { scalar @{shift->_entries} }
sub entries { @{shift->_entries} }
sub _entry_at { shift->_entries->[shift] }
sub _grep {
  my ($self, $sub) = @_;

  grep $sub->($_), @{$self->_entries}
}

sub _map {
  my ($self, $sub) = @_;

  map $sub->($_), @{$self->_entries}
}

sub _push { push @{shift->_entries}, @_ }

sub _sort_in_place {
  my ($self, $cmp) = @_;

  @{$self->_entries} = (sort { $cmp->($a, $b) } @{$self->_entries});
}

has _entries => (
  is      => 'rw',
  default => sub { [] },
);

# FIXME: I really want this to add a <source> element to each entry so it can
# be traced back to its origin. And to be much more clever. And not to rely
# on XML::Feed.
sub cat {
  my ($proto, @feed_urls) = @_;
  my $self = ref($proto) ? $proto : $proto->new();

  foreach my $f (@feed_urls) {
    if (ref($f) eq 'Feed::Pipe') {
      $self->_push($f->entries);

    } elsif (ref($f) eq 'XML::Atom::Feed') {
      $self->_add_atom($f);

    } elsif (ref($f) =~ /^XML::Feed/) {
      $f = $self->_xf_to_atom($f);
      $self->_add_atom($f);

    } else {
      my $feed = XML::Feed->parse($f);
      $feed = $self->_xf_to_atom($feed);
      $self->_add_atom($feed);
    }
  }
  return $self;    # ALWAYS return $self for chaining!
}

sub sort {
  my ($self, $sub) = @_;
  $sub ||= sub {
    ($_[1]->updated || $_[1]->published)
      cmp($_[0]->updated || $_[0]->published)
  };
  $self->_sort_in_place($sub);
  return $self;    # ALWAYS return $self for chaining!
}

sub reverse {
  my ($self) = @_;
  $self->_entries([reverse $self->entries]);
  return $self;    # ALWAYS return $self for chaining!
}

sub head {
  my ($self, $limit) = @_;
  $limit ||= 10;
  $self->_entries([splice(@{$self->_entries}, 0, $limit)]);
  return $self;    # ALWAYS return $self for chaining!
}

sub tail {
  my ($self, $limit) = @_;
  $limit ||= 10;
  $self->_entries([splice(@{$self->_entries}, -$limit)]);
  return $self;    # ALWAYS return $self for chaining!
}

sub grep {
  my ($self, $sub) = @_;
  $sub ||= sub { $_->content || $_->summary };
  $self->_entries([$self->_grep($sub)]);
  return $self;    # ALWAYS return $self for chaining!
}

sub map {
  my ($self, $sub) = @_;
  unless ($sub) {
    my ($package, $file, $line) = caller();
    warn
      sprintf('Ignoring map() without a code reference at %s:%s', $file, $line);
    return $self;
  }
  $self->_entries([$self->_map($sub)]);
  return $self;    # ALWAYS return $self for chaining!
}

sub as_atom_obj {
  my ($self) = @_;
  my $feed = XML::Atom::Feed->new;

  # FIXME: Add support for (at least) the following elements: author category
  # contributor generator icon link logo rights subtitle
  $feed->title($self->title);
  $feed->id($self->id);
  $feed->updated(DateTime::Format::HTTP->format_isoz($self->updated));
  $feed->add_entry($_) for $self->entries;
  return $feed;
}

sub as_xml {
  my ($self) = @_;
  return $self->as_atom_obj->as_xml;
}

# This code stolen from XML::Feed::convert and mangled slightly.
sub _xf_to_atom {
  my ($self, $feed) = @_;
  return $feed->{atom} if $feed->format eq 'Atom';

  my $new = XML::Feed->new('Atom');
  for my $field (
    qw( title link self_link description language author copyright modified generator )
    ) {
    my $val = $feed->$field();
    next unless defined $val;
    $new->$field($val);
  }
  for my $entry ($feed->entries) {
    $new->add_entry($entry->convert('Atom'));
  }
  return $new->{atom};
}

sub _add_atom {
  my ($self, $feed) = @_;
  my @entries = $feed->entries;    # This clones the entry nodes.

  # Clean out the entries so we can use $feed as source
  for my $node ($feed->elem->childNodes) {
    if ($node->nodeName eq 'entry') {

      $node->unbindNode();
    }
  }
  $self->_push(map { $_->source($feed) unless $_->source; $_ } @entries);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Feed::Pipe

=head1 VERSION

version 1.004

=head1 SYNOPSIS

    use Feed::Pipe;
    my $pipe = Feed::Pipe
        ->new(title => "Mah Bukkit")
        ->cat( qw(1.xml 2.rss 3.atom) )
        ->grep(sub{$_->title =~ /lolrus/i })
        ->sort
        ->head
        ;
    my $feed = $pipe->as_atom_obj; # returns XML::Atom::Feed
    # Add feed details such as author and self link. Then...
    print $feed->as_xml;

=head1 DESCRIPTION

This module is a Feed model that can mimic the functionality of standard UNIX pipe and filter style text processing tools. Instead of operating on lines from text files, it operates on entries from Atom (or RSS) feeds. The idea is to provide a high-level tool set for combining, filtering, and otherwise manipulating bunches of Atom data from various feeds.

Yes, you could do this with Yahoo Pipes. Until they decide to take it down, 
or start charging for it. And if your code is guaranteed to have Internet 
access.

Also, you could probably do it with L<Plagger>, if you're genius enough to figure
out how.

=head1 NAME

Feed::Pipe - Pipe Atom/RSS feeds through UNIX-style high-level filters

=head1 CONSTRUCTOR

To construct a feed pipe, call C<new(%options)>, where the keys of C<%options> 
correspond to any of the method names described under ACCESSOR METHODS. If you 
do not need to set any options, C<cat> may also be called on a class and will
return an instance.

    my $pipe = Feed::Pipe->new(title => 'Test Feed');

=head1 FILTER METHODS

=head2 C<cat(@feeds)>

    my $pipe = Feed::Pipe->new(title => 'Test')->cat(@feeds);
    # This also works:
    my $pipe = Feed::Pipe->cat(@feeds);

Combine entries from each feed listed, in the order received, into a single feed.
RSS feeds will automatically be converted to Atom before their entries are
added. (NOTE: Some data may be lost in the conversion. See L<XML::Feed>.)

If called as a class method, will implicitly call C<new> with no options
to return an instance before adding the passed C<@feeds>.

Values passed to C<cat> may be an instance of Feed::Pipe, XML::Atom::Feed,
XML::Feed, or URI, a reference to a scalar variable containing the XML to
parse, or a filename that contains the XML to parse. URI objects will be 
dereferenced and fetched, and the result parsed.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<grep(sub{})>

    # Keeps all entries with the word "Keep" in the title
    my $pipe = Feed::Pipe
    ->cat($feed)
    ->grep( sub { $_->title =~ /Keep/ } )
    ;

Filters the list of entries to those for which the passed function returns
true. If no function is passed, the default is to keep entries which have
C<content> (or a C<summary>). The function should test the entry object 
aliased in C<$_> which will be a L<XML::Atom::Entry>.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<head(Int $limit=10)>

Output C<$limit> entries from the top of the feed, where C<$limit> defaults to
10. If your entries are sorted in standard reverse chronological order, this
will pull the C<$limit> most recent entries.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<map(\&mapfunction)>

    # Converts upper CASE to lower case in each entry title.
    my $pipe = Feed::Pipe
    ->cat($feed)
    ->map( sub { $_->title =~ s/CASE/case/; return $_; } )
    ;

Constructs a new list of entries composed of the return values from 
C<mapfunction>. The mapfunc I<must> return one or more XML::Atom::Entry
objects, or an empty list. Within the C<mapfunction> C<$_> will be
aliased to the XML::Atom::Entry it is visiting.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<reverse()>

Returns the feed with entries sorted in the opposite of the input order. This
is just for completeness, you could easily do this with C<sort> instead.

=head2 C<sort(sub{})>

    # Returns a feed with entries sorted by title
    my $pipe = Feed::Pipe
    ->cat($feed)
    ->sort(sub{$_[0]->title cmp $_[1]->title})
    ;

Sort the feed's entries using the comparison function passed as the argument.
If no function is passed, sorts in standard reverse chronological order.
The sort function should be as described in Perl's L<sort>, but using
C<$_[0]> and C<$_[1]> in place of C<$a> and  C<$b>, respectively. The two
arguments will be L<XML::Atom::Entry> objects.

Returns the feed pipe itself so that you can chain method calls.

=head2 C<tail(Int $limit=10)>

Output C<$limit> entries from the end of the feed, where C<$limit> defaults to
10. If your entries are sorted in standard reverse chronological order, this
will pull the C<$limit> oldest entries.

Returns the feed pipe itself so that you can chain method calls.

=head1 ACCESSOR METHODS

B<NOTE: These methods are not filters. They do not return the feed pipe and
must not be used in a filter chain (except maybe at the end).>

=head2 title

Human readable title of the feed. Defaults to "Combined Feed".

=head2 id

A string conforming to the definition of an Atom ID. Defaults to a newly
generated UUID.

=head2 updated

A DateTime object representing when the feed should claim to have been updated.
Defaults to "now".

=head1 OTHER METHODS

B<NOTE: These methods are not filters. They do not return the feed pipe and
must not be used in a filter chain (except maybe at the end).>

=head2 C<as_atom_obj>

Returns the L<XML::Atom::Feed> object represented by the feed pipe.

=head2 C<as_xml>

Serialize the feed object to an XML (Atom 1.0) string and return the string. 
Equivalent to calling C<$pipe-E<gt>as_atom_obj-E<gt>as_xml>. NOTE: The current
implementation does not guarantee that the resultant output will be valid Atom.
In particular, you are likely to be missing required C<author> and C<link>
elements. For the moment, you should use C<as_atom_obj> and manipulate the
feed-level elements as needed if you require validatable output.

=head2 C<count>

Returns the number of entries in the feed.

=head2 C<entries>

Returns the list of L<XML::Atom::Entry> objects in the feed.

=head1 AUTHOR

Vince Veselosky <vince at control-escape.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Vince Veselosky.

This is free software, licensed under:

  The MIT (X11) License

=cut
