#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Devel-Mallinfo.
#
# Devel-Mallinfo is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Devel-Mallinfo is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;
BEGIN {
  plan tests => 4;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Devel::Mallinfo;

my $have_malloc_info_string = Devel::Mallinfo->can('malloc_info_string');
if (! $have_malloc_info_string) {
  MyTestHelpers::diag ('malloc_info_string() not available');
}
my $skip_malloc_info_string = ($have_malloc_info_string
                               ? undef
                               : 'due to malloc_info_string() not available');


#-----------------------------------------------------------------------------
# malloc_info_string() basic run

{
  # successful return depends on disk space available on /tmp, but think
  # it's ok to expect that when testing
  #
  my $str = $have_malloc_info_string && Devel::Mallinfo::malloc_info_string(0);
  skip ($skip_malloc_info_string,
        defined $str,
        1,
        'malloc_info_string() ran');
}

#-----------------------------------------------------------------------------
# weaken of return value

{
  my $have_scalar_util = eval { require Scalar::Util; 1 };
  if (! $have_scalar_util) {
    MyTestHelpers::diag ("Scalar::Util not available: ", $@);
  }

  my $have_weaken;
  if ($have_scalar_util) {
    $have_weaken = do {
      my $ref = [];
      eval { Scalar::Util::weaken ($ref); 1 }
    };
    if (! $have_weaken) {
      MyTestHelpers::diag ("weaken() not available: ", $@);
    }
  }

  my $ref;
  if ($have_malloc_info_string && $have_weaken) {
    $ref = \(Devel::Mallinfo::malloc_info_string(0));
    Scalar::Util::weaken ($ref);
  }
  ok (! defined $ref,
      1,
      'malloc_info_string() destroyed by weaken');
}

#-----------------------------------------------------------------------------
# malloc_info_string() induced failure from tmpfile()

my $have_bsd_resource = eval { require BSD::Resource; 1 };
if (! $have_bsd_resource) {
  MyTestHelpers::diag ("BSD::Resource not available -- ", $@);
}

my $have_rlimit_nofile;
if ($have_bsd_resource) {
  my $limits = BSD::Resource::get_rlimits();
  $have_rlimit_nofile = defined $limits->{'RLIMIT_NOFILE'};
  if (! $have_rlimit_nofile) {
    MyTestHelpers::diag ("RLIMIT_NOFILE not available");
  }
}

# don't think would have RLIMIT_NOFILE but then getrlimit() throwing "not
# implemented on this architecture", but check just in case
my $have_getrlimit;
if ($have_rlimit_nofile) {
  $have_getrlimit = eval {
    BSD::Resource::getrlimit (BSD::Resource::RLIMIT_NOFILE());
    1;
  };
  if (! $have_getrlimit) {
    MyTestHelpers::diag ("getrlimit() not available -- ", $@);
  }
}

# even less likely to have getrlimit() but not then setrlimit(), but check
# just in case
my $have_setrlimit;
if ($have_getrlimit) {
  my ($soft, $hard) = BSD::Resource::getrlimit(BSD::Resource::RLIMIT_NOFILE());
  $have_setrlimit = eval {
    BSD::Resource::setrlimit (BSD::Resource::RLIMIT_NOFILE(), $soft, $hard);
    1;
  };
  if (! $have_setrlimit) {
    MyTestHelpers::diag ("setrlimit() not available -- ",$@);
  }
}

# with RLIMIT_NOFILE making tempfile() fail
{
  my $str;
  my $err = 0;
  my $skip = (! $have_setrlimit
              ? 'due to setrlimit() not available'
              : ! $have_malloc_info_string
              ? 'due to malloc_info_string() not available'
              : undef);

  if ($have_malloc_info_string && $have_setrlimit) {
    my ($soft, $hard) = BSD::Resource::getrlimit(BSD::Resource::RLIMIT_NOFILE());
    MyTestHelpers::diag ("RLIMIT_NOFILE soft $soft hard $hard");

    BSD::Resource::setrlimit (BSD::Resource::RLIMIT_NOFILE(), 0, $hard);
    $str = Devel::Mallinfo::malloc_info_string(0);
    $err = $!;
    BSD::Resource::setrlimit (BSD::Resource::RLIMIT_NOFILE(), $soft, $hard);
  }

  require POSIX;
  my $emfile = eval { POSIX::EMFILE() } || 0; # in case no such errno

  skip ($skip,
        ! defined $str,
        1,
        'malloc_info_string() undef under NOFILE');
  skip ($skip,
        $err+0,
        $emfile,
        'malloc_info_string() errno EMFILE under NOFILE');
}

exit 0;
