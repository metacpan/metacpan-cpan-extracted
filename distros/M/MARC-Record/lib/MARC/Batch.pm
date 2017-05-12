package MARC::Batch;

=head1 NAME

MARC::Batch - Perl module for handling files of MARC::Record objects

=head1 SYNOPSIS

MARC::Batch hides all the file handling of files of C<MARC::Record>s.
C<MARC::Record> still does the file I/O, but C<MARC::Batch> handles the
multiple-file aspects.

    use MARC::Batch;

    # If you have weird control fields...
    use MARC::Field;
    MARC::Field->allow_controlfield_tags('FMT', 'LDX');    
    

    my $batch = MARC::Batch->new( 'USMARC', @files );
    while ( my $marc = $batch->next ) {
        print $marc->subfield(245,"a"), "\n";
    }

=head1 EXPORT

None.  Everything is a class method.

=cut

use strict;
use integer;
use Carp qw( croak );

=head1 METHODS

=head2 new( $type, @files )

Create a C<MARC::Batch> object that will process C<@files>.

C<$type> must be either "USMARC" or "MicroLIF".  If you want to specify
"MARC::File::USMARC" or "MARC::File::MicroLIF", that's OK, too. C<new()> returns a
new MARC::Batch object.

C<@files> can be a list of filenames:

    my $batch = MARC::Batch->new( 'USMARC', 'file1.marc', 'file2.marc' );

Your C<@files> may also contain filehandles. So if you've got a large
file that's gzipped you can open a pipe to F<gzip> and pass it in:

    my $fh = IO::File->new( 'gunzip -c marc.dat.gz |' );
    my $batch = MARC::Batch->new( 'USMARC', $fh );

And you can mix and match if you really want to:

    my $batch = MARC::Batch->new( 'USMARC', $fh, 'file1.marc' );

=cut

sub new {
    my $class = shift;
    my $type = shift;

    my $marcclass = ($type =~ /^MARC::File/) ? $type : "MARC::File::$type";

    eval "require $marcclass";
    croak $@ if $@;

    my @files = @_;

    my $self = {
        filestack   =>  \@files,
        filename    =>  undef,
        marcclass   =>  $marcclass,
        file        =>  undef,
        warnings    =>  [],
        'warn'      =>  1,
        strict      =>  1,
    };

    bless $self, $class;

    return $self;
} # new()


=head2 next()

Read the next record from that batch, and return it as a MARC::Record
object.  If the current file is at EOF, close it and open the next
one. C<next()> will return C<undef> when there is no more data to be
read from any batch files.

By default, C<next()> also will return C<undef> if an error is
encountered while reading from the batch. If not checked for this can
cause your iteration to terminate prematurely. To alter this behavior,
see C<strict_off()>. You can retrieve warning messages using the
C<warnings()> method.

Optionally you can pass in a filter function as a subroutine reference
if you are only interested in particular fields from the record. This
can boost performance.

=cut

sub next {
    my ( $self, $filter ) = @_;
    if ( $filter and ref($filter) ne 'CODE' ) {
        croak( "filter function in next() must be a subroutine reference" );
    }

    if ( $self->{file} ) {

        # get the next record
        my $rec = $self->{file}->next( $filter );

        # collect warnings from MARC::File::* object
        # we use the warnings() method here since MARC::Batch
        # hides access to MARC::File objects, and we don't
        # need to preserve the warnings buffer.
        my @warnings = $self->{file}->warnings();
        if ( @warnings ) {
            $self->warnings( @warnings );
            return if $self->{ strict };
        }

        if ($rec) {

            # collect warnings from the MARC::Record object
            # IMPORTANT: here we don't use warnings() but dig
            # into the the object to get at the warnings without
            # erasing the buffer. This is so a user can call 
            # warnings() on the MARC::Record object and get back
            # warnings for that specific record.
            my @warnings = @{ $rec->{_warnings} };

            if (@warnings) {
                $self->warnings( @warnings );
                return if $self->{ strict };
            }

            # return the MARC::Record object
            return($rec);

        }

    }

    # Get the next file off the stack, if there is one
    $self->{filename} = shift @{$self->{filestack}} or return;

    # Instantiate a filename for it
    my $marcclass = $self->{marcclass};
    $self->{file} = $marcclass->in( $self->{filename} ) or return;

    # call this method again now that we've got a file open
    return( $self->next( $filter ) );

}

=head2 strict_off()

If you would like C<MARC::Batch> to continue after it has encountered what
it believes to be bad MARC data then use this method to turn strict B<OFF>.
A call to C<strict_off()> always returns true (1).

C<strict_off()> can be handy when you don't care about the quality of your
MARC data, and just want to plow through it. For safety, C<MARC::Batch>
strict is B<ON> by default.

=cut

sub strict_off {
    my $self = shift;
    $self->{ strict } = 0;
    return(1);
}

=head2 strict_on()

The opposite of C<strict_off()>, and the default state. You shouldn't
have to use this method unless you've previously used C<strict_off()>, and
want it back on again.  When strict is B<ON> calls to next() will return
undef when an error is encountered while reading MARC data. strict_on()
always returns true (1).

=cut

sub strict_on {
    my $self = shift;
    $self->{ strict } = 1;
    return(1);
}

=head2 warnings()

Returns a list of warnings that have accumulated while processing a particular
batch file. As a side effect the warning buffer will be cleared.

    my @warnings = $batch->warnings();

This method is also used internally to set warnings, so you probably don't
want to be passing in anything as this will set warnings on your batch object.

C<warnings()> will return the empty list when there are no warnings.

=cut

sub warnings {
    my ($self,@new) = @_;
    if ( @new ) {
        push( @{ $self->{warnings} }, @new );
        print STDERR join( "\n", @new ) . "\n" if $self->{'warn'};
    } else {
        my @old = @{ $self->{warnings} };
        $self->{warnings} = [];
        return(@old);
    }
}


=head2 warnings_off()

Turns off the default behavior of printing warnings to STDERR. However, even
with warnings off the messages can still be retrieved using the warnings()
method if you wish to check for them.

C<warnings_off()> always returns true (1).

=cut

sub warnings_off {
    my $self = shift;
    $self->{ 'warn' } = 0;

    return 1;
}

=head2 warnings_on()

Turns on warnings so that diagnostic information is printed to STDERR. This
is on by default so you shouldn't have to use it unless you've previously
turned off warnings using warnings_off().

warnings_on() always returns true (1).

=cut

sub warnings_on {
    my $self = shift;
    $self->{ 'warn' } = 1;
}

=head2 filename()

Returns the currently open filename or C<undef> if there is not currently a file
open on this batch object.

=cut

sub filename {
    my $self = shift;

    return $self->{filename};
}


1;

__END__

=head1 RELATED MODULES

L<MARC::Record>, L<MARC::Lint>

=head1 TODO

None yet.  Send me your ideas and needs.

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=cut
