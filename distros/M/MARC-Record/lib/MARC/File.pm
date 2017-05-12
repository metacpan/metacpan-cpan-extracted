package MARC::File;

=head1 NAME

MARC::File - Base class for files of MARC records

=cut

use strict;
use warnings;
use integer;

use vars qw( $ERROR );

=head1 SYNOPSIS

    use MARC::File::USMARC;

    # If you have weird control fields...
    use MARC::Field;
    MARC::Field->allow_controlfield_tags('FMT', 'LDX');    

    my $file = MARC::File::USMARC->in( $filename );

    while ( my $marc = $file->next() ) {
        # Do something
    }
    $file->close();
    undef $file;

=head1 EXPORT

None.

=head1 METHODS

=head2 in()

Opens a file for import. Ordinarily you will use C<MARC::File::USMARC>
or C<MARC::File::MicroLIF> to do this.

    my $file = MARC::File::USMARC->in( 'file.marc' );

Returns a C<MARC::File> object, or C<undef> on failure. If you
encountered an error the error message will be stored in
C<$MARC::File::ERROR>.

Optionally you can also pass in a filehandle, and C<MARC::File>.
will "do the right thing".

    my $handle = IO::File->new( 'gunzip -c file.marc.gz |' );
    my $file = MARC::File::USMARC->in( $handle );

=cut

sub in {
    my $class = shift;
    my $arg = shift;
    my ( $filename, $fh );

    ## if a valid filehandle was passed in
    my $ishandle = do { no strict; defined fileno($arg); };
    if ( $ishandle ) {
        $filename = scalar( $arg );
        $fh = $arg;
    }

    ## otherwise check if it's a filename, and
    ## return undef if we weren't able to open it
    else {
        $filename = $arg;
        $fh = eval { local *FH; open( FH, '<', $arg ) or die; *FH{IO}; };
        if ( $@ ) {
            $MARC::File::ERROR = "Couldn't open $filename: $@";
            return;
        }
    }

    my $self = {
        filename    => $filename,
        fh          => $fh,
        recnum      => 0,
        warnings    => [],
    };

    return( bless $self, $class );

} # new()

sub out {
    die "Not yet written";
}

=head2 next( [\&filter_func] )

Reads the next record from the file handle passed in.

The C<$filter_func> is a reference to a filtering function.  Currently,
only USMARC records support this.  See L<MARC::File::USMARC>'s C<decode()>
function for details.

Returns a MARC::Record reference, or C<undef> on error.

=cut

sub next {
    my $self = shift;
    $self->{recnum}++;
    my $rec = $self->_next() or return;
    return $self->decode($rec, @_);
}

=head2 skip()

Skips over the next record in the file.  Same as C<next()>,
without the overhead of parsing a record you're going to throw away
anyway.

Returns 1 or undef.

=cut

sub skip {
    my $self = shift;
    my $rec = $self->_next() or return;
    return 1;
}

=head2 warnings()

Simlilar to the methods in L<MARC::Record> and L<MARC::Batch>,
C<warnings()> will return any warnings that have accumulated while
processing this file; and as a side-effect will clear the warnings buffer.

=cut

sub warnings {
    my $self = shift;
    my @warnings = @{ $self->{warnings} };
    $self->{warnings} = [];
    return(@warnings);
}

=head2 close()

Closes the file, both from the object's point of view, and the actual file.

=cut

sub close {
    my $self = shift;
    close( $self->{fh} );
    delete $self->{fh};
    delete $self->{filename};
    return;
}

sub _unimplemented {
    my $self = shift;
    my $method = shift;
    warn "Method $method must be overridden";
}

=head2 write()

Writes a record to the output file.  This method must be overridden
in your subclass.

=head2 decode()

Decodes a record into a USMARC format.  This method must be overridden
in your subclass.

=cut

sub write   { $_[0]->_unimplemented("write"); }
sub decode  { $_[0]->_unimplemented("decode"); }

# NOTE: _warn must be called as an object method

sub _warn {
    my ($self,$warning) = @_;
    push( @{ $self->{warnings} }, "$warning in record ".$self->{recnum} );
    return( $self );
}

# NOTE: _gripe can be called as an object method, or not.  Your choice.
# NOTE: it's use is now deprecated use _warn instead
sub _gripe {
    my @parms = @_;
    if ( @parms ) {
        my $self = shift @parms;

        if ( ref($self) =~ /^MARC::File/ ) {
            push( @parms, " at byte ", tell($self->{fh}) )
                if $self->{fh};
            push( @parms, " in file ", $self->{filename} ) if $self->{filename};
        } else {
            unshift( @parms, $self );
        }

        $ERROR = join( "", @parms );
        warn $ERROR;
    }

    return;
}

1;

__END__

=head1 RELATED MODULES

L<MARC::Record>

=head1 TODO

=over 4

=item * C<out()> method

We only handle files for input right now.

=back

=cut

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=cut

