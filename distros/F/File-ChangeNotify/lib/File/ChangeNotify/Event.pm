package File::ChangeNotify::Event;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.27';

use Types::Standard qw( Str );
use Type::Utils qw( enum );

use Moo;

has path => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => enum( [qw( create modify delete unknown )] ),
    required => 1,
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Class for file change events

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ChangeNotify::Event - Class for file change events

=head1 VERSION

version 0.27

=head1 SYNOPSIS

    my $watcher = File::ChangeNotify->instantiate_watcher(
        directories => [ '/my/path', '/my/other' ],
        filter      => qr/\.(?:pm|conf|yml)$/,
        exclude => [ 't', 'root', qr(/(?!\.)[^/]+$) ],
    );

    for my $event ( $watcher->new_events() ) {
        print $event->path(), ' - ', $event->type(), "\n";
    }

=head1 DESCRIPTION

This class provides information about a change to a specific file or
directory.

=head1 METHODS

=head2 File::ChangeNotify::Event->new(...)

This method creates a new event. It accepts the following arguments:

=over 4

=item * path => $path

The full path to the file or directory that changed.

=item * type => $type

The type of event. This must be one of "create", "modify", "delete", or
"unknown".

=back

=head2 $event->path()

Returns the path of the changed file or directory.

=head2 $event->type()

Returns the type of event.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=File-ChangeNotify> or via email to L<bug-file-changenotify@rt.cpan.org|mailto:bug-file-changenotify@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for File-ChangeNotify can be found at L<https://github.com/houseabsolute/File-ChangeNotify>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 - 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
