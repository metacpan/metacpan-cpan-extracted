package Labyrinth::Metadata;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Metadata - Metadata Management for Labyrinth.

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw( MetaSearch MetaSave MetaGet MetaCloud MetaTags ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

#----------------------------------------------------------------------------
# Libraries

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::Variables;

use HTML::TagCloud;

#----------------------------------------------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    title       => { type => 1, html => 1 },
    tagline     => { type => 0, html => 1 },
);

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 FUNCTIONS

=over 4

=item MetaSearch(%hash)

Provides the IDs for the given metadata search. The sqlkeys are one or more
keys into the phrasebook. Requires a hash of parameters:

  keys  => \@sqlkeys
  meta  => \@metadata
  full  => 1
  limit => $limit
  order => $order
  sort  => $sort_order

'key' and 'meta' are mandatory, all other key/value pairs are optional. If
'full' is provided with a non-zero value, a full text search is performed. If
a limit is given then only that number of records will be returned if more are
available. In order to suitably sort the records you can porovide the ORDER BY
string via the 'order' hash key.

=item MetaSave

Records the metadata with the given sqlkey for the name record id.

=item MetaGet

Gets the metadata for the given id.

=item MetaCloud

Returns the XHTML snippet to display a Metadata Tag Cloud.

=item MetaTags

Returns the list of tags attributed to a entry type and section ids.

=back

=cut

sub MetaSearch {
    my %hash = @_;

    my $keys = $hash{'keys'} || return ();
    my $meta = lc join(",", map {"'$_'"} @{$hash{meta}});
    my $data = lc join("|", @{$hash{meta}});
    my $full = $hash{'full'} || 0;

    LogDebug("MetaSearch: keys=[@$keys], meta=[$meta], full=$full");

    return ()   unless(@$keys && $meta);

    my $where = $hash{'where'} ? "AND $hash{'where'}" : '';
    my $limit = $hash{'limit'} ? "LIMIT $hash{'limit'}" : '';
    my $order = $hash{'order'} ? "ORDER BY $hash{'order'}" : '';

    my %res;
    for my $key (@$keys) {
        if($full) {
            # full text searching
            my @rs = $dbi->GetQuery('hash',"MetaDetail$key",{meta=>$meta, data => $data, where => $where, limit => $limit, order => $order});
            for(@rs) {$res{$_->{id}} = $_};
        } else {
            my @rs = $dbi->GetQuery('hash',"MetaSearch$key",{meta=>$meta, data => $data, where => $where, limit => $limit, order => $order});
            for(@rs) {$res{$_->{id}} = $_};
        }
    }

    my @res;
    if($hash{'order'}) {
        if($hash{'order'} eq 'createdate') {
            @res = map {$res{$_}} sort {int($res{$a}->{createdate}) <=> int($res{$b}->{createdate})} keys %res;
        } else {
            @res = map {$res{$_}} sort {$res{$a}->{$hash{'order'}} cmp $res{$b}->{$hash{'order'}}} keys %res;
        }
    } else {
        @res = map {$res{$_}} keys %res;
    }

    if($hash{'sort'} && $hash{'sort'} =~ /^desc/) {
        @res = reverse @res;
    }

    if($hash{'limit'}) {
        splice(@res,$hash{'limit'});
    }

    return @res;
}

sub MetaSave {
    my $id   = shift || return;
    my $keys = shift || return;
    my @meta = @_;

    LogDebug("MetaSave: $id,[@meta]");

    my $count = 0;
    for my $key (@$keys) {
        $dbi->DoQuery("MetaDelete$key",$id);
        $dbi->DoQuery("MetaUpdate$key",$id,lc($_)) for(@meta);
        $count += scalar(@meta);
    }

    return $count;
}

sub MetaGet {
    my ($id,$key) = @_;

    if($id && $key) {
        my @meta;
        my @rows = $dbi->GetQuery('array',"MetaGet$key",$id);
        if(@rows) {
            push @meta, $_->[1] for(@rows);
            return @meta    if(wantarray);
            return join(" ",sort @meta);
        }
    }

    return ()   if(wantarray);
    return;
}

sub MetaCloud {
    my %hash = @_;

    my $key       = $hash{'key'}       || return;
    my $sectionid = $hash{'sectionid'} || return;
    my $actcode   = $hash{'actcode'}   || return;

    my $path = $settings{'urlmap-'.$actcode} || "$tvars{cgipath}/pages.cgi?act=$actcode&amp;data=";

    my $cloud = HTML::TagCloud->new(levels=>10);
    my @rsa = $dbi->GetQuery('hash',"MetaCloud$key",{ids => $sectionid});
    for(@rsa) {
        $cloud->add($_->{metadata}, $path . $_->{metadata}, $_->{count});
    }

    my $html = $cloud->html();
    while($html =~ m!((<a href="$path)([^"]+)">)!) {
        my ($href,$link1,$link2) = ($1,$2,$3);
        $html =~ s!$href!$link1$link2" title="Meta search for '$link2'">!sgi;
    }

    return $html;
}

sub MetaTags {
    my %hash = @_;

    my $key       = $hash{'key'}       || return;
    my $sectionid = $hash{'sectionid'} || return;

    my @rows = $dbi->GetQuery('hash',"MetaCloud$key",{ids => $sectionid});
    my @tags = map {$_->{metadata}} @rows;
    return @tags;
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
