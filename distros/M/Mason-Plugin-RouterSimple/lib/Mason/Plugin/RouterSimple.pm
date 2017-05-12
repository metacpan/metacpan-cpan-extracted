package Mason::Plugin::RouterSimple;
BEGIN {
  $Mason::Plugin::RouterSimple::VERSION = '0.07';
}
use Moose;
with 'Mason::Plugin';

__PACKAGE__->meta->make_immutable();

1;



=pod

=head1 NAME

Mason::Plugin::RouterSimple - Specify routes for page components

=head1 VERSION

version 0.07

=head1 SYNOPSIS

In a top-level component '/archives.mc':

    <%class>
    route ":section/{year:[0-9]{4}}/{month:[0-9]{2}}";
    </%class>

    Archives for <b><% $.section %></b>
    For the month of <% $.month %>/<% $.year %>

then C</archives/news/2010/02> outputs

    Archives for <b>news</b>
    For the month of 2010/02

=head1 DESCRIPTION

See L<Mason::Manual::RequestDispatch> for background on how request paths get
mapped to page components.

This plugin allows you to parse C<< $m->path_info >> (the remainder of the
top-level path) using L<Router::Simple> routes.

It can be used whenever C<< $m->path_info >> is set, i.e. with a
L<dhandler|Mason::Manual::RequestDispatch/Dhandlers> or with a L<partial
path|Mason::Manual::RequestDispatch/Partial paths>.

Use the C<route> keyword to declare routes in a
L<E<lt>%classE<gt>|Mason::Manual::Syntax/E<lt>%classE<gt>> block.  Like
L<Router::Simple::connect|Router::Simple/METHODS>, C<route> takes a
string/regex pattern and a destination hashref; the latter defaults to C<{}> if
omitted. e.g.

    <%class>
    route "wiki/:page", { action => "wiki" };
    route "download/*.*", { action => "download" };
    route "blog/{year:[0-9]+}/{month:[0-9]{2}}";
    </%class>

This plugin overrides the default
L<allow_path_info|Mason::Manual::RequestDispatch/Partial paths> to return true
for any component that declares at least one route. For components that do not
declare a route, you will need to override C<allow_path_info> as usual.

Any named captured arguments, including C<splat>, are placed in component
attributes, which are automatically declared (as standard read-write
attributes) if you do not otherwise declare them.

If you specify more than one route in a component, they will be tried in turn,
with the first matching route taking precedence.

If none of the routes match, the request will be
L<declined|Mason::Request/decline>; in a web context this generally means a
404.

e.g. Given the route declarations above in a component named '/site.mc',

=over

=item *

The URL C</site/wiki/HomePage> will set C<$.action = "wiki"> and C<$.page =
"HomePage">.

=item *

The URL C</site/download/ping.mp3> will set C<$.action = "download"> and
C<$.splat = ['ping', 'mp3']>.

=item *

The URL C</site/blog/2010/02> will set C<$.year = "2010"> and C<$.month =
"02">.

=item *

The URLs C</site/other> and C</site/blog/10/02> will result in a decline/404.

=back

=head1 SUPPORT

The mailing list for Mason and Mason plugins is
L<mason-users@lists.sourceforge.net>. You must be subscribed to send a message.
To subscribe, visit
L<https://lists.sourceforge.net/lists/listinfo/mason-users>.

You can also visit us at C<#mason> on L<irc://irc.perl.org/#mason>.

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mason-Plugin-RouterSimple
    bug-mason-plugin-routersimple@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-mason-plugin-routersimple
    git clone git://github.com/jonswar/perl-mason-plugin-routersimple.git

=head1 SEE ALSO

L<Mason>, L<Router::Simple>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

