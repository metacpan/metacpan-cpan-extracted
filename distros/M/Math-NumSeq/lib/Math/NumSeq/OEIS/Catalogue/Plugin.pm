# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::OEIS::Catalogue::Plugin;
use 5.004;
use strict;

use vars '$VERSION';
$VERSION = 74;

# uncomment this to run the ### lines
#use Smart::Comments;

my %anum_to_info_hashref;
sub anum_to_info_hashref {
  my ($class) = @_;
  ### anum_to_info_hashref(): $class
  return ($anum_to_info_hashref{$class} ||=
          { map { $_->{'anum'} => $_ } @{$class->info_arrayref} });
}

sub anum_to_info {
  my ($class, $anum) = @_;
  foreach my $anum ($anum,
                    # A0123456 shortened to A123456
                    ($anum =~ /A0(\d{6})/ ? "A$1" : ())) {
    return ($class->anum_to_info_hashref->{$anum} || next);
  }
}

sub anum_after {
  my ($class, $after_anum) = @_;
  ### $after_anum
  my $ret;
  foreach my $info (@{$class->info_arrayref}) {
    ### after info: $info
    if ($info->{'anum'} gt $after_anum
        && (! defined $ret || $ret gt $info->{'anum'})) {
      $ret = $info->{'anum'};
    }
  }
  return $ret;
}
sub anum_before {
  my ($class, $before_anum) = @_;
  ### $before_anum
  my $ret;
  foreach my $info (@{$class->info_arrayref}) {
    if ($info->{'anum'} lt $before_anum
        && (! defined $ret || $ret lt $info->{'anum'})) {
      $ret = $info->{'anum'};
    }
  }
  return $ret;
}

sub anum_first {
  my ($class) = @_;
  return $class->anum_after ('A000000');
}
sub anum_last {
  my ($class) = @_;
  return $class->anum_before('A9999999'); # 7-digits
}

1;
__END__

=for stopwords Ryde Math-NumSeq pluggable arrayref hashref OEIS

=head1 NAME

Math::NumSeq::OEIS::Catalogue::Plugin -- pluggable catalogue extensions

=for test_synopsis my @ISA

=head1 SYNOPSIS

 package Math::NumSeq::OEIS::Catalogue::Plugin::MySeqs;
 use Math::NumSeq::OEIS::Catalogue::Plugin;
 @ISA = 'Math::NumSeq::OEIS::Catalogue::Plugin';
 # ...

=head1 DESCRIPTION

Catalogue plugins are loaded and used by C<Math::NumSeq::OEIS::Catalogue>.
A plug allows an add-on distribution or semi-independent components to
declare which OEIS A-numbers they implement and what C<NumSeq> sequence
parameters can create the sequence.

This is an internal part of C<Math::NumSeq::OEIS::Catalogue> not yet meant
for general use yet, but the intention is for add-on sequences to declare
themselves in the A-number catalogue.

A plugin "Foo" should sub-class C<Math::NumSeq::OEIS::Catalogue::Plugin>, so

    package Math::NumSeq::OEIS::Catalogue::Plugin::Foo;
    use strict;
    use vars '@ISA';
    use Math::NumSeq::OEIS::Catalogue::Plugin;
    @ISA = ('Math::NumSeq::OEIS::Catalogue::Plugin');

A set of A-numbers can be declared with an arrayref of information records
(a hashref each).  For example

    use constant info_arrayref =>
      [
       { anum  => 'A999998',
         class => 'Math::NumSeq::Foo',
       },
       { anum  => 'A999999',
         class => 'Math::NumSeq::Foo',
         parameters => [ param_a => 123, param_b => 456 ],
       },
       # ...
      ];

This means A999998 is implemented by class C<Math::NumSeq::Foo> as

    $seq = Math::NumSeq::Foo->new ();

and A999999 likewise but with additional parameters

    $seq = Math::NumSeq::Foo->new (param_a => 123,
                                   param_b => 456);

=head1 SEE ALSO

L<Math::NumSeq::OEIS::Catalogue>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-numseq/index.html

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut

