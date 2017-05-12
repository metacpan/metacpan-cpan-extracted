use warnings;
use strict;
package Jifty::Plugin::SiteNews;
use base qw'Jifty::Plugin';

our $VERSION = '0.9';

=head1 NAME

Jifty::Plugin::SiteNews - Provide site news in your app

=head1 DESCRIPTION

Provides a way to include site news in your Jifty app.  To use it, you
will need to add a news model:

  package YourApp::Model::News;
  use Jifty::DBI::Schema;
  use YourApp::Record schema {
    # ..additional properties go here, like 'author'
  };
  use Jifty::Plugin::SiteNews::Mixin::Model::News;

You will also need to alias the view somewhere; from YourApp::View:

  require Jifty::Plugin::SiteNews::View::News;
  alias Jifty::Plugin::SiteNews::View::News under '/news';

=head1 AUTHOR

Alex Vandiver

=head1 LICENSE

Copyright 2005-2009 Best Practical Solutions, LLC.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
