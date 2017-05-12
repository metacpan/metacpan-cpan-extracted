package Devel::Profiler::Test;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.01;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = qw(profile_code check_tree get_times 
                    write_module cleanup_module);

use Test::More;

# run some code through the profiler
sub profile_code {
    my $code      = shift;
    my $msg       = shift;
    my $use_line  = shift || "use Devel::Profiler;";

    # clean up old tmon.out
    unlink 'tmon.out' if -e 'tmon.out';

    # write temporary script
    open(SCRIPT, '>', 'script.pl') or die "Unable to open script.pl : $!";
    print SCRIPT "$use_line\n$code\nprint \"ok\\n\";\n";
    close(SCRIPT)                  or die "Unable to close script.pl : $!";
    
    if ($ENV{TEST_DPROF}) {
        # run script using Devel::DProf
        open(OUT, "$^X -Iblib -I. -d:DProf script.pl|")
          or die "Unable to run script.pl : $!";
    } else {
        # run script using Devel::Profiler
        open(OUT, "$^X -Iblib -I. script.pl|")
          or die "Unable to run script.pl : $!";
    }
    my $out = join('',<OUT>);
    die "Profile code did not run to completion : $out\n"
      if $out ne "ok\n";
    close OUT or die "Unable to close pipe from script.pl : $!";

    # clean up
    unlink 'script.pl' or die "Unable to delete script.pl : $!";

    # make sure this did what it should
    die "No tmon.out created.\n"
      unless -e 'tmon.out';
    
    ok(1, $msg);
}

# get a tree returned from running dprofpp -T
sub check_tree {
    my $expected   = shift;
    my $msg        = shift;
    my $extra_opts = shift || "";

    # run dprofpp -T
    open(DPROF, "dprofpp -T|") or die "Unable to run dprofpp : $!";
    my $out = join('', <DPROF>);
    close DPROF;
    
    is($out, $expected, $msg);
}

# extract total times of run through profiler
sub get_times {
    # run dprofpp -s to get system time
    open(DPROF, "dprofpp -s|") or die "Unable to run dprofpp : $!";
    my $out = join('', <DPROF>);
    close DPROF;

    my ($real) = $out =~ /Total\s+Elapsed\s+Time\s+=\s+([\d\.]+)/;
    my ($sys)  = $out =~ /System\s+Time\s+=\s+([\d\.]+)/;

    # run dprofpp -u to get user time
    open(DPROF, "dprofpp -u|") or die "Unable to run dprofpp : $!";
    $out = join('', <DPROF>);
    close DPROF;

    my ($user)  = $out =~ /User\s+Time\s+=\s+([\d\.]+)/;
    
    return ($real, $sys, $user);
}

sub write_module {
    my ($name, $code) = @_;
    open(MOD, ">", "$name.pm") or die "Unable to open $name.pm : $!";
    print MOD $code;
    close MOD;
}

sub cleanup_module {
    my $name = shift;
    unlink "$name.pm" or die "Unable to unlink $name.pm : $!";
}

__END__

=head1 NAME

Devel::Profiler::Test - test support library for Devel::Profiler

=head1 SYNOPSIS

  # plan a test for each call to Devel::Profiler::Test
  use Test::More tests => 2;
  use Devel::Profiler::Test qw(profile_code check_tree);

  profile_code(<<END)
  ... some code to profile ...
  END

  check_tree(<<END)
  ... a tree in the format produced by dprofpp -T ...
  END

=head1 DESCRIPTION

This is a test support library for Devel::Profiler.  It's probably
only useful inside Devel::Profiler's test scripts, but you never know!

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=head1 SEE ALSO

L<Devel::Profiler|Devel::Profiler>

=cut
