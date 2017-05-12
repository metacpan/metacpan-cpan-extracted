package IMDB::Local::QualifierType;

use 5.006;
use strict;
use warnings;

=head1 NAME

IMDB::Local::QualifierType - The great new IMDB::Local::QualifierType!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

use IMDB::Local::DB::BaseObject;
use base qw(IMDB::Local::DB::BaseObject);

use constant DB_TABLE => 'QualifierTypes';
use constant DB_KEY   => 'QualifierTypeID';

use Class::MethodMaker
    [ 
      scalar => [DB_KEY],
      array => [qw/ -static db_columns/],
      new  => [qw/ -init -hash new/] ,
    ];

sub init($)
{
    my ($self)=@_;

    # static array needs to be initialized only if it isn't already
    #if ( !$self->db_ignoredColumns_count ) {
    #$self->db_ignoredColumns_push(DB_COLUMNS_IGNORE);
    #}

    $self->initHandle(DB_TABLE, DB_KEY);

    if ( $self->populateUsingKey($self->get(DB_KEY)) ) {
	return $self;
    }
    return(undef);
}

use constant TV_MOVIE       => 1;
use constant TV_MINI_SERIES => 2;
use constant TV_SERIES      => 3;
use constant VIDEO_MOVIE    => 4;
use constant VIDEO_GAME     => 5;
use constant MOVIE          => 6;

use constant EPISODE_OF_TV_MINI_SERIES => 12;
use constant EPISODE_OF_TV_SERIES      => 13;

#our @EXPORT_OK = ('TV_MOVIE', 'TV_MINI_SERIES', 'TV_SERIES', 'VIDEO_MOVIE', 'VIDEO_GAME', 'MOVIE', 
#		  'EPISODE_OF_TV_MINI_SERIES', 'EPISODE_OF_TV_SERIES');

our %EXPORT_TAGS = ( types=> [ 'TV_MOVIE', 'TV_MINI_SERIES', 'TV_SERIES', 'VIDEO_MOVIE', 'VIDEO_GAME', 'MOVIE', 
			       'EPISODE_OF_TV_MINI_SERIES', 'EPISODE_OF_TV_SERIES'] );

use Carp;

sub createNew($%)
{
    my ($imdbdb, %args)=@_;

    carp("no name given") if ( !defined($args{name}) );

    my $id=$imdbdb->insert_db(DB_TABLE, DB_KEY, %args);
    if ( !defined($id) ) {
	return(undef);
    }
    return new IMDB::Local::QualifierType(imdbdb=>$imdbdb, TableID=>$id);
}

sub findByQualifierTypeID($$)
{
    my ($imdbdb, $id)=@_;
    return new IMDB::Local::QualifierType(imdbdb=>$imdbdb, DB_KEY, $id);
}

sub findByName($$)
{
    my ($imdbdb, $name)=@_;

    my $id=$imdbdb->select2Scalar("SELECT ".DB_KEY." from ".DB_TABLE." where name='$name'");
    if ( defined($id) ) {
	return new IMDB::Local::QualifierType(imdbdb=>$imdbdb, DB_KEY, $id);
    }
    return(undef);
}

use IMDB::Local::QualifierType;

sub populateQualifierType($)
{
    my ($self)=@_;

    $self->QualifierType(new IMDB::Local::QualifierType(imdbdb=>$self->imdbdb, QualifierTypeID=>$self->QualifierTypeID));
    return $self->QualifierType;
}

sub getIDs($$)
{
    my ($class, $imdbdb)=@_;
    my @ids;

    my $res=$imdbdb->dbh->selectall_arrayref("SELECT ".DB_KEY." FROM ".DB_TABLE." ORDER BY ".DB_KEY."");
    if ( !defined($res) ) {
	return(@ids);
    }

    for my $list (@$res) {
	push(@ids, $list->[0]);
    }
    return(@ids);
}

=head1 AUTHOR

jerryv, C<< <jerry.veldhuis at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imdb-local at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMDB-Local>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IMDB::Local::QualifierType


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

1; # End of IMDB::Local::QualifierType
