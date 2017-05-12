#
# This file is part of Jedi-Plugin-Template
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Template;

# ABSTRACT: Plugin for Template Toolkit

use strict;
use warnings;

our $VERSION = '1.001';    # VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

use B::Hooks::EndOfScope;

sub import {
    my $target = caller;
    on_scope_end {
        $target->can('with')->('Jedi::Plugin::Template::Role');
    };
    return;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Template - Plugin for Template Toolkit

=head1 VERSION

version 1.001

=head1 DESCRIPTION

This is a L<Template::Toolkit> plugin for L<Jedi> web app framework.

L<Jedi> is just a simple web app framework that help your create app above L<Plack>.

This plugin handle your L<Template::Toolkit> files for you.

It will use the Jedi config to get the directory of your templates. The default value is the dist_dir of your module.

=head1 SYNOPSIS

The directory of your templates should look like :

 * public
 * views
   * layouts

The public directory contain all your static files. It is generally your javascripts and css.

The views directory contain all your template toolkit files.

The views/layouts contain all your template toolkit layout files.

To use it in your Jedi app :

  package MyApps;
  use Jedi::App;
  use Jedi::Plugin::Template;

  sub jedi_app {
    # ...
    $jedi->get('/bla', sub {
      my ($jedi, $request, $response) = @_;
      $response->body(
        $jedi->jedi_template('test.tt', {hello => 'world'}, 'main.tt');
      );
      return 1;
    })
  }

  1;

The views directory here, look like :

 * views
   * test.tt
   * layouts
     * main.tt

The main.tt look like

  <html>
  <body>
  This will wrap your content :
  
  [% content %]
  </body>
  </html>

And your test.tt :

  <p>Hello [% hello %]</p>

=head1 CONFIGURATION: template_dir

By default L<Jedi::Plugin::Template> will setup the 'template_dir' configuration to the dist_dir of your package :

 MyApps:
  template_dir: DIST_DIR('MyApps')

You can create a config file to be able to do development in your working directory like this :

 MyApps:
  template_dir: ./share/

In order to be able to deploy and use properly your app like any other perl packages, use the 'share' directory.

With L<Dist::Zilla> it will be automatic if the "public" and "views" directory is placed under the "share" directory.

If you use L<Module::Build> you need to defined : 

 my %module_build_args = (
  # ...
  "share_dir" => {
   "dist" => "share"
  },
  # ...
 );

=head1 SET A DEFAULT LAYOUT: jedi_template_default_layout

 You can defined a default layout, by setting the attribute : 'jedi_template_default_layout'

  $jedi_app->jedi_template_default_layout('main.tt');

=head1 GET YOUR TEMPLATE: jedi_template

The method 'jedi_template' will use L<Template> to process your template.

  $jedi_app->jedi_template($file, \%vars);
  $jedi_app->jedi_template($file, \%vars, $layout);

The layout use the jedi_template_default_layout by default.

You can also remove any layout, using the value "none".

 $jedi_app->jedi_template($file, \%vars, 'none'),

=head1 THE PUBLIC DIRECTORY

The plugin will match all missing by sending a public file if this one exists. It handle cache and compression for you.

 * public
   * mystyle.css

 curl http://localhost:3000/mystyle.css

If no route match the '/mystyle.css', then the plugin will check in the public dir and send the file if this one is present.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-template/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
