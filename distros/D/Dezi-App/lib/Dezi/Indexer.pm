package Dezi::Indexer;
use Moose;
use MooseX::StrictConstructor;
with 'Dezi::Role';
use Types::Standard qw( Str Int Bool Maybe InstanceOf );
use Dezi::Types qw( DeziInvIndex DeziIndexerConfig );
use Scalar::Util qw( blessed );
use Carp;
use Data::Dump qw( dump );
use Dezi::Indexer::Config;
use Dezi::InvIndex;
use SWISH::3 qw( :constants );
use Try::Tiny;

use namespace::autoclean;

our $VERSION = '0.015';

has 'invindex' => (
    is     => 'rw',
    isa    => DeziInvIndex,
    coerce => 1,
);
has 'invindex_class' => (
    is      => 'rw',
    isa     => Str,
    default => sub {'Dezi::InvIndex'},
);
has 'config' => (
    is      => 'rw',
    isa     => DeziIndexerConfig,
    coerce  => 1,
    lazy    => 1,
    default => sub { Dezi::Indexer::Config->new() },
);
has 'count'   => ( is => 'rw', isa => Int );
has 'clobber' => ( is => 'rw', isa => Bool, default => 0 );
has 'flush'   => ( is => 'rw', isa => Int );
has 'started' => ( is => 'ro', isa => Int );
has 'swish3' => (
    is      => 'rw',
    isa     => Maybe [ InstanceOf ['SWISH::3'] ],
    builder => 'init_swish3',
);
has 'test_mode'            => ( is => 'rw', isa => Bool, default => sub {0} );
has 'use_swish3_tokenizer' => ( is => 'rw', isa => Bool, default => sub {0} );

=pod

=head1 NAME

Dezi::Indexer - base indexer class

=head1 SYNOPSIS

 use Dezi::Indexer;
 my $indexer = Dezi::Indexer->new(
        invindex    => Dezi::InvIndex->new,
        config      => Dezi::Indexer::Config->new,
        count       => 0,
        clobber     => 1,
        flush       => 10000,
        started     => time()
 );
 $indexer->start;
 for my $doc (@list_of_docs) {
    $indexer->process($doc);
 }
 $indexer->finish;

=head1 DESCRIPTION

Dezi::Indexer is a base class implementing the simplest of indexing
APIs. It is intended to be subclassed, along with InvIndex, for each
IR backend library.

=head1 METHODS

=head2 new( I<params> )

Constructor. See the SYNOPSIS for default options.

I<params> may include the following keys, each of which is also an
accessor method:

=over

=item clobber

Over-write any existing InvIndex.

=item config

A Dezi::Indexer::Config object or file name.

=item flush

The number of indexed docs at which in-memory changes
should be written to disk.

=item invindex

A Dezi::InvIndex object.

=item test_mode

Dry run mode, just prints info on stderr but does not
build index.

=back

=head2 BUILD

Setup object. Called internally by new().

=cut

sub BUILD {
    my $self = shift;

    # if our invindex path != config->IndexFile,
    # prefer config
    if (    $self->config->IndexFile
        and $self->config->IndexFile ne $self->invindex->path )
    {
        $self->warnings
            and warn sprintf(
            "Overriding invindex->path '%s' with IndexFile value from config '%s'\n",
            $self->invindex->path, $self->config->IndexFile );
        $self->invindex->path( $self->config->IndexFile );
    }

    # make sure our invindex class matches invindex_class
    if (   !$self->invindex
        or !blessed $self->invindex
        or !$self->invindex->isa( $self->invindex_class ) )
    {
        Class::Load::load_class( $self->invindex_class );
        if ( !$self->invindex ) {
            $self->invindex( $self->invindex_class->new );
        }
        else {
            $self->invindex(
                $self->invindex_class->new( path => $self->invindex . "" ) );
        }
    }

    # merge any manual config with swish3 header
    $self->_merge_swish3_header_with_config();

}

=head2 init_swish3

Returns a SWISH::3 object that uses B<swish3_handler>. This builder
method is called on Indexer construction if B<swish3> is uninitialized.

=cut

sub init_swish3 {
    my $self = shift;
    return SWISH::3->new(
        handler => sub {
            $self->swish3_handler(@_);
        }
    );
}

sub _merge_swish3_header_with_config {
    my $self = shift;

    # 1. any existing header file.
    my $swish_3_header = $self->invindex->header_file;
    if ( -r $swish_3_header ) {
        $self->swish3->config->add($swish_3_header);
    }

    # 2. merge config in this Indexer
    my $ver3_xml = $self->config->as_swish3_config();
    $self->swish3->config->add($ver3_xml);

    # 3. conditionally turn off tokenizer, preferring engine to do it.
    $self->swish3->analyzer->set_tokenize( $self->use_swish3_tokenizer );
}

=head2 start

Opens the invindex() object and sets the started() time to time().

Subclasses should always call SUPER::start() if they override
this method since it provides sanity checking on the InvIndex.

=cut

sub start {
    my $self = shift;
    my $invindex = $self->invindex or confess "No invindex object defined";
    if (   !blessed($invindex)
        or !$invindex->can('open') )
    {
        confess "Invalid invindex $invindex: "
            . "either not blessed object or does not implement 'open' method";
    }

    # sanity check. if this is an existing index
    # does our Format match what already exists?
    my $header = try { $invindex->get_header };
    if ($header) {
        my $format = $header->Index->{Format};
        if ( !$self->isa( 'Dezi::' . $format . '::Indexer' ) ) {
            confess "Fatal error: found existing invindex '$invindex' "
                . "with format $format.\n"
                . "You tried to open it with "
                . ref($self);
        }

    }
    $self->invindex->open;
    $self->{started} = time();
    if ( -d $self->invindex->path ) {

        # for backcompat use swish3 name
        $self->invindex->path->file('swish_last_start')->touch();
    }

    return $self->{started};
}

=head2 process( I<doc> )

I<doc> should be a Dezi::Indexer::Doc-derived object.

process() should implement whatever the particular IR library
API requires. The default action calls B<swish3_handler> on I<doc>.

=cut

sub process {
    my $self = shift;
    my $doc  = shift;
    unless ( $doc && blessed($doc) && $doc->isa('Dezi::Indexer::Doc') ) {
        croak "Dezi::Indexer::Doc object required";
    }

    $self->start unless $self->started;
    $self->swish3->parse_buffer("$doc");
    $self->{count}++;

    return $doc;
}

=head2 swish3_handler( I<swish3_payload> )

This method is called on every document passed to process(). See
the L<SWISH::3> documentation for what to expect in I<swish3_payload>.

This is an abstract method. Subclasses must implement it.

=cut

sub swish3_handler { confess "$_[0] must implement swish3_handler" }

=head2 finish

Closes the invindex().

=cut

sub finish {
    my $self = shift;
    $self->invindex->close;
}

=head2 count

Returns the number of documents processed.

=head2 started

The time at which the Indexer start() method was called. Returns a Unix epoch
integer.

=cut

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
