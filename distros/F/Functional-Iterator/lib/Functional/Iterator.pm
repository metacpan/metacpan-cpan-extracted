use strict;
use warnings;

package Functional::Iterator;
use base qw(Exporter);

our @EXPORT = qw(iterator);

our $VERSION = 1.05;

sub iterator { __PACKAGE__->new(@_) }

sub new {
  my ($class, %args) = @_;
  return bless +{
    %args,
    index => 0,
  }, $class;
}

sub next {
  my ($self) = @_;

  my $record;
  my $index = $self->{index};

  if (exists $self->{generated_record}) {
    # If the previous call to ->next() yielded an iterator, then we stashed that
    # iterator into $self->{generated_record} and returned that stashed iterator's
    # ->next record. Now it's time to ask that stashed previously-generated-but
    # now-active iterator for another record.
    $record = delete $self->{generated_record};
  } elsif (exists $self->{generator}) {
    # We have no current stashed iterator: either our generator doesn't produce
    # iterators, or the last iterator it produced has been exhausted.
    $record = $self->{generator}->();
  } else {
    # Oh, we're just a simple iterator over records, how nice.
    $record = $self->{records}[$index];
  }

  if (UNIVERSAL::isa($record, ref($self))) {
    $self->{generated_record} = $record      # The putative $record is actually an iterator, so stash it away...
      if exists $self->{generator};          # ...(maybe)...
    $record = $record->next;                 # ...and ask it for its next record.

    if (! defined($record)) {                      # Whoops, the stashed-away iterator is exhausted...
      if (exists $self->{records}[$index + 1]) {   # Simple iterator-over-records case
        $self->{index}++;
        return $self->next;
      } else {                                     # Oh, there's no next record available: why not?
        if (exists $self->{generator}) {           # ...because we're an iterator over generated iterators.
          delete $self->{generated_record};        #    ...Okay, discard this iterator (it's clearly exhausted)
          return $self->next;                      #    ...and ask myself for another
        } else {                                   # ...because we're an iterator over records
          return undef;                            #    ...but there is no next record, so signal exhaustion
        }
      }
    }
  } else {
    $self->{index}++;
  }
  return undef unless defined $record;

  return $self->{mutator}
    ? $self->{mutator}->($record)
    : $record;
}

sub reset {
  my ($self) = @_;
  $self->{index} = 0;
  delete $self->{generated_record};
  foreach (grep { UNIVERSAL::isa($_, __PACKAGE__) } @{$self->{records}}) {
    $_->reset;
  }
}

1;

__END__

=pod

=head1 NAME

Functional::Iterator - A generic iterator

=head1 SYNOPSIS

A naive example is just to turn a list into an iterable:

    use Functional::Iterator;

    my $iterator = iterator(records => [1..10]);

    while (my $rec = $iterator->next) {
      print "$rec\n";
    }

A slightly more interesting example is to turn a paginated set of results from some web API into
a seemingly unlimited stream of data. In one module you might write this:

    sub fetch_popular_results {
        my @records;
        my $page = 0;

        my $client = REST::Consumer->new(host => 'somewhere-over-the-rainbow.com');

        my $generator = sub {
            if (!@records) {
                @records = $client->get(
                    path => '/search/popular',
                    params => [
                        page => $page++,
                        page_size => 100,
                    ],
                );
            }
            return shift @records;
        };

        return iterator(generator => $generator);
    }

And then elsewhere you might write this:

    my $fetcher = fetcher();
    while (my $record = $fetcher->next) {
        ...
    }

=head1 CREATING AN ITERATOR

Iterators are set up either with a set of records, or with a generator. When a set of records
is provided, calling ->next on the iterator will simply walk through the set from beginning
to end, returning one value at a time. When a generator is provided, it will be called to
produce values. Generators signal they are finished by returning undef.

An iterator may encapsulate other iterators. The outer iterator may get its iterators either
as records, or by having a generator which produces iterators.

    my $inner = 5;
    my $limit = 10;

    my $container = iterator(
        generator => sub {
            if ($inner--) {
                return iterator(records => [1..$limit--]);
            }
        },
    );

    while (my $number = $container->next) {
        print $number . "\n";
    }

=head1 MUTATORS: CHANGE IT UP

Iterators may have a mutator as well. When a mutator is provided, calling C<-E<gt>next> on the iterator
will first select the next value (either by selecting the next item from a given list of records,
or by asking the generator to produce one) and will then pass the value into the mutator. The caller
of C<-E<gt>next> gets the mutator's return value.

You can combine these qualities to slightly interesting effect:

    use Functional::Iterator;

    my $numbers = iterator(
        records => [1..10],
        mutator => sub { shift() + 100 },
    );

    my $letter = 'a';
    my $letters = iterator(
        generator => sub {
            my $ret = $letter++;
            $ret = undef if $ret eq 'z';
            return $ret;
        }
    );

    my $numbers_and_letters = iterator(
        records => [$numbers, $letters],
    );

    while (my $rec = $numbers_and_letters->next) {
        print "$rec\n";
    }

=head1 EXPORTS

=over 4

=item * iterator (records => \@records)

=item * iterator (records => \@records, mutator => \&mutator)

=item * iterator (generator => \&generator)

=item * iterator (generator => \&generator, mutator => \&mutator)

Helper function for creating iterator objects. If both a generator and records are provided,
only the generator is considered.

=back

=head1 METHODS

=over 4

=item * ->next()

Return the next value in this iterator.

=item * ->reset()

Rewind this iterator, and any sub-iterators, back to the beginning of their records. ->reset is
meaningless to iterators built around generators.

=item * ->new()

If you really want to create your iterators like this, you certainly may:

    # see C<iterator()> for the full set of arguments you may pass to ->new
    my $iterator = Functional::Iterator->new(records => \@records);

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to this project's Github page:
L<http://github.com/belden/perl-functional-iterator/issues>.

=head1 PROJECT HOME

This project is housed on Github, at L<http://github.com/belden/perl-functional-iterator>. You may
submit pull requests via Github.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 Belden Lyman E<lt>belden@cpan.orgE<gt>

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.

=cut
