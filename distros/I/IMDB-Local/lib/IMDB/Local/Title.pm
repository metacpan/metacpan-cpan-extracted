package IMDB::Local::Title;

use 5.006;
use strict;
use warnings;

=head1 NAME

IMDB::Local::Title - Object representation of Title information.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use IMDB::Local::Title;

    my $foo = IMDB::Local::Title->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

use IMDB::Local::DB::BaseObject;
use base qw(IMDB::Local::DB::BaseObject);

use constant DB_TABLE => 'Titles';
use constant DB_KEY   => 'TitleID';

use Class::MethodMaker
    [ 
      scalar => [DB_KEY],
      array => [qw/ -static db_columns/],
      scalar => ['QualifierType'],
      array => ['Directors'],
      array => ['Actors'],
      array => ['Hosts'],
      array => ['Narrators'],
      array => ['Genres'],
      array => ['Keywords'],
      array => ['Plots'],
      scalar => ['Rating'],
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

use Carp;

sub createNew($%)
{
    my ($imdbdb, %args)=@_;

    carp("no name given") if ( !defined($args{name}) );

    my $id=$imdbdb->insert_db(DB_TABLE, DB_KEY, %args);
    if ( !defined($id) ) {
	return(undef);
    }
    return new IMDB::Local::Title(imdbdb=>$imdbdb, TableID=>$id);
}

sub findByTitleID($$)
{
    my ($imdbdb, $id)=@_;
    return new IMDB::Local::Title(imdbdb=>$imdbdb, DB_KEY, $id);
}

sub findByName($$)
{
    my ($imdbdb, $name)=@_;

    my $id=$imdbdb->select2Scalar("SELECT ".DB_KEY." from ".DB_TABLE." where name='$name'");
    if ( defined($id) ) {
	return new IMDB::Local::Title(imdbdb=>$imdbdb, DB_KEY, $id);
    }
    return(undef);
}

sub findBySearchableTitle($$$)
{
    my ($imdbdb, $name, $qualifierTypeID)=@_;

    #warn "SELECT ".DB_KEY." from ".DB_TABLE." where SearchTitle='$name'";
    my $sql="SELECT ".DB_KEY." from ".DB_TABLE." where SearchTitle='$name'";
    if ( $qualifierTypeID ) {
	$sql.=" AND QualifierTypeID=$qualifierTypeID";
    }
    my @id=@{$imdbdb->select2Array($sql)};
    if ( @id && !defined($id[0]) ) {
	return(undef);
    }
    #warn("found: ".scalar(@id)."\n");
    return(@id);
}

use IMDB::Local::QualifierType;

sub hasParentTitle($)
{
    my ($self)=@_;
    return($self->ParentID != 0 );
}

sub getParentTitle($)
{
    my ($self)=@_;

    if ( $self->hasParentTitle ) {
	return new IMDB::Local::Title(imdbdb=>$self->imdbdb, TitleID=>$self->ParentID);
    }
    return(undef);
}

sub populateQualifierType($)
{
    my ($self)=@_;

    $self->QualifierType(new IMDB::Local::QualifierType(imdbdb=>$self->imdbdb, QualifierTypeID=>$self->QualifierTypeID));
    return $self->QualifierType;
}

use IMDB::Local::Plot;

sub populatePlots($)
{
    my ($self)=@_;

    for my $id (@{$self->imdbdb->select2Array("SELECT PlotID from Plots where TitleID=".$self->TitleID." order by Sequence")}) {
	my $r=new IMDB::Local::Plot(imdbdb=>$self->imdbdb, PlotID=>$id);
	if ( $r ) {
	    $self->Plots_push($r)
	}
    }
}

use IMDB::Local::Rating;

sub populateRating($)
{
    my ($self)=@_;

    if ( $self->imdbdb->rowExists('Ratings', 'TitleID', $self->TitleID) ) {
	$self->Rating(new IMDB::Local::Rating(imdbdb=>$self->imdbdb, TitleID=>$self->TitleID));
    }
    return $self->Rating;

}

use IMDB::Local::Director;

sub populateDirectors($)
{
    my ($self)=@_;
    
    for my $id (@{$self->imdbdb->select2Array("SELECT DirectorID from Titles2Directors where TitleID=".$self->TitleID)}) {
	my $dir=new IMDB::Local::Director(imdbdb=>$self->imdbdb, DirectorID=>$id);
	if ( $dir ) {
	    $self->Directors_push($dir)
	}
    }
}

use IMDB::Local::Actor;

sub populateActors($)
{
    my ($self)=@_;
    
    for my $id (@{$self->imdbdb->select2Array("SELECT ActorID from Titles2Actors where TitleID=".$self->TitleID." order by Billing")}) {
	my $r=new IMDB::Local::Actor(imdbdb=>$self->imdbdb, ActorID=>$id);
	if ( $r ) {
	    $self->Actors_push($r)
	}
    }
}

sub populateHosts($)
{
    my ($self)=@_;
    
    for my $id (@{$self->imdbdb->select2Array("SELECT ActorID from Titles2Hosts where TitleID=".$self->TitleID)}) {
	my $r=new IMDB::Local::Actor(imdbdb=>$self->imdbdb, ActorID=>$id);
	if ( $r ) {
	    $self->Hosts_push($r)
	}
    }
}

sub populateNarrators($)
{
    my ($self)=@_;
    
    for my $id (@{$self->imdbdb->select2Array("SELECT ActorID from Titles2Narrators where TitleID=".$self->TitleID)}) {
	my $r=new IMDB::Local::Actor(imdbdb=>$self->imdbdb, ActorID=>$id);
	if ( $r ) {
	    $self->Narrators_push($r)
	}
    }
}

sub _sortEpisodes
{
    my ($a, $b)=@_;
    
    if ( $a->Series == $b->Series ) {
	return($a->Episode <=> $b->Episode);
    }
    return($a->Series <=> $b->Series);
}

sub getEpisodes($)
{
    my ($self)=@_;
    
    if ( $self->QualifierType->Name ne 'tv_series' ) {
	carp("not an episodal title");
    }

    my @episodes;
    
    for my $id (@{$self->imdbdb->select2Array("SELECT TitleID from Titles where ParentID=".$self->TitleID." order by Series,Episode")}) {
	my $e=IMDB::Local::Title::findByTitleID($self->imdbdb, $id);
	if ( $e ) {
	    push(@episodes, $e);
	}
    }
    return(sort {_sortEpisodes($a,$b)} @episodes);
}

use IMDB::Local::Genre;

sub populateGenres($)
{
    my ($self)=@_;
    
    for my $id (@{$self->imdbdb->select2Array("SELECT GenreID from Titles2Genres where TitleID=".$self->TitleID." order by GenreID")}) {
	my $r=new IMDB::Local::Genre(imdbdb=>$self->imdbdb, GenreID=>$id);
	if ( $r ) {
	    $self->Genres_push($r)
	}
    }
}

use IMDB::Local::Keyword;

sub populateKeywords($)
{
    my ($self)=@_;
    
    for my $id (@{$self->imdbdb->select2Array("SELECT KeywordID from Titles2Keywords where TitleID=".$self->TitleID)}) {
	my $r=new IMDB::Local::Keyword(imdbdb=>$self->imdbdb, KeywordID=>$id);
	if ( $r ) {
	    $self->Keywords_push($r)
	}
    }
}

sub populateAll($)
{
    my ($self)=@_;
    
    $self->populateQualifierType();

    $self->populatePlots();
    $self->populateDirectors();
    $self->populateActors();
    $self->populateHosts();
    $self->populateNarrators();
    $self->populateGenres();
    $self->populateKeywords();
    $self->populateRating();
}

sub toText($)
{
    my ($self)=@_;
    my $text='';

    $text.=$self->SUPER::toText();
    
    $text.="URL:".$self->imdbUrl()."\n";

    if ( $self->QualifierType ) {
	 $text.=$self->QualifierType->toText();
    }
    
    if ( $self->Directors && $self->Directors_count ) {
	for (my $n=0; $n < $self->Directors_count() ; $n++) {
	    $text.="Director #$n:\n";
	    for my $line (split(/\n/, $self->Directors_index($n)->toText())) {
		$text.="\t$line\n";
	    }
	}
    }
    
    if ( $self->Actors && $self->Actors_count ) {
	$text.="Actors:\n";
	for (my $n=0; $n < $self->Actors_count() ; $n++) {
	    $text.="\t".$self->Actors_index($n)->Name()."\n";
	}
    }
    if ( $self->Hosts && $self->Hosts_count ) {
	$text.="Hosts:\n";
	for (my $n=0; $n < $self->Hosts_count() ; $n++) {
	    $text.="\t".$self->Hosts_index($n)->Name()."\n";
	}
    }
    if ( $self->Narrators && $self->Narrators_count ) {
	$text.="Narrators:\n";
	for (my $n=0; $n < $self->Narrators_count() ; $n++) {
	    $text.="\t".$self->Narrators_index($n)->Name()."\n";
	}
    }
    if ( $self->Genres && $self->Genres_count ) {
	$text.="Genres:";
	for (my $n=0; $n < $self->Genres_count() ; $n++) {
	    $text.="".$self->Genres_index($n)->Name.",";
	}
	$text=~s/,$/\n/o;
    }

    if ( $self->Keywords && $self->Keywords_count ) {
	$text.="Keywords:";
	for (my $n=0; $n < $self->Keywords_count() ; $n++) {
	    $text.="".$self->Keywords_index($n)->Name.",";
	}
	$text=~s/,$/\n/o;
    }
    
    if ( $self->Rating  ) {
	$text.="Rating:Rank=".$self->Rating()->Rank.", Dist=".$self->Rating()->Distribution.", Votes=".$self->Rating()->Votes."\n";
    }

    if ( $self->Plots && $self->Plots_count  ) {
	for (my $n=0; $n < $self->Plots_count() ; $n++) {
	    my $p=$self->Plots_index($n);
	    $text.="Plot #:".$p->Sequence;
	    for my $line (split(/\n/, $p->toText())) {
		$text.="\t$line\n";
	    }
	}
    }
    return($text);
}

sub imdbUrl
{
    my ($self)=@_;

    if ( !defined($self->QualifierType) ) {
	$self->populateQualifierType();
    }

    my $dbkey;

    # tv_series
    if ( $self->QualifierType->QualifierTypeID == 3 ) {
	 $dbkey='"'.$self->Title.'"';
    }
    # episode_of_tv_series
    elsif ( $self->QualifierType->QualifierTypeID == 13 ) {
	# need to retrieve title from parent
	my $t=$self->getParentTitle();
	if ( $t ) {
	    $dbkey='"'.$t->Title.'"';
	}
    }
    else {
	$dbkey=$self->Title;
    }

    if ( $self->Year != 0 ) {
	$dbkey.=" (".$self->Year.")";
    }
    
    $dbkey=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/oeg;

    my $url="http://us.imdb.com/M/title-exact?".$dbkey;
    return($url);
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

    perldoc IMDB::Local::Title


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

1; # End of IMDB::Local::Title
