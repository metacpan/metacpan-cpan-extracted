# @(#) $Id: Atom.pm 1102 2005-12-07 14:33:19Z dom $

package Log::Dispatch::Atom;

$VERSION = 0.03;

use warnings;
use strict;

use Carp qw( carp croak );
use Fcntl qw( :flock );
use POSIX qw( strftime );
use Params::Validate qw( validate SCALAR HASHREF );
use Sys::Hostname qw( hostname );
use XML::Atom 0.15;    # We need add_entry(mode=>insert).
use XML::Atom::Entry;
use XML::Atom::Feed;
use XML::Atom::Person;

use base qw( Log::Dispatch::Output );

# We don't want complaints about this; classes below will check the
# remaining args.
Params::Validate::validation_options( allow_extra => 1 );

sub new {
    my $class = shift;
    my %p     = @_;

    my $self = bless {}, $class;
    # Log::Dispatch setup.
    $self->_basic_init( %p );
    # Our setup.
    $self->_init( %p );
    return $self;
}

sub _init {
    my $self = shift;
    my %p    = validate(
        @_,
        {
            file        => { type => SCALAR },
            feed_id     => { type => SCALAR, optional => 1 },
            feed_title  => { type => SCALAR, optional => 1 },
            feed_author => { type => HASHREF, optional => 1 },
        }
    );
    $self->{ file }        = $p{ file };
    $self->{ feed_id }     = $p{ feed_id } if $p{ feed_id };
    $self->{ feed_title }  = $p{ feed_title } if $p{ feed_title };
    $self->{ feed_author } = $p{ feed_author } if $p{ feed_author };
    return;
}

sub _now_datetime { strftime "%Y-%m-%dT%H:%M:%SZ", gmtime }
sub _now_date     { strftime "%Y-%m-%d", gmtime }

sub log_message {
    my $self = shift;
    my %p    = validate(
        @_,
        {
            id     => { type => SCALAR,  default  => $self->_default_id },
            author => { type => HASHREF, optional => 1 },
        }
    );
    my $fh = eval {
        my $fh   = $self->_lock_and_open();
        my $feed = $self->_get_feed_from_handle( $fh );
        $self->_new_entry( $feed, \%p );
        $self->_write_feed( $fh, $feed );
        return $fh;
    };

    # Take care to avoid clobbering $@.
    my $err = $@;
    eval { $self->_unlock_and_close( $fh ) };
    die $err if $err;
    return;
}

{
    my $i;
    sub _default_id {
        my $self = shift;
        return sprintf( "tag:%s,%s:%d/%d/%d",
            hostname(), $self->_now_date(), time(), $$, ++$i );
    }
}

sub _get_feed_from_handle {
    my $self = shift;
    my ( $fh ) = @_;

    my $size = ( stat( $fh ) )[7];
    if ( $size > 0 ) {
        return XML::Atom::Feed->new( $fh );
    }
    else {
        return $self->_new_feed();
    }
}

sub _new_feed {
    my $self = shift;
    my $feed = XML::Atom::Feed->new( Version => '1.0' );
    $feed->id( $self->{ feed_id } )       if $self->{ feed_id };
    $feed->title( $self->{ feed_title } ) if $self->{ feed_title };
    if ( my $author = $self->{ feed_author } ) {
        $feed->author( $self->_new_person( $author ) );
    }
    return $feed;
}

sub _new_person {
    my $self     = shift;
    my ( $args ) = @_;
    my $person   = XML::Atom::Person->new( Version => '1.0' );
    $person->name( $args->{ name } )   if $args->{ name };
    $person->email( $args->{ email } ) if $args->{ email };
    $person->uri( $args->{ uri } )     if $args->{ uri };
    return $person;
}

sub _new_entry {
    my $self = shift;
    my ( $feed, $args ) = @_;
    my $entry = XML::Atom::Entry->new( Version => '1.0' );
    $entry->title( "$args->{message}" );
    $entry->content( "$args->{message}" );
    $entry->id( "$args->{id}" );

    my $now = _now_datetime();
    $feed->updated( $now );
    $entry->updated( $now );

    if ( $args->{ author } ) {
        $entry->author( $self->_new_person( $args->{ author } ) );
    }

    $feed->add_entry( $entry, { mode => 'insert' } );
    return $entry;
}

sub _write_feed {
    my $self = shift;
    my ( $fh, $feed ) = @_;

    seek $fh, 0, 0;
    print $fh $feed->as_xml();
    return;
}

sub _lock_and_open {
    my $self = shift;
    open my $fh, '+<', $self->{ file }
        or croak "open($self->{file}): $!";
    flock( $fh, LOCK_EX )
        or croak "flock($self->{file}): $!";
    return $fh;
}

sub _unlock_and_close {
    my $self = shift;
    my ( $fh ) = @_;
    return unless $fh;

    flock( $fh, LOCK_UN )
        or carp "unlock($self->{file}): $!";
    close( $fh )
        or carp "close($self->{file}): $!";
    return;
}

1;
__END__

=head1 NAME

Log::Dispatch::Atom - Log to an atom feed.

=head1 VERSION

This document describes Log::Dispatch::Atom version 0.01

=head1 SYNOPSIS

    use Log::Dispatch::Atom;

    my $log = Log::Dispatch::Atom->new(
        name      => 'foo',
        min_level => 'debug',
        file      => 'file.atom'
    );
    $log->log_message( level => 'error', message => 'A problem happened' );
    $log->log_message( level => 'debug', message => 'Got Here' );

=head1 DESCRIPTION

This class implements logging backed by an Atom feed so that you can
subscribe to the errors produced by your application.

You should not use this object directly, but should manage it via a
L<Log::Dispatch> object.

=head1 IMPLEMENTATION NOTES

In order to safely write to the log file, the entire file must be locked
each time that an entry is logged.  This probably makes it unsuitable
for high volume log files.

The log file is opened and closed on each call to log_message().

=head1 METHODS

=over 4

=item new()

Takes a hash of arguments.  Returns a new Log::Dispatch::Atom object.
The following parameters are used:

=over 4

=item I<name> [mandatory]

The name of the logging object.

=item I<min_level> [mandatory]

The minimum logging level this object will accept.  See L<Log::Dispatch>
for more information.

=item I<max_level> [optional]

The maximum logging level this object will accept.  See L<Log::Dispatch>
for more information.  The default is the highest possible level (ie: no
maximum).

=item I<file> [mandatory]

Specifies the location of the file to read/write the feed from.

=item I<feed_id> [optional]

Specifies the identity of the feed itself.  Normally, this should be
set to the published URI of the feed.

If not specified, it will be omitted, which is in violation of the
Atom specification.  For more information, see
L<http://www.atomenabled.org/developers/syndication/#requiredFeedElements>.

=item I<feed_title> [optional]

The title of the feed.  This should probably be set to the name of
your application.

If not specified, it will be omitted, which is in violation of the
Atom specification.  For more information, see
L<http://www.atomenabled.org/developers/syndication/#requiredFeedElements>.

B<XXX> This should probably just use the I<name> parameter.  What do you
think?  Let me know.

=item I<feed_author> [optional]

The author details of a feed.  This is specified as a hash reference,
which must contain one or more of the three keys I<name>, I<email> and
I<uri>.

In order to create a valid Atom feed, you must either supply an author
in every single entry (log message), or ensure that the feed itself has
an author.  The latter is probably the easier solution, so I recommend
this parameter be supplied.

=back

B<NB>:  The I<feed_*> parameters will only be used when a new feed is
being created.  If you are creating a new object for an existing feed,
they will be ignored.

=item log_message()

Takes a hash of arguments.  Has no return value.  The following
parameters are used.

=over 4

=item I<message> [mandatory]

The actual log message.

=item I<level> [mandatory]

The level of the message.  See L<Log::Dispatch> for a full list.

=item I<id> [optional]

Each entry requires an id in order for the feed as a whole to be a valid
Atom document.  It's used by readers of Atom documents to determine
whether or not an entry has been seen previously.

If not specified, this will default to an URL comprising the current
time plus the pid plus the hostname plus a monotonically increasing
integer.  eg: tag:fred.example.com,2005-12-07:1133946771/20827/2.  This
should be good enough for a uniqueness test.

=item I<author> [optional]

You can specify author details for an individual entry if desired.  The
author parameter is expected to be a hash reference, which must contain
one or more of the keys I<name>, I<email> or I<uri>.

=back

=back

=head1 SEE ALSO

L<XML::Atom>, the module used for Atom processing.

The spec for the atom syndication format,
L<http://www.atomenabled.org/developers/syndication/>.

=head1 DEPENDENCIES

L<XML::Atom> version 0.15.

This module uses flock() to the lock the feed file whilst it's writing,
so your version of Perl will need support for that.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-xml-atom-log@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Dominic Mitchell  C<< <cpan (at) happygiraffe.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Dominic Mitchell C<< <cpan (at) happygiraffe.net> >>.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

=over 4

=item 1.

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item 2.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=back

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: set ai et sw=4 :
