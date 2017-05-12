# --8<--8<--8<--8<--
#
# Copyright (C) 2014 Smithsonian Astrophysical Observatory
#
# This file is part of IPC::PrettyPipe
#
# IPC::PrettyPipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package IPC::PrettyPipe::Stream::Utils;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw[ parse_spec ];


sub parse_spec {

    my $op = shift;

    # parse stream operator; shell syntax (similarity to IPC::Run's
    # syntax is no coincidence)

    # for consistency, N is always the descriptor which needs to
    # be opened or dup'ed to. M is never touched.

    $op =~ /^(?:
    # <, N<
    # >, N>
    # >>, N>>

      (?'redirect'
          (?'N' \d+ (?!<<) )?  # don't match N<<
          (?'Op'
              (?: [<>]{1,2} )
          )
       )

    # >&, &>
    | (?'redirect_stdout_stderr'
          (?'Op' >& | &> )
      )

    # N<&-
    | (?'close'
          (?'N'  \d+ )
          (?'Op' <&  )
          (?'M'  -   )
       )

    # M<&N
    | (?'dup'
          (?'M'  \d+ )
          (?'Op' <&  )
          (?'N'  \d+ )
      )

    # N>&M
    | (?'dup'
          (?'N'  \d+ )
          (?'Op' >&  )
          (?'M'  \d+ )
      )

      )$/x;

    # force a copy of the hash; it's magical and a simple return
    # of the elements doesn't work.
    my %opc = map { $_ => $+{$_} } grep { exists $+{$_} } qw[ N M Op ];

    ( $opc{type} )
      = grep { defined $+{$_} } qw[ redirect redirect_stdout_stderr close dup ];

    # fill in default value for N for stdin & stdout
    $opc{N} = substr( $opc{Op}, 0, 1 ) eq '<' ? 0 : 1
      if $+{redirect} && !defined $opc{N};

    $opc{param}++
      if $+{redirect} || $+{redirect_stdout_stderr};

    return \%opc;
}

1;

__END__

=head1 NAME

B<IPC::PrettyPipe::Stream::Utils> - support utilities for streams

=head1 SYNOPSIS

  use IPC::PrettyPipe::Stream::Utils qw[ parse_spec ];

  $opc = parse_spec( $op );

=head1 DESCRIPTION

=head2 Stream Specification

A stream specification is a string which may take one of the forms in
the I<Spec> column:

  Spec    Op    Mode    File    Function
  ----    ---  ----    ----    -----------------------
  <       <     I       y       read from file via fd 0
  <N      <     I       y       read from file via fd N
  >       >     O       y       write to file via fd 1
  >N      >     O       y       write to file via fd N

  >&      >&    O       n       redirect fd 2 to fd 1
  &>      &>    O       n       redirect fd 2 to fd 1

  N<&-    <&-   ?       n       close fd N

  M<&N    <&    I       n       dup fd M as fd N
  N>&M    >&    O       n       dup fd M as fd N

 where

=over

=item *

I<M> and I<N> are integers indicating file descriptors

=item *

C<Mode> indicates input (I<I>), output (I<O>), or not applicable (I<?>)

=item *

C<File> indicates whether an additional parameter with a file name is
required.

=back

Any resemblance to stream operators used by B<L<IPC::Run>> is purely
non-coincidental.

=head1 FUNCTIONS

B<IPC::PrettyPipe::Stream::Utils> exports the following functions upon
request:

=over

=item B<parse_spec>

  $components = parse_spec( $spec )

Parse a stream specification into components I<Op>, I<N>, and I<M>.
Returns a hashref with the information indexed by the component names.

If the specification indicates that additional parameters are required
(such as the name of a file to be read or written to), the key
C<param> will be set.

=back


=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>
