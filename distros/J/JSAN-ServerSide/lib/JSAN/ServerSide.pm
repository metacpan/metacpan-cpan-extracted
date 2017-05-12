package JSAN::ServerSide;

use strict;
use warnings;

our $VERSION = '0.06';


use URI::ToDisk;
use JSAN::Parse::FileDeps;
use Params::Validate qw( validate SCALAR );


sub new
{
    my $class = shift;
    my %p = validate( @_,
                      { js_dir => { type => SCALAR },
                        uri_prefix => { type => SCALAR },
                      },
                    );

    my $location = URI::ToDisk->new( $p{js_dir}, $p{uri_prefix} );

    return bless { location => $location }, $class;
}

sub add
{
    my $self = shift;
    my $js_class = shift;

    $self->_record_dependencies($js_class);

    push @{ $self->{classes} }, $js_class;
}

sub _record_dependencies
{
    my $self     = shift;
    my $js_class = shift;

    my $js_file = $self->_class_to_file($js_class);

    my $last_mod = _last_mod($js_file);

    return if $self->{last_checked}{$js_class} && $last_mod <= $self->{last_checked}{$js_class};

    my @deps = JSAN::Parse::FileDeps->library_deps($js_file);

    $self->{dependencies}{$js_class} = [ @deps ];
    $self->{last_checked}{$js_class} = time;

    $self->_record_dependencies($_) for @deps;
}

# separate primarily so it can be mocked for tests
sub _last_mod { (stat $_[0])[9] }

sub _class_to_file
{
    my $self = shift;

    $self->_class_to_path( shift )->path();
}

sub _class_to_path
{
    my $self     = shift;
    my $js_class = shift;

    my @pieces = split /\./, $js_class;
    $pieces[-1] .= '.js';

    return $self->{location}->catfile(@pieces);
}

sub uris
{
    my $self = shift;

    return map { $self->_class_to_uri($_) } $self->_classes();
}

sub files
{
    my $self = shift;

    return map { $self->_class_to_file($_) } $self->_classes();
}

sub _classes
{
    my $self = shift;

    my %seen;
    my @classes;
    for my $c ( @{ $self->{classes} } )
    {
        $self->_follow_deps( $c, \@classes, \%seen );
    }

    return @classes;
}

sub _follow_deps
{
    my $self    = shift;
    my $c       = shift;
    my $classes = shift;
    my $seen    = shift;

    return if $seen->{$c};
    $seen->{$c} = 1;

    for my $d ( @{ $self->{dependencies}{$c} } )
    {
        $self->_follow_deps( $d, $classes, $seen );
    }

    push @$classes, $c;
}

sub _class_to_uri
{
    my $self = shift;

    $self->_class_to_path( shift )->uri();
}


1;

__END__

=head1 NAME

JSAN::ServerSide - Manage JSAN dependencies server side instead of with XMLHttpRequest

=head1 SYNOPSIS

  use JSAN::ServerSide;

  my $js = JSAN::ServerSide->new( js_dir     => '/usr/local/js',
                                  uri_prefix => '/js',
                                );

  $js->add('DOM.Ready');
  $js->add('DOM.Display');
  $js->add('My.Class');

In a template ...

  <script type="text/javascript">
   JSAN = {};
   JSAN.use = function () {};
  </script>

  % for my $uri ( $js->uris() ) {
   <script src="<% $uri | %>" type="text/javascript"></script>
  % }

Or use it to create a single combined file:

  my $combined = combine $js->files() );

=head1 DESCRIPTION

The JSAN Javascript library allows you to import JSAN libraries in a
similar way to as Perl's C<use>.  This module provides a server-side
replacement for the JSAN library's importing mechanism.

The JSAN library's importing mechanism, which uses XMLHttpRequest, has
several downsides.  Some browsers (including Firefox) do not respect
caching headers when using XMLHttpRequest, so files will always be
re-fetched from the server.

After a library is retrieved, JSAN uses Javascript's C<eval> to
compile the Javascript libraries, which can cause the browser to
report errors as if they were coming from JSAN, not the library that
was fetched.

This module lets you create an object to manage dependencies on the
server side.  You tell it what libraries you want to use, and it finds
their dependencies and makes sure they are loaded in the correct
order.

Each Javascript file will be parsed looking for JSAN C<use> lines in
the form of C< JSAN.use("Some.Library") >.

Then when you call C< $js->uris() >, it returns a list of uris in the
necessary order to satisfy the dependencies it found.

You can also use this module to genereate a single combined Javascript
file with the included files in the correct order. Simply call C<
$js->files() > and combine them in the order they are returned.

=head2 Caching

Dependency information is cached in memory in the I<object>. If you
want to preserve this information in a persistent environment such as
mod_perl or FastCGI, you'll need to hold on to a reference to the
C<JSAN::ServerSide> object across multiple requests.

=head1 METHODS

This class provides the following functions:

=over 4

=item * Javascript::ServerSide->new(...)

This method accepts two parameters:

=over 8

=item o js_dir

This parameter is required.  It is the root directory of your
JSAN-style Javascript libraries.

=item o uri_prefix

This parameter is required.  It is the prefix to be prepended to
generated URIs.

=back

=item * $js->add('Class.Name')

This method accepts a JSAN-style library name (like "DOM.Ready") and
adds it to the object's list of libraries.

=item * $js->uris()

Returns a list of URIs, generated by turning the given JSAN library
names into URIs, along with any dependencies specified by those
libraries.  The list comes back in the proper order to ensure that
dependencies are loaded first.

=item * $js->files()

Returns a list of files, generated by turning the given JSAN library
names into paths, along with any dependencies specified by those
libraries.  The list comes back in the proper order to ensure that
dependencies are loaded first.

=back

=head1 MOCKING JSAN.js

If you use this module, you will need to mock out JSAN in your
generated HTML/JS.  Since the libraries being parsed contain a
C<JSAN.use()> call, this interface must be mocked in order to prevent
an error.

In the future, I hope JSAN will support a usage mode that only
provides exporting, without attempting to load libraries.

Mocking JSAN can be done with the following code:

  JSAN = {};
  JSAN.use = function () {};

=head1 CIRCULAR DEPENDENCIES

Currently, this module allows for circular dependencies because they
may not be a problem, depending on how the dependent classes are used.

For example, if "A" depends on "B" and vice versa, then A could still
work as long as it does not try to use B immediately at load time, but
rather defers that use until it is called by other code.

In Perl, this is never a problem because of the separate between
compile and run time phases.

In the future, this module may offer some sort of circular dependency
detection.

=head1 SEE ALSO

http://www.openjsan.org/, C<JSAN::Parse::FileDeps>, C<JSAN.pm>

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-jsan-serverside@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
