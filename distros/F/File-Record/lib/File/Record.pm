package File::Record;

use 5.010;
use strict;
use warnings;
use Carp;

=head1 NAME

File::Record - Read file by record!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use File::Record;

    my $reader = File::Record->new(
        mode => 'start',
        filehandle => $fh,
        pattern => qr/^\S/
    );

    or
    
    my $reader = File::Record->new();
    $reader->mode('start');
    $reader->filehandle('$fh');
    $reader->pattern(qr/^\S/);
    
    while (my $record = $reader->next_record()){
        ...
    }

=head1 DESCRIPTION

Usually the file we are working on contains many records, which consist of
several line, and we want to read the file record by record instead of line by
line. For record with explicit terminator, we can easily do that by set the
input record separator (C<$/>) to that terminator. But for record with no
explicit terminator, we can only do that by testing the next line.

This module allows you to define the record and read the file record by record.

=head1 METHODS

=head2 new
    
The constructor takes key/value pairs to set the behavior of file reader to be
created.

    #Defalt simulate the diamond operator <>.
    my $reader = File::Record->new();
    while ($reader->next_record){
        ...
    }
    
    equal to

    while (<>){
        ...
    }
    
    #Specify the pattern to identify the marker line 
    my $reader = File::Record->new(pattern => "^\t");

To identify the marker line of a record, a regular expression is needed.
By default, the C<$/> is used to simulate the diamond operator E<lt>E<gt>.
    
=cut

sub new {
    ref ( my $class = shift ) and croak "class name needed!";
    croak "Odd number of arguments\n" if (@_ % 2);
    my %arg = @_;
    my $self;
    my @options = qw(mode filehandle pattern);
    foreach my $key ( keys %arg ){
        croak "Unknown option $key" unless grep { $_ eq $key } @options;
        $self->{$key} = $arg{$key};
    }
    $self->{mode} or $self->{mode} = $class->default_mode;
    $self->{filehandle} or $self->{filehandle} = $class->default_filehandle;
    $self->{pattern} or $self->{pattern} = $class->default_pattern;
    bless $self, $class;
}

=head2 next_record

    my $record = $reader->next_record();

Return one C<$record> based on current C<$reader>.

=cut

sub next_record {
    ref ( my $self = shift ) or croak "instance variable needed";
    my $fh = $self->filehandle;
    #    return undef if eof($fh);
    my $record;
    my $pattern = $self->pattern;
    my $mode = $self->mode;
    if ($mode eq "end"){
        while (<$fh>){
            $record .= $_;
            return $record if /$pattern/;
        }
    } elsif ( $mode eq "start" ){
        my $previous_line_offset;
        while (<$fh>){
            my $current_line_offset = tell $fh;
            if ( /$pattern/ ){
                if ( $record ){
                    seek $fh, $previous_line_offset, 0;
                    return $record;
                } else {
                    $record .= $_;
                }
            } else {
                $record .= $_;
                if ( eof($fh) ){
                    return $record;
                } else {
                    $previous_line_offset = $current_line_offset;
                }
            }
        }
    }
}

=head2 mode

=cut

sub mode {
    ref( my $self = shift ) or croak "instance variable is needed";
    @_ ? $self->{mode} = shift : $self->{mode};
}

=head2 default_mode

=cut

sub default_mode {
    "end"
}

=head2 pattern

    my $pattern = $reader->pattern;
    $reader->pattern("^\t");

Getter/setter for pattern.

=cut

sub pattern {
    ref( my $self = shift ) or croak "instance variable is needed";
    if ( @_ ){
        my $pattern = shift;
        $pattern = qr/\Q$pattern\E/ unless ref $pattern eq 'Regexp';
        $self->{pattern} = $pattern;
    } else {
        $self->{pattern}
    }
}

=head2 default_pattern

=cut

sub default_pattern {
    qr/\n$/;
}

=head2 filehandle

    my $fh = $reader->filehandle;
    $reader->filehandle($fh);

Getter/setter for filehandle.

=cut

sub filehandle {
    ref( my $self = shift ) or croak "instance variable needed";
    @_ ? $self->{filehandle} = shift : $self->{filehandle};
}

=head2 default_filehandle

=cut

sub default_filehandle {
    \*ARGV
}

=head1 AUTHOR

freedog, C<< <freedog at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-record at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Record>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Record


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Record>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Record>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/File-Record>

=item * Search CPAN

L<https://metacpan.org/release/File-Record>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 freedog.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of File::Record
