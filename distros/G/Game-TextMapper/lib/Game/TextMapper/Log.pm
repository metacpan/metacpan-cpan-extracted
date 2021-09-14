# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::TextMapper::Log - a log singleton

=head1 SYNOPSIS

    use Game::TextMapper::Log;
    my $log = Game::TextMapper::Log->get();
    $log->debug("Test");

=head1 DESCRIPTION

This allows multiple modules to use the same logger. If the log level or path
are changed by one of them, the change affects all the modules since they share
the same logger instance.

This uses L<Mojo::Log>.

=head1 SEE ALSO

L<Mojo::Log>

=cut

package Game::TextMapper::Log;
use Mojo::Log;

my $log = Mojo::Log->new;

sub get {
  return $log;
}

1;
