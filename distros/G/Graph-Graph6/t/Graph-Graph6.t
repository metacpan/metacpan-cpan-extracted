#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 117;

require Graph::Graph6;
my $filename = 'Graph-Graph6-t.tmp';

#------------------------------------------------------------------------------
{
  my $want_version = 8;
  ok ($Graph::Graph6::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Graph6->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Graph6->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Graph6->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# _number_to_string()

ok (Graph::Graph6::_number_to_string(30),
    chr(93));

ok (Graph::Graph6::_number_to_string(12345),
    chr(126).chr(66).chr(63).chr(120));

{
  # 460175067 = octal 3333333333  < 2^29
  my $want = chr(126).chr(126)
    . chr(63).chr(90).chr(90) . chr(90).chr(90).chr(90);
  ok (Graph::Graph6::_number_to_string(460175067),
      $want);
  require Math::BigInt;
  ok (Graph::Graph6::_number_to_string(Math::BigInt->new('460175067')),
      $want);
}

{
  # 2147483647 = 2^31 - 1
  my $want = chr(126).chr(126)
    . chr(63+1).chr(126).chr(126) . chr(126).chr(126).chr(126);
  ok (Graph::Graph6::_number_to_string(2147483647),
      $want);
  require Math::BigInt;
  ok (Graph::Graph6::_number_to_string(Math::BigInt->new('2147483647')),
      $want);
}

{
  # 2^36 - 1

  my $power = 1;
  $power <<= 36;
  $power -= 1;
  my $have_36bit_UV = ($power >= 3 * 2.0**34);
  my $want = chr(126).chr(126)
    . chr(126).chr(126).chr(126) . chr(126).chr(126).chr(126);
  my $got = Graph::Graph6::_number_to_string($power);

  skip ($have_36bit_UV ? 0 : 'due to UV less than 36 bits',
        $got, $want,
        '2^36-1');

  ok (Graph::Graph6::_number_to_string(Math::BigInt->new('68719476735')),
      $want,
      '2^36-1');

  $power = Math::BigInt->new(1)->blsft(36) - 1;
  $got = Graph::Graph6::_number_to_string($power);
  # Math::BigInt which came with Perl 5.6.0 didn't have an >> operator so
  # beware of it being a 32-bit truncation
  my $have_bigint_good_rshift = (($power >> 32) == 15);
  skip ($have_bigint_good_rshift ? 0 : 'due to Math::BigInt >>32 not right',
        $got, $want,
        '2^36-1');
}

#------------------------------------------------------------------------------
# read_graph()

sub aref_stringize {
  my ($aref) = @_;
  if (ref $aref eq 'ARRAY') {
    return '['.join(',', map {aref_stringize($_)} @$aref).']';
  } else {
    return "$aref";
  }
}

{
  # formats.txt digraph6 example
  my $str = chr(38).chr(68).chr(73).chr(63).chr(65).chr(79).chr(63)."\n";
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str  => $str,
                                      num_vertices_func => sub {
                                        $num_vertices = $_[0];
                                      },
                                      edge_func => sub {
                                        push @edges, [@_];
                                      });
  ok ($ret, 1);
  ok ($num_vertices, 5);
  ok (aref_stringize(\@edges), '[[0,2],[0,4],[3,1],[3,4]]');
}
{
  # formats.txt graph6 example
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str  => chr(68).chr(81).chr(99)."\n",
                                      num_vertices_func => sub {
                                        $num_vertices = $_[0];
                                      },
                                      edge_func => sub {
                                        push @edges, [@_];
                                      });
  ok ($ret, 1);
  ok ($num_vertices, 5);
  ok (aref_stringize(\@edges), '[[0,2],[1,3],[0,4],[3,4]]');
}
{
  # formats.txt sparse6 example
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str              => ':Fa@x^',
                                      num_vertices_ref => \$num_vertices,
                                      edge_aref        => \@edges);
  ok ($ret, 1);
  ok ($num_vertices, 7);
  ok (aref_stringize(\@edges), '[[0,1],[0,2],[1,2],[5,6]]');
}

{
  # bad, croaking
  my $returned = 0;
  eval {
    Graph::Graph6::read_graph(str => '0');
    $returned = 1;
  };
  ok ($returned, 0);
}

# bad, with error_func returning
foreach my $elem (['0', '0'],
                  ['&&', '&'],          # doubled digraph6 "&"
                  ['&&DI?AO?', '&'],    # doubled digraph6 "&" otherwise valid
                  [':&Fa@x^', '&'],     # bad digraph6 "&" after sparse6
                  [':Fa&@x^', '&'],     # bad digraph6 "&" in middle of sparse6
                 ) {
  my ($str, $bad_char) = @$elem;
  my $error_func_called = 0;
  my $error_message = '';
  my $ret = Graph::Graph6::read_graph(str => $str,
                                      error_func => sub {
                                        $error_message = join('',@_);
                                        $error_func_called = 1;
                                      });
  ok ($ret, undef, "str \"$str\"");
  ok ($error_func_called, 1);
  ok ($error_message, "Unrecognised character: $bad_char");
}

{
  # no such filename
  my $error_func_called = 0;
  my $error_message = '';
  my $ret = Graph::Graph6::read_graph(filename => 'nosuchfilename',
                                      error_func => sub {
                                        $error_message = join('',@_);
                                        $error_func_called = 1;
                                      });
  ok ($ret, undef);
  ok ($error_func_called, 1);
  ok ($error_message =~ /^Cannot open/, 1);
}
{
  # unexpected eof ~
  my $error_func_called = 0;
  my $error_message = '';
  my $ret = Graph::Graph6::read_graph(str => '~',
                                      error_func => sub {
                                        $error_message = join('',@_);
                                        $error_func_called = 1;
                                       });
  ok ($ret, undef);
  ok ($error_func_called, 1);
  ok ($error_message, "Unexpected EOF");
}

{
  # graph6 dodgy padding, doesn't become edges
  my $str = chr(63+2) . chr(63+63);
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str              => $str,
                                      num_vertices_ref => \$num_vertices,
                                      edge_aref        => \@edges);
  ok ($ret, 1);
  ok ($num_vertices, 2);
  ok (aref_stringize(\@edges), '[[0,1]]');
}
{
  # skip blank lines before graph
  my $str = "\n\n\n".chr(63+0);
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str              => $str,
                                      num_vertices_ref => \$num_vertices,
                                      edge_aref        => \@edges);
  ok ($ret, 1);
  ok ($num_vertices, 0);
  ok (aref_stringize(\@edges), '[]');
}
{
  # trailng \r
  my $str = "\n\n\n".chr(63+0)."\r\n";
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str              => $str,
                                      num_vertices_ref => \$num_vertices,
                                      edge_aref        => \@edges);
  ok ($ret, 1);
  ok ($num_vertices, 0);
  ok (aref_stringize(\@edges), '[]');
}
{
  # some newlines then eof
  my $str = "\n\n\n";
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str              => $str,
                                      num_vertices_ref => \$num_vertices,
                                      edge_aref        => \@edges);
  ok ($ret, 0);
}
{
  # bad header
  my $str = ">>grXYZ";
  my $error_message;
  my $ret = Graph::Graph6::read_graph(str => $str,
                                      error_func => sub {
                                        $error_message = join('',@_);
                                      });
  ok ($ret, undef);
  ok ($error_message, "Incomplete header: >>grX");
}
{
  # bad header
  my $str = ">#";
  my $error_message;
  my $ret = Graph::Graph6::read_graph(str => $str,
                                      error_func => sub {
                                        $error_message = join('',@_);
                                      });
  ok ($ret, undef);
  ok ($error_message, "Incomplete header: >#");
}

{
  # \my per POD
  my $ret = Graph::Graph6::read_graph(str              => ':Fa@x^',
                                      num_vertices_ref => \my $num_vertices,
                                      edge_aref        => \my @edges);
  ok ($ret, 1);
  ok ($num_vertices, 7);
  ok (aref_stringize(\@edges), '[[0,1],[0,2],[1,2],[5,6]]');
}

{
  # from filename
  {
    my $fh;
    (open $fh, '>', $filename
     and print $fh ':Fa@x^',"\n"
     and close $fh)
      or die "Cannot write $filename; $!";
  }
  my $ret = Graph::Graph6::read_graph(filename         => $filename,
                                      num_vertices_ref => \my $num_vertices,
                                      edge_aref        => \my @edges);
  ok ($ret, 1);
  ok ($num_vertices, 7);
  ok (aref_stringize(\@edges), '[[0,1],[0,2],[1,2],[5,6]]');
}
{
  # from fh
  {
    my $fh;
    (open $fh, '>', $filename
     and print $fh ':Fa@x^',"\n"
     and close $fh)
      or die "Cannot write $filename; $!";
  }
  open my $fh, '<', $filename or die "Cannot open $filename: $!";
  my $ret = Graph::Graph6::read_graph(fh               => $fh,
                                      num_vertices_ref => \my $num_vertices,
                                      edge_aref        => \my @edges);
  ok ($ret, 1);
  ok ($num_vertices, 7);
  ok (aref_stringize(\@edges), '[[0,1],[0,2],[1,2],[5,6]]');
}

{
  # sparse6
  # b[i]=1 or b[i]=0 same for setting v when to>=v+2
  #
  foreach my $str (":CoJ\n", ":COJ\n") {
    my @edges;
    my $num_vertices;
    my $ret = Graph::Graph6::read_graph(str              => $str,
                                        num_vertices_ref => \$num_vertices,
                                        edge_aref        => \@edges);
    ok ($ret, 1);
    ok ($num_vertices, 4);
    ok (aref_stringize(\@edges), '[[0,2],[1,2]]');
  }
}

{
  # sparse6
  my $str = ":GoBN_\n";
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str              => $str,
                                      num_vertices_ref => \$num_vertices,
                                      edge_aref        => \@edges);
  ok ($ret, 1);
  ok ($num_vertices, 8);
  ok (aref_stringize(\@edges), '[[0,4],[3,4],[3,4],[0,6]]');
}
{
  # :GoBN_
  # [length 7]
  # 001000 110000 000011 001111 100000
  # round trip:
  #
  # [length 6]
  # 001000 110000 001110 000011

  # sparse6
  my $str = ":GoMB\n";
  my @edges;
  my $num_vertices;
  my $ret = Graph::Graph6::read_graph(str              => $str,
                                      num_vertices_ref => \$num_vertices,
                                      edge_aref        => \@edges);
  ok ($ret, 1);
  ok ($num_vertices, 8);
  ok (aref_stringize(\@edges), '[[0,4],[0,6]]');
}



#------------------------------------------------------------------------------
# write_graph() -- graph6

{
  # formats.txt graph6 example
  my $str;
  my $ret = Graph::Graph6::write_graph(str_ref      => \$str,
                                       num_vertices => 5,
                                       edge_aref => [[0,2],[4,0],[1,3],[3,4]]);
  ok ($ret, 1);
  ok ($str, chr(68).chr(81).chr(99)."\n");
}
{
  # with header
  my $str;
  my $ret = Graph::Graph6::write_graph(header       => 1,
                                       str_ref      => \$str,
                                       num_vertices => 2);
  ok ($ret, 1);
  ok ($str, ">>graph6<<A?\n");
}
{
  # with edge_predicate
  my $str;
  my $ret = Graph::Graph6::write_graph(str_ref      => \$str,
                                       num_vertices => 6,
                                       edge_predicate => sub {
                                         my ($from, $to) = @_;
                                         return $to <= 3;
                                       });
  ok ($ret, 1);
  ok ($str, "E~??\n");
}
{
  # no edges
  my $str;
  my $ret = Graph::Graph6::write_graph(str_ref      => \$str,
                                       num_vertices => 0,
                                      );
  ok ($ret, 1);
  ok ($str, "?\n");
}

{
  # \my per POD
  my $ret = Graph::Graph6::write_graph(str_ref      => \my $str,
                                       num_vertices => 1,
                                      );
  ok ($ret, 1);
  ok ($str, chr(63+1)."\n");
}

{
  # to filename

  my $ret = Graph::Graph6::write_graph(filename     => $filename,
                                       edge_aref    => [[0,1]]);
  ok ($ret, 1);
  my $str;
  {
    my $fh;
    (open $fh, '<', $filename
     and read $fh, $str, 1000
     and close $fh
    ) or die "Cannot read $filename: $!";
  }
  unlink($filename);
  ok ($str, chr(63+2).chr(63+32)."\n");
}

{
  # to fh
  {
    open my $fh, '>', $filename or die "Cannot write $filename: $!";
    my $ret = Graph::Graph6::write_graph(filename     => $filename,
                                         edge_aref    => [[0,1]]);
    ok ($ret, 1);
  }
  my $str;
  {
    my $fh;
    (open $fh, '<', $filename
     and read $fh, $str, 1000
     and close $fh
    ) or die "Cannot read $filename: $!";
  }
  unlink($filename);

  ok ($str, chr(63+2).chr(63+32)."\n");
}


#------------------------------------------------------------------------------
# write_graph() -- sparse6

{
  # formats.txt sparse6 example
  my $str;
  my $ret = Graph::Graph6::write_graph(format       => 'sparse6',
                                       str_ref      => \$str,
                                       num_vertices => 7,
                                       edge_aref => [[0,1],[0,2],[1,2],[5,6]]);
  ok ($ret, 1);
  ok ($str, ":Fa\@x^\n");
}
{
  # with header
  my $str;
  my $ret = Graph::Graph6::write_graph(format       => 'sparse6',
                                       header       => 1,
                                       str_ref      => \$str,
                                       num_vertices => 8);
  ok ($ret, 1);
  ok ($str, ">>sparse6<<:G\n");
}
{
  # with edge_predicate
  my $str;
  my $ret = Graph::Graph6::write_graph(format       => 'sparse6',
                                       str_ref      => \$str,
                                       num_vertices => 31,  # width = 5 bits
                                       edge_predicate => sub {
                                         my ($from, $to) = @_;
                                         return ($from == 0 && $to == 0);
                                       });
  ok ($ret, 1);
  ok ($str, ':'.chr(31+63).chr(63)."\n");
}
{
  # no edges
  my $str;
  my $ret = Graph::Graph6::write_graph(format       => 'sparse6',
                                       str_ref      => \$str,
                                       num_vertices => 0,
                                      );
  ok ($ret, 1);
  ok ($str, ":?\n");
}


#------------------------------------------------------------------------------
# write_graph() provoke some sparse6 padding stuff

{
  my $num_vertices;
  my $edges;
  my $try = sub {
    my ($str) = @_;
    undef $num_vertices;
    $edges = '';
    Graph::Graph6::read_graph(str => $str,
                              num_vertices_func => sub {
                                my ($n) = @_;
                                $num_vertices = $n;
                              },
                              edge_func => sub {
                                my ($from, $to) = @_;
                                $edges .= "$from-$to,";
                              });
  };

  {
    # n=1 with 0-0 self loop
    # : N(1) 0 11111
    $try->(':'.chr(63+1).chr(63+31));
    ok ($num_vertices, 1);
    ok ($edges, '0-0,');
  }

  {
    # n=2 with 0-0 self loop
    # : N(2) 0-0    0-1     1-1
    #             set v=1   + to v=2
    $try->(':'.chr(63+2).chr(63+7));
    ok ($num_vertices, 2);
    ok ($edges, '0-0,');
  }
  {
    # n=2 with 0-0 and 1-1 self loops
    # : N(2) 0-0   1-1    1-1
    #         x=0  + x=1  + to v=2
    $try->(':'.chr(63+2).chr(63+15));
    ok ($num_vertices, 2);
    ok ($edges, '0-0,1-1,');
  }

  {
    # n=4 edge 0-1
    # : N(4) 1-00   1-11
    #        + x=0  + set v=3
    $try->(':'.chr(63+4).chr(63+32+7));
    ok ($num_vertices, 4);
    ok ($edges, '0-1,');
  }
  {
    # n=4 edges 0-2, 1-2
    # : N(4) 0-10    0-00 0-01   0-11
    #        set v=2 edge edge   pad
    # :COJ
    # :CoJ
    $try->(':' . chr(63+4) . chr(63+16) . chr(63+11));
    ok ($num_vertices, 4);
    ok ($edges, '0-2,1-2,');
  }
}

#------------------------------------------------------------------------------
# write_graph() -- digraph6

{
  # formats.txt digraph6 example
  my $str;
  my $ret = Graph::Graph6::write_graph
    (format       => 'digraph6',
     str_ref      => \$str,
     num_vertices => 5,
     edge_aref    => [[0,2], [0,4], [3,1],[3,4]]);
  ok ($ret, 1);
  ok ($str, "&DI?AO?\n");
}

{
  # edge both ways
  my $str;
  my $ret = Graph::Graph6::write_graph
    (format       => 'digraph6',
     str_ref      => \$str,
     num_vertices => 3,
     edge_aref    => [[0,2], [2,0]]);
  ok ($ret, 1);
  ok ($str, "&BG_\n");
}
{
  # edge back only
  my $str;
  my $ret = Graph::Graph6::write_graph
    (format       => 'digraph6',
     str_ref      => \$str,
     num_vertices => 3,
     edge_aref    => [ [2,0]]);
  ok ($ret, 1);
  ok ($str, "&B?_\n");
}


#------------------------------------------------------------------------------
unlink $filename;
exit 0;
