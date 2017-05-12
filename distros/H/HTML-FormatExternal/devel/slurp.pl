#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

# HTML-FormatExternal is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# HTML-FormatExternal is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with HTML-FormatExternal.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Data::Dumper;

# uncomment this to run the ### lines
use Smart::Comments;

{
  require IPC::Run;
  my $infile = '/dev/null';
  my $stdout;
  my $stderr;
  my $ret = eval { IPC::Run::run(['lynx','-dump'],
                          '<', $infile,
                          '>', \$stdout,
                                 '2>', \$stderr) };
  my $err = $@;
  ### $stdout
  ### $stderr
  ### $ret
  ### $err
  exit 0;
}

{
  require Perl6::Slurp;
  my $str = eval { Perl6::Slurp::slurp ('-|', 'nosuchprogramname') };
  print $str//'undef';
  exit 0;
}

{
  my $in;
  if (! open $in, '-|', 'nosuchprogram', '--version') {
    my $e1 = $@;
    my $e2 = $!;
    print Dumper($e1);
    print Dumper($e2);
  }
  undef $in;
  local $SIG{__WARN__} = sub { $_[0] =~ /Can't exec/ or warn $_[0] };
  if (! open $in, '-|', 'nosuchprogram', '--version') {
    my $e1 = $@;
    my $e2 = $!;
    print Dumper($e1);
    print Dumper($e2);
  }
  exit 0;
}



#------------------------------------------------------------------------------
# Old code:
#
# # In Perl6::Slurp version 0.03 open() gives its usual warning if it can't
# # run the program, but Perl6::Slurp then croaks with that same message.
# # Suppress the warning in the interests of avoiding duplication.
# #
# sub _slurp_nowarn {
#   require Perl6::Slurp;
#   # no warning suppression when debugging
#   local $SIG{__WARN__} = (DEBUG ? $SIG{__WARN__} : \&_warn_suppress_exec);
#   return Perl6::Slurp::slurp (@_);
# }
# sub _warn_suppress_exec {
#   $_[0] =~ /Can't exec/ or warn $_[0];
# }

  # '-|', 
  # require Perl6::Slurp;
  # my $str = do {
  #   local %ENV = %ENV;
  #   @ENV{keys %$env} = values %$env; # overrides out of subclasses
  #   Perl6::Slurp::slurp (@command);
  # };

# Perl6::Slurp demands 5.8 anyway, don't think need to ask for 5.8 here to
# be sure of getting multi-arg open() of piped command in that module
# use 5.008;
