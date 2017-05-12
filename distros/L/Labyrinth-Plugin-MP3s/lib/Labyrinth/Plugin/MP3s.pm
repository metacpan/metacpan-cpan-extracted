package Labyrinth::Plugin::MP3s;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.01';

=head1 NAME

Labyrinth::Plugin::MP3s - MP3 plugin handler for Labyrinth

=head1 DESCRIPTION

Contains all the MP3 management handling functionality for the Labyrinth Web
Framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %cat_fields = (
    mp3catid    => { type => 0, html => 0 },
    category    => { type => 1, html => 1 },
);

my (@cat_mandatory,@cat_allfields);
for(keys %cat_fields) {
    push @cat_mandatory, $_     if($cat_fields{$_}->{type});
    push @cat_allfields, $_;
}

my %fields = (
    mp3id       => { type => 0, html => 0 },
    mp3catid    => { type => 1, html => 1 },
    orderno     => { type => 1, html => 1 },
    source      => { type => 1, html => 1 },
    tracks      => { type => 0, html => 2 },
    notes       => { type => 0, html => 2 },
    publish     => { type => 1, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(mp3catid orderno source tracks notes publish);
my $INDEXKEY    = 'mp3id';
my $ALLSQL      = 'AllMP3s';
my $SAVESQL     = 'SaveMP3';
my $ADDSQL      = 'AddMP3';
my $GETSQL      = 'GetMP3ByID';
my $LEVEL       = ADMIN;

my %adddata = (
    mp3id       => 0,
    mp3catid    => 1,
    orderno     => 999,
    source      => '',
    tracks      => '',
    notes       => '',
    publish     => 1,
);

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item * List

Lists all the publicly visable categories and MP3s.

=back

=cut

sub List {
    # get list for current realm
    my @cats = $dbi->GetQuery('hash','GetMP3Cats');
    $tvars{cats} = \@cats;
    my @rows = $dbi->GetQuery('hash','GetMP3s');
    $tvars{mp3s} = \@rows;
}

=head1 ADMIN INTERFACE METHODS

=head2 MP3s Methods

=over 4

=item * Admin

List, and manages, all the MP3s available within the system.

=item * Add

Add a new MP3.

=item * Edit

Edit details of an existing MP3.

=item * ReOrder

Re-order MP3s within a category.

=item * Promote

Publish, Archive, etc MP3s.

=item * Delete

Delete an MP3 from the system.

=item * Save

Validates the fields returned from the edit page, and either saves or inserts
the record into the database.

It should be noted that the actual media file upload data is saved in the 
'images' table. This is for legacy reasons and the table *should* have been
renamed, perhaps to 'media', but I've never gotten around to it.

=back

=cut

sub Admin {
    return  unless(AccessUser($LEVEL));
    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'ReOrder' ) { ReOrder(); }
           if($cgiparams{doaction} eq 'Promote' ) { Promote(); }
           if($cgiparams{doaction} eq 'Delete'  ) { Delete();  }
    }
    my @rows = $dbi->GetQuery('hash','AllMP3s');
    for my $row (@rows) {
        $row->{publish} = PublishState($row->{publish});
    }
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser($LEVEL);
    $tvars{data}{ddcats}    = CatSelect();
    $tvars{data}{ddpublish} = PublishSelect($tvars{data}{publish},1);
}

sub Edit {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    $tvars{data}{ddcats}    = CatSelect($tvars{data}{mp3catid});
    $tvars{data}{ddpublish} = PublishSelect($tvars{data}{publish},1);
}

sub ReOrder {
    my @rows = $dbi->GetQuery('hash',$ALLSQL);
    for my $row (@rows) {
        next    if($cgiparams{"ORDER$row->{mp3id}"} == $row->{orderno});
        $dbi->DoQuery('ReOrderMP3s',$cgiparams{"ORDER$row->{mp3id}"},$row->{mp3id});
    }
}

sub Promote {
    my @ids = CGIArray('LISTED');
    next    unless(@ids);

    my @rows = $dbi->GetQuery('hash',$ALLSQL);
    my %ids = map {$_->{mp3id} => $_->{publish}} @rows;

    for my $id (@ids) {
        next    unless(defined $ids{$id} && $ids{$id} < 4);
        $dbi->DoQuery('PromoteMP3s',($ids{$id} + 1),$id);
    }
}

sub Delete {
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    $dbi->DoQuery('DeleteMP3s',{ids=>join(",",@ids)});
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanMP3s($cgiparams{$_}) }
    }
    return  if FieldCheck(\@allfields,\@mandatory);
    
    # TODO upload Media file
    if($cgiparams{mp3file}) {
        my ($imageid,$imagelink) = SaveImageFile(
            param   => "FILEUPLOAD",
            stock   => 'mp3s'
        );

        # TODO
    }

    my @fields = map {$tvars{data}->{$_}} @savefields;
    if(    $cgiparams{$INDEXKEY}) { $dbi->DoQuery($SAVESQL,@fields,$cgiparams{$INDEXKEY}); } 
    else { $cgiparams{$INDEXKEY} =  $dbi->IDQuery( $ADDSQL,@fields); }

    $tvars{thanks} = 1;
}

=head2 Category Admin

=over 4

=item * CatAdmin

List, and manages, all the MP3 categories within the system.

=item * CatEdit

Edit details of an existing MP3 category.

=item * CatDelete

Delete an MP3 category from the system.

=item * CatSave

Validates the fields returned from the edit page, and either saves or inserts
the record into the database.

Note that there is no CatAdd, as this is purely a blank form, submitted to 
CatSave method.

=item * CatSelect

Provides a drop down list of the currently available MP3 categories.
=back

=cut

sub CatAdmin {
    return  unless(AccessUser($LEVEL));
    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete' ) { CatDelete();  }
    }
    my @rows = $dbi->GetQuery('hash','GetAllMP3Cats');
    $tvars{data} = \@rows   if(@rows);
}

sub CatEdit {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck('GetMP3CatByID','mp3catid',$LEVEL);
}

sub CatDelete {
    return  unless AccessUser($LEVEL);
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    $dbi->DoQuery('DeleteMP3Cats',{ids=>join(",",@ids)});
    $dbi->DoQuery('DeleteMP3Categories',{ids=>join(",",@ids)});
}

sub CatSave {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck('GetMP3CatByID','mp3catid',$LEVEL);
    for(keys %cat_fields) {
           if($cat_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($cat_fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($cat_fields{$_}->{html} == 3) { $cgiparams{$_} = CleanMP3s($cgiparams{$_}) }
    }
    return  if FieldCheck(\@cat_allfields,\@cat_mandatory);
    if($cgiparams{mp3catid}) {    $dbi->DoQuery('SaveMP3Category',$tvars{data}->{category},$cgiparams{mp3catid}); }
    else { $cgiparams{mp3catid} = $dbi->IDQuery('AddMP3Category',$tvars{data}->{category}); }
    $tvars{thanks} = 1;
}

sub CatSelect {
    my $opt = shift;
    my @rows = $dbi->GetQuery('hash','GetAllMP3Cats');
    DropDownRows($opt,'mp3catid','mp3catid','category',@rows);
}

1;

__END__

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
