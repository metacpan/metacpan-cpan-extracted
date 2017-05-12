use strict;
use warnings;

package Gentoo::ChangeLog::Parser::Eventual;
BEGIN {
  $Gentoo::ChangeLog::Parser::Eventual::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::ChangeLog::Parser::Eventual::VERSION = '0.1.2';
}

# ABSTRACT: Rudimentary Event-Based ChangeLog format parser, inspired by Pod::Eventual.



{
  use Carp qw( croak );
  use Moose;
  use namespace::clean -except => 'meta';

  has _context => ( isa => 'Str', is => 'rw', default => 'pre-parse', );

  has _event_register => ( isa => 'ArrayRef[ CodeRef ]', is => 'rw', lazy_build => 1, );


  has _callback => (
    isa      => 'CodeRef',
    init_arg => 'callback',
    is       => 'rw',
    required => 1,

    #  lazy_build => 1,
    traits    => ['Code'],
    'handles' => { handle_event => 'execute_method', },
  );

  sub _event_data {
    my ( $self, %other ) = @_;
    return { content => $self->{WORKLINE}, %other, %{ $self->{PASSTHROUGH} } };
  }


  sub handle_line {
    my ( $self, $line, $passthrough ) = @_;

    $passthrough ||= {};

    ## no critic ( ProhibitLocalVars )
    local $self->{WORKLINE}    = $line;
    local $self->{PASSTHROUGH} = $passthrough;

  RULE: for my $event ( @{ $self->_event_register } ) {
      local $_ = $self;

      my $result = $event->( $self, $line );

      next RULE if $result eq 'next';
      return    if $result eq 'fail';
      return 1  if $result eq 'return';
      croak(qq{Bad return $result});
    }
    return;
  }

  sub _build__event_register {
    return [
      \&_event_start,               \&_event_blank,                  \&_event_header_comment,
      \&_event_header_end,          \&_event_release_line,           \&_event_change_header,
      \&_event_begin_change_header, \&_event_continue_change_header, \&_event_end_change_header,
      \&_event_change_body,         \&_event_unknown
    ];
  }

  sub _build_callback {
    croak(q{Not implementeted!. For now you MUST specify callback yourself});
  }


  my %EVENT_LIST = map { $_ => 1 } qw(
    start
    blank
    header
    header_comment
    header_end

    release_line

    change_header
    change_body
    end_change_body

    begin_change_header
    continue_change_header
    end_change_header

    UNKNOWN
  );

  before handle_event => sub {
    croak("BAD EVENT $_[1]") if not exists $EVENT_LIST{ $_[1] };
  };

  sub _event_start {
    return 'next' if $_->_context ne 'pre-parse';
    $_->handle_event( 'start' => $_->_event_data() );
    $_->_context('document');
    return 'next';
  }

  sub _event_blank {
    return 'next' if $_->{WORKLINE} !~ /^\s*$/;
    $_->handle_event( 'blank' => $_->_event_data() );
    return 'return';
  }

  sub _event_header_comment {
    return 'next' if $_->{WORKLINE} !~ /^#\s*/;
    if ( $_->_context eq 'document' ) {
      $_->handle_event( 'header' => $_->_event_data() );
      $_->_context('header');
    }
    $_->handle_event( 'header_comment' => $_->_event_data() );
    return 'return';
  }

  sub _event_header_end {
    return 'next'
      if ( $_->_context() ne 'pre-parse' )
      and ( $_->_context() ne 'header' );

    $_->handle_event( 'header_end' => $_->_event_data() );
    $_->_context('body');
    return 'next';
  }

  sub _event_release_line {
    return 'next'
      if ( $_->_context() ne 'body' )
      and ( $_->_context() ne 'changebody' );
    return 'next' if $_->{WORKLINE} !~ /^\*/;
    if ( $_->_context eq 'changebody' ) {
      $_->handle_event( 'end_change_body' => $_->_event_data() );
      $_->_context('body');
    }

    $_->handle_event( 'release_line' => $_->_event_data() );
    return 'return';
  }

  sub _event_change_header {
    return 'next' if ( $_->_context() ne 'body' ) and ( $_->_context() ne 'changebody' );
    return 'next' if ( $_->{WORKLINE} !~ /^[ ]{2}\d\d?[ ][A-Z][a-z]+[ ]\d\d+;.*:\s*$/ );
    if ( $_->_context eq 'changebody' ) {
      $_->handle_event( 'end_change_body' => $_->_event_data() );
    }
    $_->handle_event( 'change_header' => $_->_event_data() );
    $_->_context('changebody');
    return 'return';
  }

  sub _event_begin_change_header {
    return 'next'
      unless ( $_->_context() eq 'body' )
      or ( $_->_context() eq 'changebody' );
    return 'next' if ( $_->{WORKLINE} !~ /^[ ]{2}\d\d?[ ][A-Z][a-z]+[ ]\d\d+;.*$/ );
    if ( $_->_context eq 'changebody' ) {
      $_->handle_event( 'end_change_body' => $_->_event_data() );
    }

    $_->handle_event( 'begin_change_header' => $_->_event_data() );
    $_->_context('changeheader');
    return 'return';
  }

  sub _event_continue_change_header {
    return 'next' unless $_->_context eq 'changeheader';
    return 'next' if $_->{WORKLINE} =~ /:\s*$/;
    $_->handle_event( 'continue_change_header' => $_->_event_data() );
    return 'return';
  }

  sub _event_end_change_header {
    return 'next' unless $_->_context eq 'changeheader';
    return 'next' unless $_->{WORKLINE} =~ /:\s*$/;
    $_->handle_event( 'end_change_header' => $_->_event_data() );
    $_->_context('changebody');
    return 'return';
  }

  sub _event_change_body {
    return 'next' unless $_->_context eq 'changebody';
    return 'next' unless $_->{WORKLINE} =~ /^[ ]{2}/;
    $_->handle_event( 'change_body' => $_->_event_data() );
    return 'return';
  }

  sub _event_unknown {
    $_->handle_event( 'UNKNOWN' => $_->_event_data() );
    return 'return';
  }
  __PACKAGE__->meta->make_immutable;

  no Moose;
}

1;

__END__

=pod

=head1 NAME

Gentoo::ChangeLog::Parser::Eventual - Rudimentary Event-Based ChangeLog format parser, inspired by Pod::Eventual.

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    use Gentoo::ChangeLog::Parser::Eventual
    my $parser = Gentoo::ChangeLog::Parser::Eventual->new(
        callback => sub {
            my ( $parser, $event, $opts ) = @_ ;
        },
    );

    $parser->handle_line( "This is a line", { key => 'value', line => 1 });

=head1 DESCRIPTION

In the proceeds of making a ChangeLog parser, I kept getting stuck on various parts with writing it cleanly.

This design, inspired by L<< RJBS' Great C<Pod::Eventual>|Pod::Eventual >>, greatly simplifies the process by using very rudimentary and loose
data validation.

Lines are fed in manually, because we didn't want to implement all the File IO our self and didn't want to
limit the interface by forcing passing a file handle.

You can do the IO quite simply anyway.

    while( my $line = <$fh> ){
        chomp $line;
        $parser->handle_line( $line , { line => $. } );
    }

A parser instance has a bit of state persistence, so you should use only 1 parser per input file.

Currently, it can only detect a few basic things.

=over 4

=item 1. Header blocks.

We go naive and classify that entire "# ChangeLog for " section at the top of a ChangeLog as a "Header".

The header itself is not validated or parsed in any way beyond the notion that its a series of comments.

=item 2. Release statements.

Raises an event when it sees

    *perl-5.12.2 (10 Jun 2010)

=item 3. Change Headers.

This is the part on the top of each ChangeLog entry as follows:

    10 Jun 2010; Bob Smith <asd>:

There are multiple ways this can be done however, so there are 3 events for this.

=item 4. Change bodies.

This is the part after the header.

=item 5. Blank Lines.

=back

=head1 METHODS

=head2 handle_line

handle_line is the only public method on this object. It takes one line, processes
its own state a bit, works out what event(s) need to be thrown, and call the passed callback.

=head3 Specification: $object->handle_line( Str $line, HashRef $opts )

=head3 Parameter: $line : Mandatory, Str

This must be a string, and this is the string that represents a singular line from the ChangeLog to be parsed.
This code is written under the assumption that you have also pre-chomped all your lines, but doesn't enforce it.
However, its not guaranteed to work, and is not tested for, and may in a future revision be enforced.

=head3 Parameter: $opts : Mandatory, HashRef

This is a HashRef of data to be sent through to the event handler.

This is a good place to specify the source line number of the line you are currently parsing if you want that.

     $object->handle_line("this line", { line => 4 } );

and then in the callback:

     my( $parser, $event, $opts ) = @_ ;
     print $opts->{line} = 4;

=head1 ATTRIBUTES

=head2 _callback

Outside construction and providing this (required) attribute, no public methods exist for
working with it.

=head3 Specification: CodeRef, rw, required, init_arg => callback

=head3 Construction.

    my $object = ::Elemental->new( callback => sub {
        my( $parser, $event, $opts ) = @_ ;
         .... event handler code here ....
    });

=head3 Parameter: $event : Str

This is the name of the event that has been triggered. See L</EVENTS>.

=head3 Parameter: $opts : HashRef

This is a Hash Reference of data about the event. Mostly, it contains whatever data was passed
from L</handle_line>, but it injects its own 'content' key containing a copy of the string that was parsed.

=head3 Executing.

You can manually execute the CodeRef as if it were called internally, but there is little point to this.

    $object->handle_event( 'an-event-name' => { } );

Note, that the event-names list is baked into this class, and manually calling this method and passing
an unsupported event name will result in casualties.

=head1 EVENTS

=head2 start

Fires when the first line is parsed.

=head2 blank

Fires on blank ( i.e.: all white space ) lines.

=head2 header

Fires on the first header line.

=head2 header_comment

Fires on all comments that are deemed "part of the header"

=head2 header_end

Fires on the first line that is obviously not part of the header, terminating the header.

=head2 release_line

Fires on C<*perl-5.12.2> lines.

=head2 change_header

Fires on Single-line change headers.

=head2 change_body

Fires on each line that looks like it was a child of the previous change header.

=head2 end_change_body

Fires when the first line is seen that indicates the change body is complete.

=head2 begin_change_header

Fires on the first line of a multi-line change header.

=head2 continue_change_header

Fires on all non-blank lines in a multi-line change header other than the first and last.

=head2 end_change_header

Fires on the last line of a multi-line change header

=head2 UNKNOWN

Fires in the event no processing rules indicated a success state.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
