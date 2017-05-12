=head1 NAME

MKDoc::Core::Article::Overview - Overview of MKDoc::Core



=head1 SUMMARY

This is an article, not a module.



=head1 HISTORY

MKDoc is a mature, feature-rich web content management system which promotes
standards compliance, accessibility, usability and information architecture.

However, MKDoc code lives in one big CVS repository. Each time a feature is
added, the codebase increases a bit more.

Separation between various system components is sometimes a bit blurry.

Although MKDoc is not at the stage of "unworkable spaghetti code which needs to
be thrown away", there is quite a fair bit of cleanup / refactoring to be done.

The two main goals of L<MKDoc::Core> are to:

=over

=item Cleanup / Refactor MKDoc

=item Open-source MKDoc

=back



=head1 OVERVIEW

L<MKDoc::Core> is a mod_perl friendly application framework in which web applications
can be written.

Rather than writing L<MKDoc::Core> from scratch, the following has been done:

=over

=item Take the existing MKDoc code

=item Remove all user functionality

=item See what is remaining

=item Refactor & make minor improvements

=item Document thoroughly

=back


What Remains? You might ask. Well, let's see...


=head2 Install scripts

L<MKDoc::Core> comes with L<MKDoc::Core::Setup>, an easily subclassable module
which provides a standard installation procedure for MKDoc software packages.

L<MKDoc::Core> aims at providing an easy installation procedure - or at least
easier than other server-side OSS packages such as RT, Slash or Bugzilla. Well.
Maybe :)


=head2 A pluggable chain of responsiblity.

L<MKDoc::Core> offers a 'chain of responsibility' design pattern to handle
incoming HTTP requests. There is a predefined list of handlers which are called
plugins in MKDoc jargon. Each plugin can choose to process the request or not.

At the end of the plugin chain, there is always the L<MKDoc::Core::Not_Found>
plugin which always processes the request when everything else has failed. It
displays a '404 Not Found' page.


=head2 A multi website system

MKDoc has been designed to run multiple sites - and L<MKDoc::Core> reflects
that.

When you install L<MKDoc::Core>, you create a master repository which contains
an empty httpd.conf file. You just need to include this file in your apache
config. Unless you have specific requirements, you should not have to fiddle
around too much with Apache config files.

The way it works is that whenever you install a new site, it creates httpd.conf
files in the site directory which are included the the master directory's
httpd.conf file. All you need do once you have installed a new site is restart
apache.


=head2 A customization system

By default plugin use L<Petal> templates which are stored along with the code
somewhere in @INC/MKDoc/templates.

When you install L<MKDoc::Core>, you have to create a master directory in which
you can define server-wide defaults for all your L<MKDoc::Core> sites. For
example you can redefine a template in the L<MKDoc::Core> master directory and
all your L<MKDoc::Core> sites will use this default.

When you install an L<MKDoc::Core> site, you can customize further at the site
level (as opposed to server-wide level). This means that MKDoc::Core products
offer three degrees of customization:

=over

=item "Factory defaults"

=item Server wide

=item Site wide

=back


=head2 Multi-lingual support (optional)

By default L<MKDoc::Core::Plugin> class coupled with L<MKDoc::Core::Language>
will choose the appropriate template based on content negotiation. Other mechanisms
than content negotiation can be used through subclassing.


=head2 Some optional libraries

=over

=item L<MKDoc::Core::Plugin>

By default L<MKDoc::Core::Plugin> uses L<MKDoc::Core::Error> for easy error reporting -
which is especially useful with forms / user input validation.

It is also coupled with L<MKDoc::Core::Language> to provide your web application with
multi-lingual capabilities.


=item L<MKDoc::Core::Request>

A subclass of CGI.pm coupled with a per-request singleton design pattern.
Features minor bugfixes and extra methods over CGI.pm.


=item L<MKDoc::Core::Response>

Counterpart of L<MKDoc::Core::Request>, you can use L<MKDoc::Core::Response> to
easily and correctly format your HTTP responses.

=back



=head1 CAVEAT

L<MKDoc::Core> on its own does I<nuthin'>

The following products have been written completed:


=head2 L<MKDoc::Auth>

This MKDoc product provides:

=over

=item User signup / signout with customizable email confirmation

=item Apache authentication handlers

=item Login / Logout / Log as somebody else

=back


=head2 L<MKDoc::Forum>

This MKDoc product provides IMAP based, threaded discussion forums. It can be
used with any authentication mechanisms and works "out of the box" with
L<MKDoc::Auth>.


The following products need doing:


=head2 L<MKDoc::Authz>

This MKDoc product will provide:

=over

=item ACL based authorization facilities

=item Apache authentication handlers

=item Some kind of web interface for administration

=back


=head2 L<MKDoc::CMS>

This MKDoc product will provide the functionality presently offered by MKDoc
1.6, our proprietary content management system - Minus MKDoc::Forum which is
now a separate product.

See http://mkdoc.com/ for details.


=cut
