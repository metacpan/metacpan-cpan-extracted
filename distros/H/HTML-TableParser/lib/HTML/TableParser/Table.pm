package HTML::TableParser::Table;

# ABSTRACT: support class for HTML::TableParser

use strict;
use warnings;

use HTML::Entities qw();

our $VERSION = '0.43';

## no critic ( ProhibitAccessOfPrivateData )

#pod =method new
#pod
#pod =cut

sub new
{
  my $this = shift;

  my $class = ref($this) || $this;

  my $self = {
              data      => [[]],        # row data (for overlapping rows)
              row       => undef,       # row info
              col       => undef,       # column info
              hdr       => undef,       # accumulated header info
              hdr_row   => 0,           # index of header row
              hdr_line  => undef,       # line in file of header row
              in_hdr    => 0,           # are we in a header row?
              prev_hdr  => 0,           # was the previous row a header row?
              line      => undef,       # line in file of current row
              start_line => undef,      # line in file of table start
              req       => undef,       # the matching table request
              exclreqs  => {},          # the requests which exlude this table
             };

  bless $self, $class;

  my ( $parser, $ids, $reqs, $line ) = @_;

  $self->{parser} = $parser;
  $self->{start_line} = $line;

  # if called with no args, create an empty, placeholder object
  unless ( defined $ids )
  {
    $self->{ids} = [ 0 ];
    $self->{process} = 0;
    $self->{id} =  'sentinel';
  }

  else
  {
    $ids->[-1]++;
    $self->{oids} = [ @$ids ];
    $self->{ids} = [ @$ids, 0 ];
    $self->{id} =  join( '.', grep { $_ != 0 } @{$ids} );

    $self->{reqs} = $reqs;

    # are we interested in this table?
    $self->match_id();

    # inform user of table start.  note that if we're looking for
    # for column name matches, we don't want to do the callback;
    # in that case $self->{req} isn't set and callback() won't
    # actually make the call.
    $self->callback( 'start', $self->{start_line} )
                     if $self->{process};
  }

  $self;
}

#pod =method match_id
#pod
#pod =cut

sub match_id
{
  my $self = shift;

  $self->{process} = 0;
  $self->{req} = undef;

  # 1. look for explicit id matches
  # 2. if no explicit id match, use header matches
  # 3. if no header matches, use DEFAULT
  # 4. if no DEFAULT, no match

  # 1. explicit id.

  my ( $skip, $req );

  ( $skip, $req ) =
    req_match_id( $self->{reqs}, $self->{id}, $self->{oids},
                  $self->{exclreqs} );

  # did we match a skip table request?
  return if $skip;

  if ( $req )
  {
    $self->match_req( $req );
    return;
  }


  # 2. header match.
  # don't set {req}, as that'll trigger callbacks and we're not sure
  # this is a match yet

  if ( grep { @{$_->{cols}} } @{$self->{reqs}})
  {
    $self->{process} = 1;
    $self->{req} = undef;
    return;
  }

  # 3. DEFAULT match
  ( $skip, $req ) =
    req_match_id( $self->{reqs}, 'DEFAULT', $self->{oids}, $self->{exclreqs} );

  # did we match a skip table request? Does this make sense for DEFAULT?
  return if $skip;

  if ( $req )
  {
    $self->match_req( $req );
    return;
  }

  # 4. out of luck. no match.
}

#pod =method req_match_id
#pod
#pod =cut

# determine if a request matches an id.  requests should
# be real objects, but until then...
sub req_match_id
{
  my ( $reqs, $id, $oids, $excluded ) = @_;

  for my $req ( @$reqs )
  {
    # if we've already excluded this request, don't bother again.
    # this is needed for id = DEFAULT passes where we've previously
    # excluded based on actual table id and should again.
    next if exists $excluded->{$req};

    # bail if this request has already matched and we're not
    # multi-matching
    next if $req->{match} && ! $req->{MultiMatch};

    for my $cmp ( @{$req->{id}} )
    {
      # is this a subroutine to call?
      if ( 'CODE' eq ref $cmp->{match} )
      {
        next unless $cmp->{match}->($id, $oids );
      }

      # regular expression
      elsif( 'Regexp' eq ref $cmp->{match} )
      {
        next unless $id =~ /$cmp->{match}/;
      }

      # a direct match?
      else
      {
        next unless $id eq $cmp->{match};
      }

      # we get here only if there was a match.

      # move on to next request if this was an explicit exclude
      # request.
      if ( $cmp->{exclude} )
      {
        $excluded->{$req}++;
        next;
      }

      # return match, plus whether this is a global skip request
      return ( $cmp->{skip}, $req );
    }
  }

  ( 0, undef );
}

#pod =method req_match_cols
#pod
#pod =cut

# determine if a request matches a column.  requests should
# be real objects, but until then...
sub req_match_cols
{
  my ( $reqs, $cols, $id, $oids ) = @_;

  for my $req ( @$reqs )
  {
    # bail if this request has already matched and we're not
    # multi-matching
    next if $req->{match} && ! $req->{MultiMatch};

    my @fix_cols = @$cols;
    fix_texts($req, \@fix_cols);

    for my $cmp ( @{$req->{cols}} )
    {
      # is this a subroutine to call?
      if ( 'CODE' eq ref $cmp->{match} )
      {
        next unless $cmp->{match}->( $id, $oids, \@fix_cols );
      }

      # regular expression
      elsif( 'Regexp' eq ref $cmp->{match} )
      {
        next unless grep { /$cmp->{match}/ } @fix_cols;
      }

      # a direct match?
      else
      {
        next unless grep { $_ eq $cmp->{match} } @fix_cols;
      }

      # we get here only if there was a match

      # move on to next request if this was an explicit exclude
      # request.
      next if $cmp->{exclude};

      # return match, plus whether this is a global skip request
      return ( $cmp->{skip}, $req );
    }

  }

  (0, undef);
}

#pod =method match_hdr
#pod
#pod =cut

# we've pulled in a header; does it match against one of the requests?
sub match_hdr
{
  my ( $self, @cols ) = @_;


  # 1. check header matches
  # 2. if no header matches, use DEFAULT id
  # 3. if no DEFAULT, no match

  # 1. check header matches
  my ( $skip, $req ) = req_match_cols( $self->{reqs}, \@cols, $self->{id},
                                       $self->{oids} );
  # did we match a skip table request?
  return 0 if $skip;

  if ( $req )
  {
    $self->match_req( $req );
    return 1;
  }


  # 2. DEFAULT match
  ( $skip, $req ) =
    req_match_id( $self->{reqs}, 'DEFAULT', $self->{oids}, $self->{exclreqs} );

  # did we match a skip table request? Does this make sense for DEFAULT?
  return 0 if $skip;

  if ( $req )
  {
    $self->match_req( $req );
    return 1;
  }

  # 3. if no DEFAULT, no match

  0;
}

#pod =method match_req
#pod
#pod =cut

sub match_req
{
  my ( $self, $req ) = @_;

  if ( $req->{class} )
  {
#    no strict 'refs';
    my $new = $req->{new};
    $self->{obj} = $req->{class}->$new( $req->{id}, $req->{udata} );
  }
  elsif ( $req->{obj} )
  {
    $self->{obj} = $req->{obj};
  }

  $self->{process} = 1;
  $self->{req} = $req;
  $self->{req}{match}++;
}


#pod =method callback
#pod
#pod =cut

# generic call back interface.  handle method calls as well as
# subroutine calls.
sub callback
{
  my $self = shift;
  my $method = shift;

  return unless
    defined $self->{req} && exists $self->{req}->{$method};

  my $req = $self->{req};
  my $call = $req->{$method};

  if ( 'CODE' eq ref $call )
  {
    $call->( $self->{id}, @_, $req->{udata} );
  }
  else
  {
    # if the object was destroyed before we get here (if it
    # was created by us and thus was destroyed before us if
    # there was an error), we can't call a method
    $self->{obj}->$call( $self->{id}, @_, $req->{udata} )
      if defined $self->{obj};
  }
}


# handle <th>

#pod =method start_header
#pod
#pod =cut

sub start_header
{
  my $self = shift;
  my ( undef, $line ) = @_;

  $self->{in_hdr}++;
  $self->{prev_hdr}++;
  $self->{hdr_line} = $line;
  $self->start_column( @_ );
}


# handle </th>

#pod =method end_header
#pod
#pod =cut

sub end_header
{
  my $self = shift;
  $self->end_column();
}

# handle <td>
#pod =method start_column
#pod
#pod =cut

sub start_column
{
  my $self = shift;
  my ( $attr, $line ) =  @_;

  # end last column if not explicitly ended. perform check here
  # to avoid extra method call
  $self->end_column() if defined $self->{col};

  # we really shouldn't be here if a row hasn't been started
  unless ( defined $self->{row} )
  {
    $self->callback( 'warn', $self->{id}, $line,
                     "<td> or <th> without <tr> at line $line\n" );
    $self->start_row( {}, $line );
  }

  # even weirder.  if the last row was a header we have to process it now,
  # rather than waiting until the end of this row, as there might be
  # a table in one of the cells in this row and if the enclosing table
  # was using a column match/re, we won't match it's header until after
  # the enclosed table is completely parsed.  this is bad, as it may
  # grab a match (if there's no multimatch) meant for the enclosing table.

  # if we're one row past the header, we're done with the header
  $self->finish_header()
    if ! $self->{in_hdr} && $self->{prev_hdr};

  $self->{col} = { attr =>  { %$attr}  };
  $self->{col}{attr}{colspan} ||= 1;
  $self->{col}{attr}{rowspan} ||= 1;
}

# handle </td>

#pod =method end_column
#pod
#pod =cut

sub end_column
{
  my $self = shift;

  return unless defined $self->{col};

  $self->{col}{text} = defined $self->{text} ? $self->{text} : '' ;

  push @{$self->{row}}, $self->{col};

  $self->{col} = undef;
  $self->{text} = undef;
}

#pod =method start_row
#pod
#pod =cut

sub start_row
{
  my $self = shift;
  my ( $attr, $line ) = @_;

  # end last row if not explicitly ended
  $self->end_row();

  $self->{row} = [];
  $self->{line} = $line;
}


#pod =method end_row
#pod
#pod =cut

sub end_row
{
  my $self = shift;

  return unless defined $self->{row};

  # perhaps an unfinished row. first finish column
  $self->end_column();

  # if we're in a header, deal with overlapping cells differently
  # then if we're in the data section
  if ( $self->{in_hdr} )
  {

    my $cn = 0;
    foreach my $col ( @{$self->{row}} )
    {
      # do this just in case there are newlines and we're concatenating
      # column names later on.  causes strange problems.  besides,
      # column names should be regular
      $col->{text} =~ s/^\s+//;
      $col->{text} =~ s/\s+$//;

      # need to find the first undefined column
      $cn++ while defined $self->{hdr}[$cn][$self->{hdr_row}];

      # note that header is stored as one array per column, not row!
      for ( my $cnn = 0 ; $cnn < $col->{attr}{colspan} ; $cnn++, $cn++ )
      {
        $self->{hdr}[$cn] ||= [];
        $self->{hdr}[$cn][$self->{hdr_row}] = $col->{text};

        # put empty placeholders in the rest of the rows
        for ( my $rnn = 1 ; $rnn < $col->{attr}{rowspan} ; $rnn++ )
        {
          $self->{hdr}[$cn][$rnn + $self->{hdr_row}] = '';
        }
      }
    }

    $self->{hdr_row}++;
  }
  else
  {
    my $cn = 0;
    foreach my $col ( @{$self->{row}} )
    {
      # need to find the first undefined column
      $cn++ while defined $self->{data}[0][$cn];

      for ( my $cnn = 0 ; $cnn < $col->{attr}{colspan} ; $cnn++, $cn++ )
      {
        for ( my $rnn = 0 ; $rnn < $col->{attr}{rowspan} ; $rnn++ )
        {
          $self->{data}[$rnn] ||= [];
          $self->{data}[$rnn][$cn] = $col->{text};
        }
      }
    }
  }

  # if we're one row past the header, we're done with the header
  $self->finish_header()
    if ! $self->{in_hdr} && $self->{prev_hdr};

  # output the data if we're not in a header
  $self->callback( 'row', $self->{line},
                   fix_texts( $self->{req}, shift @{$self->{data}} ) )
      unless $self->{in_hdr};

  $self->{in_hdr} = 0;
  $self->{row} = undef;
}

# collect the possible multiple header rows into one array and
# send it off

#pod =method finish_header
#pod
#pod =cut

sub finish_header
{
  my $self = shift;

  return unless $self->{hdr};

  my @header = map { join( ' ', grep { defined $_ && $_ ne '' } @{$_}) }
                        @{ $self->{hdr} };

  # if we're trying to match header columns, check that here.
  if ( defined $self->{req} )
  {
    fix_texts( $self->{req}, \@header );
    $self->callback( 'hdr',  $self->{hdr_line}, \@header );
  }

  else
  {
    if ( $self->match_hdr( @header ) )
    {
      # haven't done this callback yet...
      $self->callback( 'start', $self->{start_line} );

      fix_texts( $self->{req}, \@header );
      $self->callback( 'hdr',  $self->{hdr_line}, \@header );
    }

    # no match.  reach up to the controlling parser and turn off
    # processing of this table. this is kind of kludgy!
    else
    {
      $self->{parser}->process(0);
    }
  }


  $self->{hdr} = undef;
  $self->{prev_hdr} = undef;
  $self->{hdr_row} = 0;
}

DESTROY
{
  my $self = shift;

  # if we're actually parsing this table, do something.
  if ( $self->{process} )
  {
    # just in case
    $self->end_row();

    # just in case there's no table body
    $self->finish_header();

    $self->callback( 'end', $self->{line} );
  }
}

#pod =method fix_texts
#pod
#pod =cut

sub fix_texts
{
  my ( $req, $texts  ) = @_;

  for ( @$texts )
  {
    local $HTML::Entities::entity2char{nbsp} =
      $HTML::Entities::entity2char{nbsp};

    $HTML::Entities::entity2char{nbsp} = ' '
      if $req->{DecodeNBSP};

    chomp $_
      if $req->{Chomp};

    HTML::Entities::decode_entities( $_ )
      if $req->{Decode};


    if ( $req->{Trim} )
    {
      s/^\s+//;
      s/\s+$//;
    }
  }

  $texts;
}

#pod =method text
#pod
#pod =cut

sub text
{
  my $self = shift;

  $self->{text} = shift;
}

#pod =method id
#pod
#pod =cut

sub id  { $_[0]->{id} }

#pod =method ids
#pod
#pod =cut

sub ids { $_[0]->{ids} }


#pod =method process
#pod
#pod =cut

sub process { $_[0]->{process} }

1;

#
# This file is part of HTML-TableParser
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

HTML::TableParser::Table - support class for HTML::TableParser

=head1 VERSION

version 0.43

=head1 DESCRIPTION

This class is used to keep track of information related to a table and
to create the information passed back to the user callbacks.  It is in
charge of marshalling the massaged header and row data to the user
callbacks.

An instance is created when the controlling TableParser class finds a
C<<table> tag.  The object is given an id based upon which table it is
to work on.  Its methods are invoked from the TableParser callbacks
when they run across an appropriate tag (C<tr>, C<th>, C<td>).  The
object is destroyed when the matching C</table> tag is found.

Since tables may be nested, multiple B<HTML::TableParser::Table>
objects may exist simultaneously.  B<HTML::TableParser> uses two
pieces of information held by this class -- ids and process.  The
first is an array of table ids, one element per level of table
nesting.  The second is a flag indicating whether this table is being
processed (i.e. it matches a requested table) or being ignored.  Since
B<HTML::TableParser> uses the ids information from an existing table
to initialize a new table, it first creates an empty sentinel (place
holder) table (by calling the B<HTML::TableParser::Table> constructor
with no arguments).

The class handles missing C</tr>, C</td>, and C</th> tags.  As such
(especially when handling multi-row headers) user callbacks may
be slightly delayed (and data cached).  It also handles rows
with overlapping columns

=head1 METHODS

=head2 new

=head2 match_id

=head2 req_match_id

=head2 req_match_cols

=head2 match_hdr

=head2 match_req

=head2 callback

=head2 start_header

=head2 end_header

=head2 start_column

=head2 end_column

=head2 start_row

=head2 end_row

=head2 finish_header

=head2 fix_texts

=head2 text

=head2 id

=head2 ids

=head2 process

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-TableParser> or by
email to
L<bug-HTML-TableParser@rt.cpan.org|mailto:bug-HTML-TableParser@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/html-tableparser>
and may be cloned from L<git://github.com/djerius/html-tableparser.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<HTML::TableParser|HTML::TableParser>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =head1 DESCRIPTION
#pod
#pod This class is used to keep track of information related to a table and
#pod to create the information passed back to the user callbacks.  It is in
#pod charge of marshalling the massaged header and row data to the user
#pod callbacks.
#pod
#pod An instance is created when the controlling TableParser class finds a
#pod C<<table> tag.  The object is given an id based upon which table it is
#pod to work on.  Its methods are invoked from the TableParser callbacks
#pod when they run across an appropriate tag (C<tr>, C<th>, C<td>).  The
#pod object is destroyed when the matching C</table> tag is found.
#pod
#pod Since tables may be nested, multiple B<HTML::TableParser::Table>
#pod objects may exist simultaneously.  B<HTML::TableParser> uses two
#pod pieces of information held by this class -- ids and process.  The
#pod first is an array of table ids, one element per level of table
#pod nesting.  The second is a flag indicating whether this table is being
#pod processed (i.e. it matches a requested table) or being ignored.  Since
#pod B<HTML::TableParser> uses the ids information from an existing table
#pod to initialize a new table, it first creates an empty sentinel (place
#pod holder) table (by calling the B<HTML::TableParser::Table> constructor
#pod with no arguments).
#pod
#pod The class handles missing C</tr>, C</td>, and C</th> tags.  As such
#pod (especially when handling multi-row headers) user callbacks may
#pod be slightly delayed (and data cached).  It also handles rows
#pod with overlapping columns
