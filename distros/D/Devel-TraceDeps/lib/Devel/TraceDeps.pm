package Devel::TraceDeps;
$VERSION = v0.0.3;

=head1 NAME

Devel::TraceDeps - track loaded modules and objects

=head1 SYNOPSIS

  $ perl -MDevel::TraceDeps your_program.pl

And the real fun is to pull a tree of dependencies off of your test
suite.

  $ perl -MDevel::eps=tree -S prove -l -r t
  $ ls tracedeps/

And of course no Devel:: module would be complete without an obligatory
cute little shortcut which needlessly involves the DB backend:

  $ perl -d:eps whatever.pl

TODO:  a cute little shortcut which needlessly claims an otherwise
very funny-looking toplevel namespace.

  $ perl -MapDeps whatever.pl

=head1 About

Devel::TraceDeps delivers a comprehensive report of everything which was
loaded into your perl process via the C<use>, C<require>, or
C<do($file)> mechanisms.

Unlike Devel::TraceLoad, this does not load any modules itself and is
intended to be very unintrusive.  Unlike Module::ScanDeps, it is
designed to run alongside your test suite.

For access to the resultant data, see the API in
L<Devel::TraceDeps::Scan>.

In tree mode, forking processes and various other runtime effects
*should* be supported but surprises abound in this realm -- tests and
patches welcome.

TODO reports on shared objects loaded by DynaLoader/XSLoader.

TODO somehow catching the 'use foo 1.2' VERSION assertions.  This is
handled by use() and is therefore outside of our reach (without some
tricks involving $SIG{__DIE__} or such.)

=cut

=begin note

Depth can be inferred, though it is really meaningless because it is an
accident of chronology -- the second level never appears if something is
already loaded.

Types are:

  'do',      $what, $package, $line, $file
  'req',     $what, $package, $line, $file
  'ver',     $version

TODO:
  'loaded',  $module, $return, $version||'undef', $modfile
  'dlmod',   $module
  'failed',  $module, $message
  'done',    $what, $return

Does anything appear in %INC without our knowing?

Dynaloader: @DynaLoader::dl_shared_objects or @DynaLoader::dl_modules ?

=head1 Naming

By $0, but need to address -e and maybe subprocesses.  Perhaps the
import option takes care of that?  There's also this issue of cleaning.

  -MDevel::TraceDeps=tree
    cleans the .tracedeps/ dir
    sets PERL5OPT to =child,$PWD/.tracedeps
    does no tracing?

=head1 After

Which modules were successfully loaded:

  $module, $version

Other data would be

  foreach $module (@loaded) {
    push(@{$something{$module}{wanters}}, $wanter);
  }

=end note

=cut

my %store;

# tracking the steps in the tree
my @trace;
my $tracemark = 0;

my $debugging = 0; # for -d:... usage
BEGIN {
  if(defined(%DB::)) {
    $debugging = 1;
    *DB::DB = sub {};
  }
  *CORE::GLOBAL::do = sub {
    my $target = shift;

    my ($p, $f, $l) = CORE::caller;
    my $list = $store{$p} ||= [];

    push(@trace, ++$tracemark); $tracemark = 0;
    push(@$list, my $req = {file => $f, line => $l, did => $target,
      trace => join('-', @trace),
    });
    #warn "$p does $target ($f, $l)\n";
    my $x = bless({mod => $target, req => $req, by => \@caller},
      'Devel::TraceDeps::Watch');

    my $ret = CORE::do($target);
    return($ret) if($ret);
    #$x->{err} = $@ if($@);
    if(defined($ret)) {
      $req->{err} = "returned '$ret'" unless($ret);
    }
    else {
      $req->{err} = $!;
    }

    return($ret);
  };
  *CORE::GLOBAL::require = sub {
    my ($required) = @_;
    my $module = $required; # don't touch the $required value

    my @caller = CORE::caller(0);
    my ($p, $f, $l) = @caller;

    # remember it
    my $list = $store{$p} ||= [];
    #warn "$p wants $module ($f, $l)\n";

    # do data-gathering

    # pass through version numbers
    # XXX require("0.4") edge cases :-/
    # bah! this is version 5something dude
    if(($module =~ m/^5(?:\.|$)/) or (ord(substr($module, 0, 1)) == 5)) {
      # using it as a string breaks the versiony magic
      # but an untouched value works fine
      # ok, if it has literal dots it is a number
      my $version = 
        $module eq '5' ? '5.000' :
        $module =~ m/^5(?:\.|$)/ ? $module : sprintf("%vd", $module);
      push(@$list, {file => $f, line => $l, ver => $version,
        trace => join('-', @trace, ++$tracemark),
      });
      return CORE::require $required;
    }

    push(@trace, ++$tracemark); $tracemark = 0;

    push(@$list, my $req = {
      file => $f, line => $l, req => $module,
      trace => join('-', @trace),
    });

    if(exists($INC{$module})) {
      $tracemark = pop(@trace);
      return(1);
    }

    # delicious and necessary evil: the object goes out of scope in that
    # moment between the here and the there, thus: after the
    # CORE::require completes, even if we're in eval.

    #warn join("|", 'caller =', @caller), "\n";
    my $x = bless({mod => $module, req => $req, by => \@caller},
      'Devel::TraceDeps::Watch');

    # apparently goto doesn't work here,
    # so we need to tweak the caller stack?
    return scalar(CORE::require($module));
  };
}
{
  package Devel::TraceDeps::Watch;
  sub DESTROY {
    my $self = shift;
    my $req = $self->{req};
    unless($INC{$self->{mod}}) {
      $req->{fail} = 1;
    }
    $tracemark = pop(@trace);

    # hmm, can we tell if this is global cleanup time?

    my $caller = delete($self->{by});

    if(my $err = $@) {
      # XXX ugh. eval("require foo") vs eval {require foo}!
      # thanks base.pm
      if($err =~ m/^(Can't locate .*\)) at /) {
        my $fix_err = $1;
        my @from = @$caller;
        # emulate the builtin eval error here (eek)
        my $at_file =
          ($from[6] or $from[3] =~ m/::BEGIN$/) ? "(eval 424242)" :
          $from[1];
        my $at_line = $from[2];
        $fix_err .= " at $at_file line $at_line.\n";
        $@ = $fix_err; # YES I REALLY MEAN THAT
      }
      # the @INC bits are not important
      $err =~ s/\(\@INC contains: .*/.../;
      $err =~ s/\n$//;
      $err =~ s/\n/\\n/g;
      $req->{err} = $err;
    }
    return;
  }
}

sub _output {
  my (%args) = @_;
  return if($args{is_root});

  my $fh;
  if(my $dir = $args{in_tree}) {
    my $program = $args{program};
    $program =~ s#^/+##;
    $program =~ s#/+#---#g;
    $outfile = $dir . '/' . $program;
    if($$ != $args{init_pid}) {
      $outfile .= '.' . $$;
    }
    open($fh, '>', $outfile) or die "cannot save $outfile $!";
  }
  else {
    $fh = \*STDOUT;
  }
  foreach my $key (keys(%store)) {
    print $fh $key, "\n";
    foreach my $item (@{$store{$key}}) {
      print $fh join("\n", '  -----',
        map({"  $_: $item->{$_}"} keys %$item)), "\n";
    }
  }
}

########################################################################
{ # closure
my %self;

END { _output(%self); }

sub import {
  my $class = shift;
  my (@args) = @_;
  #warn "my pid is $$";
  if(@args) {
    if($args[0] eq 'tree') {
      $self{is_root} = 1;
      my $dir = $args[1] || 'tracedeps';
      if(-e $dir) {
        die "$dir exists!";
      }
      else {
        mkdir($dir);
      }

      # just setup the subprocesses
      $ENV{PERL5OPT} = join(' ',
        split(/ /, $ENV{PERL5OPT}||''), "-MDevel::TraceDeps=tree=$dir"
      );
    }
    elsif($args[0] =~ s/^tree=//) {
      # subprocess
      $self{in_tree} = $args[0];
      $self{program} = $0;
      $self{init_pid} = $$;
    }
    else {
      die "unknown import args @args";
    }
  }
}
}
########################################################################

=head1 Possible Issues

I think these are going to be very pathological cases since I've already
run a fair body of code through this without any visible hitches.

=head2 Version Number Ambiguity

If you try to require("5.whatever.pm"), it might fail.

=head2 Caller

If a required module expects to do something with caller() at BEGIN time
(e.g. outside of import()), we have problems.  If I could think of a
good reason to rewrite the results of caller(), I would.

=head2 Tree

The tree setting goes all the way down into any perl subprocesses by
setting ourselves in PERL5OPT.  This is probably what you want if you're
trying to package or bundle some code, but needs a knob if you're trying
to do something else with it.

The PERL5OPT variable gets dropped if you use taint.  Patches welcome!

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

my $fakery = 'kwalitee police look the other way now please
use strict;
'; # we cannot use modules here, not even strict.pm


# vi:ts=2:sw=2:et:sta
1;
