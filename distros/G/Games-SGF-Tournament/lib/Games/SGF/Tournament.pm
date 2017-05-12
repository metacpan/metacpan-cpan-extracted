package Games::SGF::Tournament;

use version; $VERSION = qv(1.0);

use warnings;
use strict;
use Carp;
use CGI qw/ :html /;

sub new {
   my $class = shift;
   my %params = @_;
   $params{sgf_dir} ||= '.';
   $params{base_url} ||= '';
   my %scores;
   my @games;
   undef $/;

   unless (opendir(SGF, $params{sgf_dir})) {
      carp "While opening directory \"$params{sgf_dir}\": $!";
      return undef;
   }
   foreach (grep { /.*\.sgf$/ } readdir SGF) {
      open IN, "$params{sgf_dir}/$_" or next;
      my $sgf_content = <IN>;
      close IN;
      my %game_info = ( file => "$params{base_url}$_" );
      foreach (qw/ RU SZ HA KM PW PB DT TM RE /) {
         if ($sgf_content =~ /$_\[(.*?)\]/) {
            $game_info{$_} = $1;
         } else {
            $game_info{$_} = '?';
         }
      }
      push @games, \%game_info;

      $game_info{RE} =~ /^([BW])\+/o;
      foreach (qw/ B W /) {
         $scores{$game_info{"P$_"}} += $1 eq $_ ? 1:0;
      }
   }
   bless { games => \@games, scores => \%scores }, $class;
}

sub games {
   my $self = shift;
   my @rows = TR(
         th('Game#'),
         th('Black'),
         th('White'),
         th('Setup'),
         th('Date'),
         th('Result')
   );
   my $i;

   foreach (sort { $a->{DT} cmp $b->{DT} } @{ $self->{games} }) {
      push @rows, TR(
         td(a({ -href => $_->{file} }, ++$i)),
         td($_->{PB}),
         td($_->{PW}),
         td("$_->{RU}/$_->{SZ}/$_->{HA}/$_->{KM}/$_->{TM}"),
         td($_->{DT}),
         td($_->{RE})
      );
   }

   return table({ -border => 1 },
      caption('Table of played games'),
      @rows
   );
}

sub scores {
   my $self = shift;
   my @rows = TR(
      th('Pos#'),
      th('Name'),
      th('Score')
   );
   my $i;

   foreach (sort { $self->{scores}->{$b} <=> $self->{scores}->{$a} }
      (keys %{ $self->{scores} })
   ) {
      push @rows, TR(
         td(++$i),
         td($_),
         td($self->{scores}->{$_})
      );
   }

   return table({ -border => 1 },
      caption('Scoreboard'),
      @rows
   );
}

1;
__END__

=head1 NAME

B<Games::SGF::Tournament> - Tournament statistics generator


=head1 VERSION

This document describes B<Games::SGF::Tournament> version 1.0


=head1 SYNOPSIS

    use CGI qw / :html /;
    use Games::SGF::Tournament;
    my $t = Games::SGF::Tournament->new();
    print html(body($t->score()));

=head1 DESCRIPTION

Smart Go Format (SGF) is a file format used to store game records of
two player board games. This module used to collect tournament
information from a set of SGF files and produce statistic HTML tables
for creating WWW tournament pages.


=head1 INTERFACE

B<Games::SGF::Tournament> is a class with following methods:

=head2 new

The constructor. Optional parameters are:

=over

=item I<sgf_dir>

Path to SGF files representing the tournament. Default: current directory.

=item I<base_url>

Base URL to prefix file names of SGF files. Default: empty string.

=back

=head2 games

Returns a table of played games in chronological order with hyperlinks
to SGF files.

=head2 scores

Returns a table of players descending by score.


=head1 DIAGNOSTICS

=over

=item C<While opening directory...>

Can't open given I<sgf_dir> for reading. Probably it doesn't exist or have inappropriate permissions, see OS error message.

=back


=head1 CONFIGURATION AND ENVIRONMENT

B<Games::SGF::Tournament> requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<version>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Class is tested only on the game of Go. Suggestions about other games 
are welcome, and especially about ties processing.

If two or more players have same score, they position will be
unpredictable. Usually, such a problem on tournaments have to be
resolved with the help of other methods os scoring: SOS and so
on. That is not implemented yet.

This is my very first object-oriented Perl module, and i will 
appreciate any suggestions about OO-style.

Please report any bugs or feature requests through the web interface at
L<http://sourceforge.net/tracker/?group_id=143987>.


=head1 SEE ALSO

L<CGI>, Smart Go Format: L<http://www.red-bean.com/sgf/>.


=head1 AUTHOR

Al Nikolov E<lt>alnikolov@narod.ruE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Al Nikolov E<lt>alnikolov@narod.ruE<gt>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
USA


=head1 DISCLAIMER OF WARRANTY

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
