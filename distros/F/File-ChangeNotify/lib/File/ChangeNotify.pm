package File::ChangeNotify;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.31';

use Carp qw( confess );

# We load this up front to make sure that the prereq modules are installed.
use File::ChangeNotify::Watcher::Default;
use Module::Pluggable::Object;
use Module::Runtime qw( use_module );

# First version to support coerce => 1
use Moo 1.006 ();

sub instantiate_watcher {
    my $class = shift;

    my @usable = $class->usable_classes;
    return $usable[0]->new(@_) if @usable;

    return File::ChangeNotify::Watcher::Default->new(@_);
}

{
    my $finder = Module::Pluggable::Object->new(
        search_path => 'File::ChangeNotify::Watcher' );
    my $loaded;
    my @usable_classes;

    sub usable_classes {
        return @usable_classes if $loaded;
        @usable_classes = grep { _try_load($_) }
            sort grep { $_ ne 'File::ChangeNotify::Watcher::Default' }
            $finder->plugins;
        $loaded = 1;

        return @usable_classes;
    }
}

sub _try_load {
    my $module = shift;

    my $ok = eval { use_module($module) };
    my $e  = $@;
    return $module if $ok;

    die $e
        if $e
        && $e !~ /Can\'t locate|did not return a true value/;
}

1;

# ABSTRACT: Watch for changes to files, cross-platform style

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ChangeNotify - Watch for changes to files, cross-platform style

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    use File::ChangeNotify;

    my $watcher =
        File::ChangeNotify->instantiate_watcher
            ( directories => [ '/my/path', '/my/other' ],
              filter      => qr/\.(?:pm|conf|yml)$/,
            );

    if ( my @events = $watcher->new_events ) { ... }

    # blocking
    while ( my @events = $watcher->wait_for_events ) { ... }

=head1 DESCRIPTION

This module provides an API for creating a
L<File::ChangeNotify::Watcher> subclass that will work on your
platform.

Most of the documentation for this distro is in
L<File::ChangeNotify::Watcher>.

=head1 METHODS

This class provides the following methods:

=head2 File::ChangeNotify->instantiate_watcher(...)

This method looks at each available subclass of
L<File::ChangeNotify::Watcher> and instantiates the first one it can
load, using the arguments you provided.

It always tries to use the L<File::ChangeNotify::Watcher::Default>
class last, on the assumption that any other class that is available
is a better option.

=head2 File::ChangeNotify->usable_classes

Returns a list of all the loadable L<File::ChangeNotify::Watcher> subclasses
except for L<File::ChangeNotify::Watcher::Default>, which is always usable.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=File-ChangeNotify> or via email to L<bug-file-changenotify@rt.cpan.org|mailto:bug-file-changenotify@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for File-ChangeNotify can be found at L<https://github.com/houseabsolute/File-ChangeNotify>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Aaron Crane H. Merijn Branch Karen Etheridge

=over 4

=item *

Aaron Crane <arc@cpan.org>

=item *

H. Merijn Branch <h.m.brand@xs4all.nl>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 - 2019 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
