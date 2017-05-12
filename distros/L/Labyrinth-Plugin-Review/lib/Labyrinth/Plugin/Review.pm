package Labyrinth::Plugin::Review;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.01';

=head1 NAME

Labyrinth::Plugin::Review - Reviews plugin for the Labyrinth framework

=head1 DESCRIPTION

Contains all the functionality for book reviews.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Clone qw(clone);
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
    brand           => { type => 1, html => 1 },
    retailerid      => { type => 1, html => 0 },
    itemcode        => { type => 1, html => 0 },
    itemlink        => { type => 1, html => 0 },
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

sub FrontPage {
    my @rows;
    my @time = split("/",formatDate(9));
    my $this = "$time[0]/$time[1]";
    $time[1]--;
    if($time[1] < 1) { $time[0]--;$time[1]=12; }
    my $that = "$time[0]/$time[1]";


    my $stop = $settings{'frontpage'} || FRONTPAGE;
    my $next = $dbi->Iterator('hash','PubReviews');
    while(@rows < $stop && (my $row = $next->())) {
        $row->{new} = ($row->{createdate} =~ m!^($this|$that)! ? 1 : 0);
        push @rows, $row;
    }
    $tvars{reviews} = \@rows    if(@rows);
}

sub List {
    my $publish = 3 unless($tvars{command} eq 'admin');

    my @where;
    push @where, "r.publish=$publish"                           if($publish);
    push @where, "r.title LIKE '%$cgiparams{'searchtitle'}%'"   if($cgiparams{'searchtitle'});
    push @where, "r.reviewtypeid=$cgiparams{'reviewtypeid'}"    if($cgiparams{'reviewtypeid'});
    push @where, "r.userid=$cgiparams{'userid'}"                if($cgiparams{'userid'});
    push @where, "r.brand=$cgiparams{'brand'}"                  if($cgiparams{'brand'});
    push @where, "r.retailerid=$cgiparams{'retailerid'}"        if($cgiparams{'retailerid'});
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
    $tvars{ddretailers} = _dropdownRetailers($cgiparams{retailerid},1);
}

sub Item {
    return  unless($cgiparams{'reviewid'});

    my @rows = $dbi->GetQuery('hash','GetReviewByID',$cgiparams{'reviewid'});
    return  unless(@rows);

    if($rows[0]->{'imageid'}) {
        my @img = $dbi->GetQuery('hash','GetImageByID',$rows[0]->{'imageid'});
        $rows[0]->{'image_link'} = $img[0]->{'link'}  if(@img);
    }

    $rows[0]->{body} = '<p>' . $rows[0]->{body} unless($rows[0]->{body} =~ /^<p>/i);
    $tvars{data} = $rows[0];

    if($tvars{data}->{additional}) {
        my $html = '';
        my @links = split ",", $tvars{data}->{additional};
        foreach my $link (@links) {
            my ($name,$url) = split "=", $link;
            $html .= qq!<a href="$url" title="link to $name">$name</a><br />!;
        }
        $tvars{data}->{additional} = $html;
    }
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item * Access

Check default access to the Admin methods

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

sub Admin {
    return  unless AccessUser(EDITOR);

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete') { Delete(); }
        elsif($cgiparams{doaction} eq 'Copy')   { Copy();   }
    }

    List();
}

sub Add {
    AccessUser(EDITOR);

    my $select;
    if(Authorised(PUBLISHER)) {
        $select = UserSelect(0,1);
    } else {
        $select = DropDownRows($tvars{user}->{userid},'userid','userid','name',{userid => $tvars{user}->{userid}, name => $tvars{user}->{name}});
    }

    my %data = (
        ddreviewers => $select,
        ddretailers => _dropdownRetailers(),
        ddrevtypes  => _dropdownReviewTypes(),
        postdate    => formatDate(3),
    );

    $tvars{data}    = \%data;
    $tvars{preedit} = 1;
}

sub PreEdit {
    my @man = qw(userid reviewtypeid postdate itemcode);
    return  if FieldCheck(\@mandatory,\@mandatory);

    $tvars{data}->{realname}   = UserName($tvars{data}->{userid});
    $tvars{data}->{createdate} = unformatDate(3,$tvars{data}->{postdate});
}

sub Copy {
    $cgiparams{'reviewid'} = $cgiparams{'LISTED'};
    return  unless AuthorCheck('GetReviewByID','reviewid',PUBLISHER);

    my @fields = (  
        $tvars{data}->{reviewtypeid},0,
        $tvars{data}->{title},
        $tvars{data}->{brand},
        $tvars{data}->{itemcode},
        $tvars{data}->{userid},
        $tvars{data}->{createdate},
        $tvars{data}->{snippet},
        $tvars{data}->{body},
        $tvars{data}->{imageid},
        $tvars{data}->{itemlink},
        $tvars{data}->{retailerid},
        1
    );

    $cgiparams{reviewid} = $dbi->IDQuery('AddReview',@fields);
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

    $tvars{data}->{ddreviewers} = $select;
    $tvars{data}->{ddretailers} = _dropdownRetailers($tvars{data}->{retailerid});
    $tvars{data}->{ddrevtypes}  = _dropdownReviewTypes($tvars{data}->{reviewtypeid});
    $tvars{data}->{postdate}    = formatDate(3,$tvars{data}->{createdate});

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
        $tvars{data}->{brand},
        $tvars{data}->{itemcode},
        $tvars{data}->{userid},
        $tvars{data}->{createdate},
        $tvars{data}->{snippet},
        $tvars{data}->{body},
        $tvars{data}->{imageid},
        $tvars{data}->{itemlink},
        $tvars{data}->{retailerid},
        $tvars{data}->{publish}
    );

    # store review details
    if($tvars{data}->{reviewid})
            { $dbi->DoQuery('SaveReview',@fields,$tvars{data}->{reviewid}); }
    else    { $cgiparams{reviewid} = $dbi->IDQuery('AddReview',@fields); }

    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser(PUBLISHER);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    for my $id (@ids) {
        $cgiparams{'reviewid'} = $id;
        next    unless AuthorCheck('GetReviewByID','reviewid',PUBLISHER);
        $dbi->DoQuery('DeleteReview',$cgiparams{'reviewid'});
    }
}

# -------------------------------------
# Private Methods

sub _dropdownRetailers {
    my ($select,$blank) = @_;
    my @rows = $dbi->GetQuery('hash','AllRetailers');
    unshift @rows, {retailerid=>0,retailer=>'Select Retailer'}   if(defined $blank && $blank == 1);
    return DropDownRows($select,'retailerid','retailerid','retailer',@rows);
}

sub _dropdownReviewTypes {
    my ($select,$blank) = @_;
    my @rows = $dbi->GetQuery('hash','AllReviewTypes');
    unshift @rows, {reviewtypeid=>0,typename=>'Select Review Type'} if(defined $blank && $blank == 1);
    return DropDownRows($select,'reviewtypeid','reviewtypeid','typename',@rows);
}

1;

__END__

=head1 SEE ALSO

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
