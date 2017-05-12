package Labyrinth::Plugin::Articles::Site;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Articles::Site - Site Pages handler plugin for Labyrinth

=head1 DESCRIPTION

Contains all the site pages handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Articles);

use Clone qw(clone);
use Time::Local;
use Data::Dumper;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Globals;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Variables;
use Labyrinth::Writer;
use Labyrinth::Metadata;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    articleid   => { type => 0, html => 0 },
    quickname   => { type => 1, html => 0 },
    title       => { type => 1, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $SECTIONID = 3;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Archive

Retrieves a list of the volumes available.

=item List

Retrieves a list of site pages.

=item Meta

Retrieves pages based on given meta tag.

=item Cloud

Provides a tag cloud for the current site pages.

=item Search

Retrieves a list of site pages based on a given search string.

=item Item

Provides the content of a named site page.

=back

=cut

sub Archive {
    $cgiparams{sectionid} = $SECTIONID;
    $cgiparams{section} = 'site';

    shift->SUPER::Archive();
    $tvars{articles} = undef;
}

sub List {
    $cgiparams{sectionid} = $SECTIONID;
    $settings{limit} = 1;

    shift->SUPER::List();
}

sub Meta {
    return  unless($cgiparams{data});

    $cgiparams{sectionid} = $SECTIONID;
    $settings{limit} = 10;

    shift->SUPER::Meta();
}

sub Cloud {
    $cgiparams{sectionid} = $SECTIONID;
    $cgiparams{actcode} = 'site-meta';
    shift->SUPER::Cloud();
}

sub Search {
    return  unless($cgiparams{data});

    $cgiparams{sectionid} = $SECTIONID;
    $settings{limit} = 10;

    shift->SUPER::Search();
}

sub Item {
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Item();
}

=head1 ADMIN INTERFACE METHODS

Standard actions to administer the section content.

=over 4

=item Access

Determine with user has access to administration features.

=item Admin

Provide list of the site pages currently available.

=item Add

Add a new site page.

=item Edit

Edit an existing site page.

=item Save

Save the current site page.

=item Delete

Delete a site page.

=back

=cut

sub Access  { Authorised(EDITOR) }

sub Admin {
    return  unless AccessUser(EDITOR);
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Admin();
}

sub Add {
    return  unless AccessUser(EDITOR);
    $cgiparams{sectionid} = $SECTIONID;
    my $self = shift;
    $self->SUPER::Add();
    $self->SUPER::Tags();
}

sub Edit {
    return  unless AccessUser(EDITOR);
    $cgiparams{sectionid} = $SECTIONID;
    my $self = shift;
    $self->SUPER::Edit();
    $self->SUPER::Tags();
}

sub Save {
    return  unless AccessUser(EDITOR);
    $cgiparams{sectionid} = $SECTIONID;
    $cgiparams{quickname} ||= formatDate(0);
    shift->SUPER::Save();
}

sub Delete {
    return  unless AccessUser(ADMIN);
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Delete();
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
