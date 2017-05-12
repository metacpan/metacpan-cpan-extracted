package Labyrinth::Plugin::Articles::Sections;

use warnings;
use strict;

use vars qw($VERSION $ALLSQL $SECTIONID);
$VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Articles::Sections - Sections handler plugin for Labyrinth

=head1 DESCRIPTION

Contains all the section handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Articles);

use Clone qw(clone);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Variables;

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

$ALLSQL     = 'AllArticles';
$SECTIONID  = 2;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item GetSection

Retrieves the section articles used for introductory passages. 

GetSection can be called with a named section, or it will use the section
of the current request. 

=back

=cut

sub GetSection {
    my ($self, $section) = @_;
    my $name = $cgiparams{name};
    $cgiparams{sectionid} = $SECTIONID;

    if($section) {
        $cgiparams{name} = $section;
    } else {
        my $request = $cgiparams{act} || 'home-public';
        $request = 'home-public'    if($request eq 'user-logout');
        ($cgiparams{name}) = split("-",$request);
    }

    $self->SUPER::Item();
    $tvars{page}->{section} = $tvars{articles}->{$cgiparams{name}}  if($tvars{articles}->{$cgiparams{name}});
    $cgiparams{name} = $name;   # revert back to what it should be!
}

=head1 ADMIN INTERFACE METHODS

Standard actions to administer the section content.

=over 4

=item Access

Determine with user has access to administration features.

=item Admin

Provide list of the sections currently available.

=item Add

Add a new section article.

=item Edit

Edit an existing section article.

=item Save

Save the current section article.

=item Delete

Delete a section article.

=back

=cut

sub Access  { Authorised(MASTER) }

sub Admin {
    return  unless AccessUser(MASTER);
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Admin();
}

sub Add {
    return  unless AccessUser(MASTER);
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Add();
}

sub Edit {
    return  unless AccessUser(MASTER);
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Edit();
}

sub Save {
    return  unless AccessUser(MASTER);
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Save();
}

sub Delete {
    return  unless AccessUser(MASTER);
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
