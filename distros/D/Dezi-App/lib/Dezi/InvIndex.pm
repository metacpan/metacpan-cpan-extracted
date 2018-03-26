package Dezi::InvIndex;
use Moose;
use MooseX::StrictConstructor;
with 'Dezi::Role';
use Carp;
use Types::Standard qw( Bool Str InstanceOf );
use Dezi::InvIndex::Header;
use MooseX::Types::Path::Class;
use Class::Load ();
use Try::Tiny;
use overload(
    '""'     => sub { shift->path },
    'bool'   => sub {1},
    fallback => 1,
);

use namespace::autoclean;

our $VERSION = '0.015';

our $DEFAULT_NAME = 'dezi.index';

has 'version' => (
    is      => 'rw',
    isa     => Str,
    default => sub {$VERSION},
);

has 'path' => (
    is      => 'rw',
    isa     => 'Path::Class::Dir',
    coerce  => 1,
    default => sub { Path::Class::Dir->new($DEFAULT_NAME) }
);

has 'clobber' => ( is => 'rw', isa => Bool, default => 0 );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( path => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

sub new_from_header {
    my $self = shift;

    # open swish.xml meta file
    my $header = $self->get_header();

    # parse for index format
    my $format = $header->Index->{Format};

    # create new object and re-set $self
    my $newclass = "Dezi::${format}::InvIndex";

    #warn "reblessing $self into $newclass";

    Class::Load::load_class($newclass);

    return $newclass->new(
        path    => $self->{path},
        clobber => $self->{clobber},
    );
}

sub open {
    my $self = shift;

    if ( -d $self->path && $self->clobber ) {
        $self->path->rmtree( $self->verbose, 1 );
    }
    elsif ( -f $self->path ) {
        confess $self->path
            . " is not a directory -- won't even attempt to clobber";
    }

    if ( !-d $self->path ) {
        $self->warnings and Carp::cluck("no path $self->{path} -- mkpath");
        $self->path->mkpath( $self->verbose );
    }

    1;
}

sub open_ro {
    shift->open(@_);
}

sub close { 1; }

sub get_header {
    my $self = shift;
    return Dezi::InvIndex::Header->new( invindex => $self );
}

sub header_file {
    my $self = shift;
    return $self->path->file( Dezi::InvIndex::Header->header_file );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Dezi::InvIndex - base class for Dezi inverted indexes

=head1 SYNOPSIS

 use Dezi::InvIndex;
 my $index = Dezi::InvIndex->new(path => 'path/to/index');
 print $index;  # prints $index->path
 my $header = $index->get_header();  # $meta isa Dezi::InvIndex::Header object

=head1 DESCRIPTION

A Dezi::InvIndex is a base class for defining different inverted index formats.

=head1 METHODS

=head2 new

Constructor.

=head2 new_from_header

Instantiates an InvIndex object in the correct subclass
based on the Index Format in the InvIndex header file.

Example:

 my $invindex = Dezi::InvIndex->new('path/to/lucy.index');
 # $invindex isa Dezi::Lucy::InvIndex

=head2 path

Returns a Path::Class::Dir object representing the directory path to the index.
The path is a directory which contains the various files that comprise the
index.

=head2 get_header

Returns a Dezi::InvIndex::Header object with which you can query
information about the index.

=head2 header_file

Returns Path::Class::File object pointing at the header_file.

=head2 open

Open the invindex for reading/writing. Subclasses should implement this per
their IR library specifics.

This base open() method will rmtree( path() ) if clobber() is true,
and will mkpath() if path() does not exist. So SUPER::open() should
do something sane at minimum.

=head2 open_ro

Open the invindex in read-only mode. This is typical when searching
the invindex.

The default open_ro() method will simply call through to open().

=head2 close

Close the index. Subclasses should implement this per
their IR library specifics.

=head2 clobber

Get/set the Boolean indicating whether the index should overwrite
any existing index with the same name. The default is true.

=head2 new_from_meta

Returns a new instance like new() does, blessed into the appropriate
class indicated by the C<swish.xml> meta header file.

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::InvIndex

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>
