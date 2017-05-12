package Devel::SlowBless;

use strict;
use warnings;
require Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Devel::SlowBless ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	amg_gen sub_gen
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Devel::SlowBless', $VERSION);

# Preloaded methods go here.
my $pid     = 0;
my $amg_gen = 0;
my $sub_gen = 0;
my $warn    = 0;

sub start_warning {
  $warn = 1;
}

sub stop_warning {
  $warn = 0;
}

sub DB::DB {
    my $cur_amg = amg_gen();
    my $cur_sub = sub_gen();

    if ($pid != $$)
    {
        $pid = $$;
        $amg_gen = $cur_amg;
        $sub_gen = $cur_sub;
    }

    if ($amg_gen != $cur_amg)
    {
        if ($warn)
        {
            Carp::cluck("[$pid] AMAGIC $amg_gen -> $cur_amg\n");
        }
        $amg_gen = $cur_amg;
    }
    if ($sub_gen != $cur_sub)
    {
        if ($warn)
        {
            Carp::cluck("[$pid] SUB GEN $sub_gen - $cur_sub\n");
        }
        $sub_gen = $cur_sub;
    }
}

1;
__END__

=head1 NAME

Devel::SlowBless - Perl extension for identifying code that causes bless
into overloaded classes to be slow.

=head1 SYNOPSIS

  perl -d:SlowBless
  ... # initialization code that is expected to change PL_sub_generation
  Devel::SlowBless::start_warning();
  ... # a stack backtrace will be output whenever PL_sub_generation or
      # PL_amagic_generation changes
  Devel::SlowBless::stop_warning(); # what it says. optional, obviously

=head1 DESCRIPTION

This module provides functions to introspect the current value of the
PL_sub_generation and the PL_amagic_generation internal perl variables,
as well as a perl debugger implementation that will print out a stack
trace whenever either of these variables changes. As of Perl 5.17.1,
PL_amagic_generation has been removed and always returns 0.

Whenever either of these variables changes, the bless() function slows
down as perl examines the entire class hierarchy recomputing the overloads
that are normally cached in the stash.  The penalty is paid just once for
each class, but if these variables are changing frequently, and your program
has deep class hierarchies with overloading, performance can suffer badly.

=head2 EXPORT

None by default.

  sub_gen
  amg_gen

=head1 AUTHORS

Benjamin Holzman E<lt>bholzman@earthlink.netE<gt>
Grant Street Group, Inc. E<lt>developers@grantstreet.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Benjamin Holzman and Grant Street Group, Inc.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
