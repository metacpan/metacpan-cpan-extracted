package Directory::Scanner;
# ABSTRACT: Streaming directory scanner

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use Directory::Scanner::API::Stream;

use Directory::Scanner::Stream;

use Directory::Scanner::StreamBuilder::Concat;
use Directory::Scanner::StreamBuilder::Recursive;
use Directory::Scanner::StreamBuilder::Matching;
use Directory::Scanner::StreamBuilder::Ignoring;
use Directory::Scanner::StreamBuilder::Application;
use Directory::Scanner::StreamBuilder::Transformer;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

## static builder constructors

sub for {
    my (undef, $dir) = @_;
    return bless [ $dir ] => __PACKAGE__;
}

sub concat {
    my (undef, @streams) = @_;

    Carp::confess 'You provide at least two streams to concat'
        if scalar @streams < 2;

    return Directory::Scanner::StreamBuilder::Concat->new( streams => [ @streams ] );
}

## builder instance methods

sub recurse {
    my ($builder) = @_;
    push @$builder => [ 'Directory::Scanner::StreamBuilder::Recursive' ];
    return $builder;
}

sub ignore {
    my ($builder, $filter) = @_;
    # XXX - should this support using at .gitignore files?
    push @$builder => [ 'Directory::Scanner::StreamBuilder::Ignoring', filter => $filter ];
    return $builder;
}

sub match {
    my ($builder, $predicate) = @_;
    push @$builder => [ 'Directory::Scanner::StreamBuilder::Matching', predicate => $predicate ];
    return $builder;
}

sub apply {
    my ($builder, $function) = @_;
    push @$builder => [ 'Directory::Scanner::StreamBuilder::Application', function => $function ];
    return $builder;
}

sub transform {
    my ($builder, $transformer) = @_;
    push @$builder => [ 'Directory::Scanner::StreamBuilder::Transformer', transformer => $transformer ];
    return $builder;
}

## builder method

sub stream {
    my ($builder) = @_;

    if ( my $dir = shift @$builder ) {
        my $stream = Directory::Scanner::Stream->new( origin =>  $dir );

        foreach my $layer ( @$builder ) {
            my ($class, %args) = @$layer;
            $stream = $class->new( stream => $stream, %args );
        }

        return $stream;
    }
    else {
        Carp::confess 'Nothing to construct a stream on';
    }
}

1;

__END__

=pod

=head1 NAME

Directory::Scanner - Streaming directory scanner

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # get all entries in a directory

    Directory::Scanner->for( $dir )->stream;

    # get all entries in a directory recursively

    Directory::Scanner->for( $dir )
                      ->recurse
                      ->stream;

    # get all entries in a directory recusively
    # and filter out anything that is not a directory

    Directory::Scanner->for( $dir )
                      ->recurse
                      ->match(sub { $_->is_dir })
                      ->stream;

    # ignore anything that is a . directory, then recurse

    Directory::Scanner->for( $dir )
                      ->ignore(sub { $_->basename =~ /^\./ })
                      ->recurse
                      ->stream;

=head1 DESCRIPTION

This module provides a streaming interface for traversing
directories. Unlike most modules that provide similar
capabilities, this will not pre-fetch the list of files
or directories, but instead will only focus on one thing
at a time. This is useful if you have a large directory
tree and need to do a lot of resource intensive work on
each file.

=head2 Builders

This module uses the builder pattern to create the
L<Directory::Scanner> stream you need. If you look in
the L<SYNOPSIS> above you can see that the C<for> method
starts the creation of a builder. All the susequent
chained methods simply collect metadata, and not
until C<stream> is called is anything constructed.

=head2 Streams

If you look at the code in the L<SYNOPSIS> you will see
that most of the chained builder calls end with a call
to C<stream>. This method will use the builder information
and construct an instance which does the
C<Directory::Scanner::API::Stream> API role.

=head1 METHODS

=head2 C<for($dir)>

Begins the construction of a C<StreamBuilder> to eventually
create a stream for scanning the given C<$dir>.

=head2 C<concat(@streams)>

This concatenates multiple streams into a single stream, and
will return an instance that does the
C<Directory::Scanner::API::Stream> role.

=head2 C<stream>

This is meant as an end to a C<StreamBuilder> process. It will
use the collected builder metadata to create an appropriate
instance that does the C<Directory::Scanner::API::Stream> role.

=head1 BUILDERS

These are all methods of the C<StreamBuilder>, each will
set up the metadata needed for C<stream> to construct an
actual instance.

=head2 C<recurse>

By default a scanner will not try to recurse into subdirectories,
if that is what you want, you must call this builder method.

See L<Directory::Scanner::StreamBuilder::Recursive> for more info.

=head2 C<ignore($filter)>

Construct a stream that will ignore anything that is matched by
the C<$filter> CODE ref.

See L<Directory::Scanner::StreamBuilder::Ignoring> for more info.

=head2 C<match($predicate)>

Construct a stream that will keep anything that is matched by
the C<$predicate> CODE ref.

See L<Directory::Scanner::StreamBuilder::Matching> for more info.

=head2 C<apply($function)>

Construct a stream that will apply the C<$function> to each
element in the stream without modifying it.

See L<Directory::Scanner::StreamBuilder::Application> for more info.

=head2 C<transform($transformer)>

Construct a stream that will apply the C<$transformer> to each
element in the stream and modify it.

See L<Directory::Scanner::StreamBuilder::Transformer> for more info.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
