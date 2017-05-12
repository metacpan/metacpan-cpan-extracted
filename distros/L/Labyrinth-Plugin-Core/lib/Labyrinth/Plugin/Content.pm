package Labyrinth::Plugin::Content;

use strict;
use warnings;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Content - General page content functionality.

=head1 DESCRIPTION

The functions contain herein are for general page content functionality.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Support;
use Labyrinth::Variables;

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Admin

Checks whether user has admin priviledges.

=item Home

Sets article name to 'index' for quick loading.

=item Section

Sets article name to current section name for quick loading.

=back

=cut

sub Admin   { AccessUser(ADMIN); }
sub Home    { $cgiparams{name} = 'index';   }
sub Section { $cgiparams{name} = $tvars{section}; }

#----------------------------------------------------------
# Content Management Subroutines

=head1 CONTENT MANAGEMENT FUNCTIONS

=over 4

=item GetVersion

Sets the current application versions in template variables.

=item ServerTime

Sets the current server time in a template variable.

=back

=cut

sub GetVersion  { $tvars{'version'} = $main::VERSION; $tvars{'labversion'} = $Labyrinth::Variables::VERSION; }
sub ServerTime  { $tvars{'server'}{'date'} = formatDate(3); $tvars{'server'}{'time'} = formatDate(17); }

=head1 REALM CHANGING FUNCTIONS

All the following reset the current realm.

=over

=item RealmAJAX

Use when the AJAX layout template is required.

=item RealmICal

Use when the ICal layout template is required.

=item RealmJS

Use when the JavaScript layout template is required.

=item RealmJSON

Use when the JSON layout template is required.

=item RealmPlain

Use when the plain text layout template is required.

=item RealmPopup

Use when the popup layout template is required.

=item RealmXML

Use when the XML layout template is required.

=item RealmYAML

Use when the YAML layout template is required.

=back

=cut

sub RealmAJAX   { $tvars{realm} = 'ajax';  }
sub RealmICal   { $tvars{realm} = 'ical';  }
sub RealmJS     { $tvars{realm} = 'js';    }
sub RealmJSON   { $tvars{realm} = 'json';  }
sub RealmPlain  { $tvars{realm} = 'plain'; }
sub RealmPopup  { $tvars{realm} = 'popup'; }
sub RealmXML    { $tvars{realm} = 'xml';   }
sub RealmYAML   { $tvars{realm} = 'yaml';  }

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
