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


# my $catalogue = Math::Values::OeisCatalogue->new(exclude_files=>1);
#



package Math::NumSeq::OEIS::Catalogue;
use 5.004;
use strict;
use List::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

use Module::Pluggable require => 1;
my @plugins = sort __PACKAGE__->plugins;
### @plugins

use vars '$VERSION';
$VERSION = 74;

# sub seq_to_num {
#   my ($class, $num) = @_;
# }


sub anum_to_info {
  my ($class, $anum) = @_;
  ### Catalogue anum_to_info(): $anum

  foreach my $plugin (@plugins) {
    ### $plugin
    if (my $info = $plugin->anum_to_info($anum)) {
      return $info;
    }
  }
  return undef;
}

sub anum_list {
  my ($class) = @_;
  my %ret;
  foreach my $plugin (@plugins) {
    ### $plugin
    foreach my $info (@{$plugin->info_arrayref}) {
      $ret{$info->{'anum'}} = 1;
    }
  }
  my @ret = sort {$a<=>$b} keys %ret;
  return @ret;
}

sub _method_apply {
  my $acc = shift;
  my $method = shift;
  ### plugin anums: map {$_->$method(@_)} @plugins
  return $acc->(grep {defined} map {$_->$method(@_)} @plugins);
}
sub anum_after {
  my ($class, $after_anum) = @_;
  ### Catalogue anum_after(): $after_anum

  _method_apply (\&List::Util::minstr, 'anum_after', $after_anum);
}
sub anum_before {
  my ($class, $before_anum) = @_;
  _method_apply (\&List::Util::maxstr, 'anum_before', $before_anum);
}

sub anum_first {
  my ($class) = @_;
  _method_apply (\&List::Util::minstr, 'anum_first');
}
sub anum_last {
  my ($class) = @_;
  _method_apply (\&List::Util::maxstr, 'anum_last');
}


# sub anum_to_class {
#   my ($class, $anum) = @_;
#   ### anum_to_class(): @_
#   my @ret;
#   foreach my $plugin (@plugins) {
#     ### $plugin
#     my $href = $plugin->anum_to_class_hashref;
#     if (my $aref = $href->{$anum}) {
#       return @$aref;
#     }
#   }
#   return;
# }
# 
# sub _file_anum_list {
#   my ($class) = @_;
#   ### anum_list()
#   my %ret;
#   foreach my $plugin (@plugins) {
#     ### $plugin
#     my $href = $plugin->anum_to_class_hashref;
#     %ret = (%ret, %$href);
#   }
#   return sort keys %ret;
# }


1;
__END__

=for stopwords Ryde Math-NumSeq NumSeq OEIS

=head1 NAME

Math::NumSeq::OEIS::Catalogue -- available A-numbers

=head1 SYNOPSIS

 use Math::NumSeq::OEIS::Catalogue;
 my $anum = Math::NumSeq::OEIS::Catalogue->anum_first;
 my $anum_next = Math::NumSeq::OEIS::Catalogue->anum_after($anum);

=head1 DESCRIPTION

This module lists the A-numbers available for C<Math::NumSeq::OEIS>.  It
includes those available from NumSeq module code and those available from
files.

A-numbers are handled as strings like "A000032".  Six digits is usual,
though rumour has it the plan is for seven digits like "A1000000" when the
millionth sequence is reached.

Add-on distributions can extend the catalogue by creating a plugin module.
See L<Math::NumSeq::OEIS::Catalogue::Plugin> for details.

=head1 FUNCTIONS

=over

=item C<$anum = Math::NumSeq::OEIS::Catalogue-E<gt>anum_first()>

=item C<$anum = Math::NumSeq::OEIS::Catalogue-E<gt>anum_last()>

Return the first, or last, A-number available.

=item C<$anum = Math::NumSeq::OEIS::Catalogue-E<gt>anum_before ($anum)>

=item C<$anum = Math::NumSeq::OEIS::Catalogue-E<gt>anum_after ($anum)>

Return the A-number before, or after, a given C<$anum>.  Return C<undef> if
there's no more A-numbers in the respective direction.

=back

=head1 SEE ALSO

L<Math::NumSeq::OEIS>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-numseq/index.html

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

