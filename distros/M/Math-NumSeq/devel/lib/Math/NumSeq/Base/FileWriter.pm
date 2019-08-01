# Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::Base::FileWriter;
use 5.006;
use strict;
use warnings;
use File::Temp;

use Math::NumSeq::Base::File;

use vars '$VERSION';
$VERSION = 73;

# uncomment this to run the ### lines
#use Smart::Comments;

# $File::Temp::KEEP_ALL = 1;

sub new {
  my $class = shift;
  ### Values FileWriter new(): @_

  my $self = bless { @_ }, $class;
  my $hi = $self->{'hi'};

  my $package = $self->{'package'};
  my $options = $self->{'options'};
  if (defined $options) {
    $options = "--$options";
  } else {
    $options = '';
  }
  my $key = "$package--$options";

  my $fh;
  if (my $filetemp = $Math::NumSeq::Base::File::filetemp{$key}) {
    my $filename = $filetemp->filename;
    ### existing file: $filename
    open $fh, '+>', $filename or die;
  } else {
    my $basename = $key;
    $basename =~ s/^Math::NumSeq:://;
    $basename =~ tr/:/_/;
    $fh = $Math::NumSeq::Base::File::filetemp{$key}
      = File::Temp->new (TEMPLATE => "${basename}_XXXXXX",
                         SUFFIX => '.data',
                         TMPDIR => 1);
    ### tempfile: $fh->filename
  }
  $self->{'fh'} = $fh;
  print $fh "-1\n";  # pending true $hi in done()

  my $bytes = ($hi+1 + 7) >> 3;
  seek $fh, 32+$bytes, 0 or die;
  print $fh "x" or die;
  return $self;
}

sub write_n {
  my ($self, $n) = @_;
  ### Values FileWriter write_n(): $n
  my $fh = $self->{'fh'};

  my $pos = 32 + ($n>>3);
  ### $pos
  seek $fh, $pos, 0 or die;
  read $fh, my $buf, 1 or die;
  vec ($buf, $n&7,1) = 1;
  seek $fh, $pos, 0 or die;
  print $fh $buf or die;

  seek $fh, 0, 2 or die;
  print $fh "$n\n" or die;
}

sub done {
  my ($self) = @_;
  if (my $fh = delete $self->{'fh'}) {
    seek $fh, 0, 0 or die;
    print $fh "$self->{'hi'}\n" or die;
    close $fh or die;
  }
}

sub DESTROY {
  my ($self) = @_;
  if (my $fh = delete $self->{'fh'}) {
    close $fh or die;
  }
}

1;
__END__
