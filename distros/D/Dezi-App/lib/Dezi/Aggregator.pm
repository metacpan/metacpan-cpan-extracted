package Dezi::Aggregator;
use Moose;
with 'Dezi::Role';
use Carp;
use Types::Standard qw( Bool Str InstanceOf Int Object );
use Dezi::Types qw( DeziFileOrCodeRef DeziEpoch );
use Dezi::Utils;
use SWISH::Filter;
use Dezi::Indexer::Doc;
use Scalar::Util qw( blessed );
use Data::Dump qw( dump );

use namespace::autoclean;

our $VERSION = '0.015';

has 'set_parser_from_type' => ( is => 'rw', isa => Bool, default => sub {1} );
has 'indexer' => (
    is  => 'rw',
    isa => InstanceOf ['Dezi::Indexer'],
);
has 'doc_class' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => sub {'Dezi::Indexer::Doc'},
);
has 'swish_filter_obj' => (
    is      => 'rw',
    isa     => InstanceOf ['SWISH::Filter'],
    default => sub { SWISH::Filter->new }
);
has 'test_mode' => ( is => 'rw', isa => Bool, default => sub {0} );
has 'filter' => ( is => 'rw', isa => DeziFileOrCodeRef, coerce => 1, );
has 'ok_if_newer_than' => ( is => 'rw', isa => DeziEpoch );
has 'progress'         => ( is => 'rw', isa => Object );   # Term::ProgressBar
has 'count'            => ( is => 'ro', isa => Int );

=pod

=head1 NAME

Dezi::Aggregator - document aggregation base class

=head1 SYNOPSIS

 package MyAggregator;
 use Moose;
 extends 'Dezi::Aggregator';

 sub get_doc {
    my ($self, $url) = @_;

    # do something to create a Dezi::Indexer::Doc object from $url

    return $doc;
 }

 sub crawl {
    my ($self, @where) = @_;

    foreach my $place (@where) {

       # do something to search $place for docs to pass to get_doc()

    }
 }

 1;

=head1 DESCRIPTION

Dezi::Aggregator is a base class that defines the basic API for writing
an aggregator. Only two methods are required: get_doc() and crawl(). See
the SYNOPSIS for the prototypes.

See Dezi::Aggregator::FS and Dezi::Aggregator::Spider for examples
of aggregators that crawl the filesystem and web, respectively.

=head1 METHODS

=head2 BUILD

Set object flags per Dezi::Class API. These are also accessors,
and include:

=over

=item set_parser_from_type

This will set the parser() value in swish_filter() based on the
MIME type of the doc_class() object.

=item indexer

A Dezi::Indexer object.

=item doc_class

The name of the Dezi::Indexer::Doc-derived class to use in get_doc().
Default is Dezi::Indexer::Doc.

=item swish_filter_obj

A SWISH::Filter object. If not passed in new() one is created for you.

=item test_mode

Dry run mode, just prints info on stderr but does not
build index.

=item filter

Value should be a CODE ref. This is passed through to set_filter()
internally at BUILD() time. If you need to adjust the filter
after the Aggregator object is created, use set_filter().

=item ok_if_newer_than

Value should be a Unix timestamp (epoch seconds). Default is undef.
If set, aggregators should skip files that have a modification time
older than the timestamp.

You may get/set the ok_if_newer_than value with the ok_if_newer_than()
attribute method, but use set_ok_if_newer_than() to include validation
of the supplied I<timestamp> value.

=item progress( I<Term::ProgressBar object> )

Get/set a progress object. The default used in the examples/swish3
script is Term::ProgressBar. If set, it will be incremented
just like count() is.

=back

=cut

sub BUILD {
    my $self = shift;
    $self->{__progress_so_far} = 0;
    $self->{__progress_next}   = 0;
    if ( $self->filter ) {
        $self->set_filter( $self->filter );
    }
}

=head2 config

Returns the Dezi::Indexer::Config object from the Indexer
being used. This is a read-only method (accessor not mutator).

=cut

sub config {
    return shift->indexer->config;
}

=head2 count

Returns the total number of doc_class() objects returned by get_doc().

=cut

=head2 crawl( I<@where> )

Override this method in your subclass. It does the aggregation,
and passes each doc_class() object from get_doc() to indexer->process().

=cut

sub crawl {
    my $self = shift;
    confess ref($self) . " does not implement crawl()";
}

=head2 get_doc( I<url> )

Override this method in your subclass. Should return a doc_class()
object.

=cut

sub get_doc {
    my $self = shift;
    confess ref($self) . " does not implement get_doc()";
}

=head2 swish_filter( I<doc_class_object> )

Passes the content() of the I<doc_class_object> through SWISH::Filter
and transforms it to something index-able. Returns
the I<doc_class_object>, filtered.

B<NOTE:> This method should be called by all aggregators after
get_doc() and before passing to the indexer().

See the SWISH::Filter documentation.

=cut

sub swish_filter {
    my $self = shift;
    my $doc  = shift;
    unless ( $doc && blessed($doc) && $doc->isa('Dezi::Indexer::Doc') ) {
        croak "Dezi::Indexer::Doc-derived object required";
    }

    if ( $self->debug ) {
        warn "checking filter for " . $doc->url;
    }

    unless ( defined $doc->parser ) {
        if ( $self->set_parser_from_type ) {
            my $type = $doc->type || 'default';
            $doc->parser(
                Dezi::Utils->get_parser_for_mime(
                    $type,
                    ( $self->indexer ? $self->indexer->swish3 : undef ),
                )
            );
        }
    }

    my $sfo = $self->swish_filter_obj;

    if ( $sfo->can_filter( $doc->type ) ) {

        if ( $self->debug ) {
            warn sprintf
                "debug=%d can_filter true for %s with parser %s for type %s",
                $self->debug, $doc->url,
                $doc->parser, $doc->type;
        }

        my $content = $doc->content;
        my $url     = $doc->url;
        my $type    = $doc->type;
        my $f       = $sfo->convert(
            document     => \$content,
            content_type => $type,
            name         => $url
        );

        if (   !$f
            || !$f->was_filtered
            || $f->is_binary )    # is is_binary necessary?
        {
            warn "skipping $url - filtering error\n";
            return;
        }

        if ( $self->debug > 1 ) {
            warn "$url [$type] was filtered\n";
            if ( $doc->content ne ${ $f->fetch_doc } ) {
                warn sprintf "content changed:'%s'\n", ${ $f->fetch_doc };
            }
        }

        $doc->content( ${ $f->fetch_doc } );

        # leave type and parser as-is
        # since we want to store original mime in indexer.
        # TODO test this.
        # what about parser?
        # since type will have changed ( $f->content_type ) from original
        # the parser type might also have changed?

        $doc->parser( $f->swish_parser_type ) if $self->set_parser_from_type;

    }
    else {

        if ( $self->debug ) {
            warn sprintf(
                "No filter applied to %s - cannot filter %s (parser %s)\n",
                $doc->url, $doc->type, $doc->parser, );
            warn sprintf( " available filter: %s\n", $_ )
                for $sfo->filter_list;
        }

    }

}

=head2 set_filter( I<code_ref> )

Use I<code_ref> as the C<doc_class> filter. This method called by BUILD() if
C<filter> param set in constructor.

=cut

sub set_filter {
    my $self   = shift;
    my $filter = shift;
    unless ( ref($filter) eq 'CODE' ) {
        croak "filter must be a CODE ref";
    }

    # cheat a little by using this code instead of the default
    # method in doc_class
    {
        no strict 'refs';
        no warnings 'redefine';

        #warn "setting filter as method: " . $self->{doc_class} . '::filter';
        *{ $self->{doc_class} . '::filter' } = $filter;
    }

}

=head2 set_ok_if_newer_than( I<timestamp> )

Set the ok_if_newer_than attribute. I<timestamp> should be a Unix
epoch value.

=cut

sub set_ok_if_newer_than {
    my $self = shift;
    my $ts = shift || 0;
    if ( $ts =~ m/\D/ ) {
        croak "timestamp should be an integer";
    }
    $self->ok_if_newer_than($ts);
}

#
# private methods
#

sub _increment_count {
    my $self = shift;
    my $count = shift || 1;
    $self->{count} += $count;
    if ( $self->{progress} ) {
        $self->{__progress_so_far} += $count;
        if ( $self->{__progress_so_far} >= $self->{__progress_next} ) {
            $self->{__progress_next}
                = $self->{progress}->update( $self->{__progress_so_far} );
        }
    }
    return $self;
}

sub _apply_file_rules {
    my ( $self, $file, $file_rules ) = @_;
    if (   !$file_rules
        && !exists $self->{_file_rules}
        && $self->config->FileRules )
    {

        # cache obj
        $self->{_file_rules} = File::Rules->new( $self->config->FileRules );
    }
    if ( $file_rules or exists $self->{_file_rules} ) {
        $self->debug and warn "$file [applying DeziFileRules]\n";
        my $rules = $file_rules || $self->{_file_rules};
        my $match = $rules->match($file);
        return $match;
    }
    return 0;    # no rules
}

sub _apply_file_match {
    my ( $self, $file ) = @_;

    # TODO
    return 0;    # no-op for now
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://swish-e.org/>
