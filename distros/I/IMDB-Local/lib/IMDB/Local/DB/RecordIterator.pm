package IMDB::Local::DB::RecordIterator;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

IMDB::Local::DB::RecordIterator - Object to iterate through search results

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use IMDB::Local::DB::RecordIterator;

    my $foo = IMDB::Local::DB::RecordIterator->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new($$)
{
    my ($class, $sth)=@_;

    if ( !defined($sth) ) {
	carp("sth is not defined");
	return(undef);
    }

    my $self={sth=>$sth};

    $self->{cacheBy}=1000;
    $self->{cacheSize}=0;
    bless($self, $class);
    $self->{rowIntoCache}=0;
    $self->{rowCounter}=0;
    return($self);
}

sub _cacheRows($)
{
    my $self=shift;

    delete($self->{cache});
    $self->{cacheSize}=0;
	    
    my $all=$self->{sth}->fetchall_arrayref(undef, $self->{cacheBy});
    my @list;
    for my $refer (@$all) {
	my @ref=@$refer;
	if ( @ref ) {
	    push(@list, \@ref);
	}
    }
    if ( @list ) {
	$self->{cache}=\@list;
	$self->{cacheSize}=scalar(@list);
	#print "cached ".$self->{cacheSize}."\n";
	return($self->{cache});
    }
    return(0);
}

=head2 nextRow

=cut

sub nextRow($)
{
    my $self=shift;

    if ( !$self->{cache} || $self->{rowIntoCache}+1 >= $self->{cacheSize} ) {
	if ( !$self->_cacheRows() ) {
	    # no more rows
	    return(undef);
	}
	$self->{rowIntoCache}=0;
    }
    else {
	$self->{rowIntoCache}++;
    }
    my @arr=@{$self->{cache}};
    #print "returning ".$self->{rowIntoCache}." row\n";
    my $refer=$arr[$self->{rowIntoCache}];
    return(\@$refer);
}

=head2 rowNumber

=cut

sub rowNumber($)
{
    my $self=shift;
    return($self->{rowCounter});
}


=head1 AUTHOR

jerryv, C<< <jerry.veldhuis at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imdb-local at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMDB-Local>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IMDB::Local::DB::RecordIterator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMDB-Local>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IMDB-Local>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IMDB-Local>

=item * Search CPAN

L<http://search.cpan.org/dist/IMDB-Local/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 jerryv.

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

1; # End of IMDB::Local::DB::RecordIterator
