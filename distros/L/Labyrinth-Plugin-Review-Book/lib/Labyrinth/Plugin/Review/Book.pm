package Labyrinth::Plugin::Review::Book;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

Labyrinth::Plugin::Review::Book - Book Reviews plugin for the Labyrinth framework

=head1 DESCRIPTION

Contains all the functionality for book reviews.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Review);

use Clone qw(clone);
use WWW::Scraper::ISBN;
use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Media;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

use Data::Dumper;

# -------------------------------------
# Constants

use constant    FRONTPAGE       => 10;
use constant    COVER_WIDTH     => 150;
use constant    COVER_HEIGHT    => 200;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    # review references
    reviewid        => { type => 0, html => 0 },
    title           => { type => 1, html => 1 },
    userid          => { type => 1, html => 0 },
    reviewtypeid    => { type => 1, html => 0 },
    postdate        => { type => 1, html => 0 },
    imageid         => { type => 0, html => 0 },
    snippet         => { type => 0, html => 2 },
    body            => { type => 1, html => 2 },
    publish         => { type => 1, html => 0 },
    additional      => { type => 0, html => 1 },

    # item references
    author          => { type => 1, html => 1 },    # aka brand
    isbn            => { type => 1, html => 0 },    # aka itemcode
    publisherid     => { type => 1, html => 0 },    # aka retailerid
    book_link       => { type => 1, html => 0 },    # aka itemlink
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item * FrontPage

Provides the an abbreviated list of the latest reviews to use on the front
page or a side panel of the website.

=item * List

Provides a full list, filtered based on any search criteria, of reviews for
the main reviews page on the website.

=item * Item

Provides all the details for a specific review.

=back

=cut

sub List {
    my $publish = 3 unless($tvars{command} eq 'admin');

    my @where;
    push @where, "r.publish=$publish"                           if($publish);
    push @where, "r.title LIKE '%$cgiparams{'searchtitle'}%'"   if($cgiparams{'searchtitle'});
    push @where, "r.reviewtypeid=$cgiparams{'reviewtypeid'}"    if($cgiparams{'reviewtypeid'});
    push @where, "r.userid=$cgiparams{'userid'}"                if($cgiparams{'userid'});
    push @where, "r.brand=$cgiparams{'author'}"                 if($cgiparams{'author'});
    push @where, "r.retailerid=$cgiparams{'publisherid'}"       if($cgiparams{'publisherid'});
    my $where = @where ? 'WHERE '.join(' AND ',@where) : '';

    my @rows = $dbi->GetQuery('hash','AllReviews',{where=>$where});
    foreach (@rows) {
        $_->{publishstate} = PublishState($_->{publish});
        $_->{postdate} = formatDate(3,$_->{createdate});
    }
    $tvars{data} = \@rows   if(@rows);

    $tvars{searchtitle} = $cgiparams{searchtitle};
    $tvars{ddreviewers} = UserSelect($cgiparams{userid},1,1,'Reviewer');
    $tvars{ddrevtypes}  = _dropdownReviewTypes($cgiparams{reviewtypeid},1);
    $tvars{ddpublishers}= _dropdownRetailers($cgiparams{publisherid},1);
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item * Access

Check default access to the Admin methods

=item * ImageCheck

Returns true or false as to whether the given image is referenced wihin a 
review. 

Currently this method always returns false.

=item * Admin

List reviews for administration purposes.

=item * Add

Add a review.

=item * PreEdit

Following an add review page, there may be additional lookuos required to 
check the validity of the product code given. This may be an additonal API
call to a 3rd party website, and is most likely to be used by sub-classed
modules.

Requires a call to the Edit method to display current values.

=item * Copy

Copies an existing review to a new review. Typical when you want to use the 
same product to review, and just want to use the same product references.

Requires a call to the Edit method to display current values.

=item * Edit

Edit a review.

=item * Save

Save a review.

=item * Delete

Delete one or more reviews.

=back

=cut

sub Access  { Authorised(EDITOR) }
sub ImageCheck  { return 0 }

sub Add {
    AccessUser(EDITOR);

    my $select;
    if(Authorised(PUBLISHER)) {
        $select = UserSelect(0,1);
    } else {
        $select = DropDownRows($tvars{user}->{userid},'userid','userid','name',{userid => $tvars{user}->{userid}, name => $tvars{user}->{name}});
    }

    my %data = (
        ddreviewers     => $select,
        ddpublishers    => _dropdownRetailers(),
        ddrevtypes      => _dropdownReviewTypes(),
        postdate        => formatDate(3),
    );

    $tvars{data}    = \%data;
    $tvars{preedit} = 1;
}

sub PreEdit {
    my @man = qw(userid reviewtypeid postdate isbn);
    return  if FieldCheck(\@mandatory,\@mandatory);

    $tvars{data}->{realname}   = UserName($tvars{data}->{userid});
    $tvars{data}->{createdate} = unformatDate(3,$tvars{data}->{postdate});

    my $scraper = WWW::Scraper::ISBN->new();
    my @drivers = $scraper->available_drivers;
    $scraper->drivers(@drivers);

    $tvars{data}->{isbn} =~ tr/0-9X//cd;
LogDebug("isbn=[$tvars{data}->{isbn}]");
    my $result = $scraper->search($tvars{data}->{isbn});

    if($result->found) {
        my @fields = qw(isbn title author book_link image_link publisher);
        my $book = $result->book;
        $tvars{data}->{$_} = $book->{$_} for(@fields);

        # do we have an image?
        if($book->{image_link}) {
#LogDebug("thumb=[$book->{image_link}]");
            ($tvars{data}->{imageid},$tvars{data}->{image_link}) = MirrorImageFile($book->{image_link},'Covers',COVER_WIDTH,COVER_HEIGHT);
#LogDebug("image=[$tvars{data}->{image_link}]");
        }

        # do we have the publisher in the DB
        my @rows = $dbi->GetQuery('hash','FindPublisher',$book->{publisher});
        $tvars{data}->{publisherid} = $rows[0]->{publisherid}   if(@rows);

        # O'Reilly have defined Errata links.
        if(defined $tvars{data}->{publisher} && $tvars{data}->{publisher} =~ /Reilly/) {
            $tvars{data}->{additional} = sprintf "Errata=%s/errata/",dirname($tvars{data}->{book_link});
        }
    }

#   use Data::Dumper;
#   LogDebug(Dumper($tvars{data}));
}

sub Copy {
    $cgiparams{'reviewid'} = $cgiparams{'LISTED'};
    return  unless AuthorCheck('GetReviewByID','reviewid',PUBLISHER);

    my @fields = (  
        $tvars{data}->{reviewtypeid},
        0,
        $tvars{data}->{title},
        $tvars{data}->{author},
        $tvars{data}->{isbn},
        $tvars{data}->{userid},
        $tvars{data}->{createdate},
        $tvars{data}->{snippet},
        $tvars{data}->{body},
        $tvars{data}->{imageid},
        $tvars{data}->{book_link},
        $tvars{data}->{publisherid},
        1
    );

    $cgiparams{reviewid} = $dbi->IDQuery('AddReview',@fields);

    $tvars{errcode} = 'NEXT';
    $tvars{command} = 'revs-edit';
}

sub Edit {
    if($cgiparams{reviewid}) {
        return  unless AuthorCheck('GetReviewByID','reviewid',PUBLISHER);

        if($tvars{data}->{'imageid'}) {
            my @img = $dbi->GetQuery('hash','GetImageByID',$tvars{data}->{'imageid'});
            $tvars{data}->{'image_link'} = $img[0]->{'link'}  if(@img);
        }

        if($tvars{data}->{publish} == 4 && $tvars{command} ne 'view') {
            $tvars{errcode} = 'FAILURE';
            return;
        }
    }

    my $select;
    if(Authorised(PUBLISHER)) {
        $select = UserSelect($tvars{data}->{userid},1,1);
    } else {
        $select = DropDownRows($tvars{user}->{userid},'userid','userid','name',{userid => $tvars{user}->{userid}, name => $tvars{user}->{name}});
    }

    my $promote = 0;
    $promote = 1    if($tvars{data}->{publish} == 1 && Authorised(EDITOR));
    $promote = 1    if($tvars{data}->{publish} == 2 && Authorised(PUBLISHER));
    $promote = 1    if($tvars{data}->{publish} == 3 && Authorised(PUBLISHER));
    $tvars{data}->{ddpublish} = PublishAction($tvars{data}->{publish},$promote);
    $tvars{data}->{ddpublish} = PublishSelect($tvars{data}->{publish})  if(Authorised(ADMIN));

    $tvars{data}->{ddreviewers}     = $select;
    $tvars{data}->{ddpublishers}    = _dropdownRetailers($tvars{data}->{publisherid});
    $tvars{data}->{ddrevtypes}      = _dropdownReviewTypes($tvars{data}->{reviewtypeid});
    $tvars{data}->{postdate}        = formatDate(3,$tvars{data}->{createdate});

    $tvars{preview} = clone($tvars{data});  # data fields need to be editable

    for(keys %fields) {
           if($fields{$_}->{html} == 1) {   $tvars{data}->{$_}    = CleanHTML($tvars{data}->{$_});
                                            $tvars{preview}->{$_} = CleanHTML($tvars{preview}->{$_}); }
        elsif($fields{$_}->{html} == 2) {   $tvars{data}->{$_}    = SafeHTML($tvars{data}->{$_}); }
    }

    if($tvars{data}->{additional}) {
        my $html = '';
        my @links = split ",", $tvars{data}->{additional};
        foreach my $link (@links) {
            my ($name,$url) = split "=", $link;
            $html .= qq!<a href="$url" title="link to $name">$name</a><br />!;
        }
        $tvars{preview}->{additional} = $html;
    }
}

sub Save {
    return  unless AuthorCheck('GetReviewByID','reviewid',PUBLISHER);
    return  if FieldCheck(\@allfields,\@mandatory);

    for(keys %fields) {
        if($fields{$_}->{html} == 1)    { $tvars{data}->{$_} = CleanHTML($tvars{data}->{$_}) }
        elsif($fields{$_}->{html} == 2) { $tvars{data}->{$_} = CleanTags($tvars{data}->{$_}) }
    }

    $tvars{data}->{createdate} = unformatDate(3,$tvars{data}->{postdate}) if($tvars{data}->{postdate});
    ($tvars{data}->{imageid}) = SaveImageFile(
            param   => 'image_link',
            width   => $settings{review_cover_width}  || COVER_WIDTH,
            height  => $settings{review_cover_height} || COVER_HEIGHT,
            stock   => 'Covers'
        )   if($cgiparams{image_link});

    my @fields = (  
        $tvars{data}->{reviewtypeid},
        0,
        $tvars{data}->{title},
        $tvars{data}->{author},
        $tvars{data}->{isbn},
        $tvars{data}->{userid},
        $tvars{data}->{createdate},
        $tvars{data}->{snippet},
        $tvars{data}->{body},
        $tvars{data}->{imageid},
        $tvars{data}->{book_link},
        $tvars{data}->{publisherid},
        $tvars{data}->{publish}
    );

    # store review details
    if($tvars{data}->{reviewid})
            { $dbi->DoQuery('SaveReview',@fields,$tvars{data}->{reviewid}); }
    else    { $cgiparams{reviewid} = $dbi->IDQuery('AddReview',@fields); }

    $tvars{thanks} = 1;
}

sub _dropdownRetailers {
    my ($select,$blank) = @_;
    my @rows = $dbi->GetQuery('hash','AllRetailers');
    unshift @rows, {retailerid=>0,retailer=>'Select Publisher'}   if(defined $blank && $blank == 1);
    return DropDownRows($select,'publisherid','retailerid','retailer',@rows);
}

1;

__END__

=head1 SEE ALSO

  WWW::Scraper::ISBN,
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
