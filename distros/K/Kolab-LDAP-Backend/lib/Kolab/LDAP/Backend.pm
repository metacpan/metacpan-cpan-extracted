package Kolab::LDAP::Backend;

##
##  Copyright (c) 2003  Code Fusion cc
##
##    Writen by Stuart Bingë  <s.binge@codefusion.co.za>
##
##  This  program is free  software; you can redistribute  it and/or
##  modify it  under the terms of the GNU  General Public License as
##  published by the  Free Software Foundation; either version 2, or
##  (at your option) any later version.
##
##  This program is  distributed in the hope that it will be useful,
##  but WITHOUT  ANY WARRANTY; without even the  implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You can view the  GNU General Public License, online, at the GNU
##  Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.
##

use 5.008;
use strict;
use warnings;
use Kolab;
use Kolab::Util;
use vars qw(
    %startup
    %run
    %backends
);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        &load
        &startup
        &run
        %backends
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

sub load
{
    my $p = shift || '';
    my $non_directory = shift;
    my $backend;

    if (!defined $non_directory) {
      $p .= '_' if ($p);
      $backend = $Kolab::config{$p . 'directory_mode'};
    } else {
      $backend = $p;
    }
    return if (exists($backends{$backend}));

    Kolab::log('B', "Loading backend `$backend'");

    unless (eval "require Kolab::LDAP::Backend::$backend") {
        Kolab::log('B', "Backend `$backend' does not exist, exiting", KOLAB_ERROR);
        exit(1);
    }

    $startup{$backend} = \&{'Kolab::LDAP::Backend::' . $backend . '::startup'};
    $run{$backend} = \&{'Kolab::LDAP::Backend::' . $backend . '::run'};

    $backends{$backend} = 1;
}

# shutdown is handled per-module, using signals
sub startup
{
    foreach my $backend (keys %backends) {
        my $func = $startup{$backend};
        unless (eval '&$func') {
            $func = 'Kolab::LDAP::Backend::' . $backend . '::startup';
            Kolab::log('B', "Function `$func' does not exist, exiting", KOLAB_ERROR);
            exit(1);
        }
    }
}

sub run
{
    my $backend = shift || 1;
    return if (!exists($run{$backend}));

    my $func = $run{$backend};
    unless (eval '&$func') {
        $func = 'Kolab::LDAP::Backend::' . $backend . '::run';
        Kolab::log('B', "Function `$func' does not exist, exiting", KOLAB_ERROR);
        exit(1);
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::LDAP::Backend - Perl extension for abstract directory
service usage

=head1 ABSTRACT

  Kolab::LDAP::Backend is basically an interface to the various
  directory service backends that are available.

=head1 AUTHOR

Stuart Bingë, E<lt>s.binge@codefusion.co.zaE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003  Code Fusion cc

This  program is free  software; you can redistribute  it and/or
modify it  under the terms of the GNU  General Public License as
published by the  Free Software Foundation; either version 2, or
(at your option) any later version.

This program is  distributed in the hope that it will be useful,
but WITHOUT  ANY WARRANTY; without even the  implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You can view the  GNU General Public License, online, at the GNU
Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.

=cut
