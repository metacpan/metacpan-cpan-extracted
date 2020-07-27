package Devel::ebug::Backend;

use strict;
use warnings;

our $VERSION = '0.63'; # VERSION

package DB;

use IO::Socket::INET;
use String::Koremutake;
use YAML;
use Module::Pluggable
  search_path => 'Devel::ebug::Backend::Plugin',
  require     => 1;

use vars qw(@dbline %dbline);

our $VERSION = '0.63'; # VERSION

# Let's catch INT signals and set a flag when they occur
$SIG{INT} = sub {
  $DB::signal = 1;
  return;
};

my $context = {
  finished     => 0,
  initialise   => 1,
  mode         => "step",
  stack        => [],
  watch_points => [],
};


# Commands that the back end can respond to
# Set record if the command changes start and should thus be recorded
# in order for undo to work properly
my %commands = ();

sub DB {
  my ($package, $filename, $line) = caller;
  ($context->{package}, $context->{filename}, $context->{line}) =
    ($package, $filename, $line);

  initialise() if $context->{initialise};

  # we're here because of a signal, reset the flag
  if ($DB::signal) {
    $DB::signal = 0;
  }

  # single step
  my $old_single = $DB::single;
  $DB::single = 1;

  if (@{ $context->{watch_points} }) {
    my %delete;
    foreach my $watch_point (@{ $context->{watch_points} }) {
      local $SIG{__WARN__} = sub { };
      my $v = eval "package $package; $watch_point";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
      if ($v) {
        $context->{watch_single} = 1;
        $delete{$watch_point} = 1;
      }
    }
    if ($context->{watch_single} == 0) {
      return;
    } else {
      @{ $context->{watch_points} } =
        grep { !$delete{$_} } @{ $context->{watch_points} };
    }
  }

  # we're here because of a break point, test the condition
  if ($old_single == 0) {
    my $condition = break_point_condition($filename, $line);
    if ($condition) {
      local $SIG{__WARN__} = sub { };
      my $v = eval "package $package; $condition";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
      unless ($v) {
        # condition not true, go back to running
        $DB::single = 0;
        return;
      }
    }
  }

  $context->{watch_single} = 1;
  $context->{codeline} = (fetch_codelines($filename, $line - 1))[0];
  chomp $context->{codeline};

  while (1) {
    my $req     = get();
    my $command = $req->{command};

    my $sub = $commands{$command}->{sub};
    if (defined $sub) {
      put($sub->($req, $context));

      if ($context->{last}) {
        delete $context->{last};
        last;
      }
    } else {
      die "unknown command $command";
    }
  }
}

sub initialise {
  my $k      = String::Koremutake->new;
  my $int    = $k->koremutake_to_integer($ENV{SECRET});
  my $port   = 3141 + ($int % 1024);
  my $server = IO::Socket::INET->new(
    Listen    => 5,
    LocalAddr => 'localhost',
    LocalPort => $port,
    Proto     => 'tcp',
    ReuseAddr => 1,
    Reuse     => 1,
    )
    || die $!;
  $context->{socket} = $server->accept;

  foreach my $plugin (__PACKAGE__->plugins) {
    my $sub = $plugin->can("register_commands");
    next unless $sub;
    my %new = &$sub;
    foreach my $command (keys %new) {
      $commands{$command} = $new{$command};
    }
  }

  $context->{initialise} = 0;
}

sub put {
  my ($res) = @_;
  my $data = unpack("h*", Dump($res));
  local $\; # if we run under perl -l the following line would get mangled
  $context->{socket}->print($data . "\n");
}

sub get {
  exit unless $context->{socket};
  local $/= "\n";
  my $data = $context->{socket}->getline;
  my $req = do {
    local $YAML::LoadBlessed = 1;
    Load(pack("h*", $data));
  };
  push @{ $context->{history} }, $req
    if exists $commands{ $req->{command} }->{record};
  return $req;
}

sub sub {
  my (@args) = @_;
  my $sub = $DB::sub;

  my $frame = { single => $DB::single, sub => $sub };
  push @{ $context->{stack} }, $frame;

  # If we are in 'next' mode, then skip all the lines in the sub
  $DB::single = 0 if defined $context->{mode} && $context->{mode} eq 'next';

  no strict 'refs';
  if (wantarray) { ## no critic (Freenode::Wantarray)
    my @ret   = &$sub;
    my $frame = pop @{ $context->{stack} };
    $DB::single = $frame->{single};
    $DB::single = 0 if defined $context->{mode} && $context->{mode} eq 'run' && !@{$context->{watch_points}};

    if ($frame->{'return'}) {
      return @{ $frame->{'return'} };
    } else {
      return @ret;
    }
  } else {
    my $ret   = &$sub;
    my $frame = pop @{ $context->{stack} };
    $DB::single = $frame->{single};
    $DB::single = 0 if defined $context->{mode} && $context->{mode} eq 'run' && !@{$context->{watch_points}};

    if ($frame->{'return'}) {
      return $frame->{'return'}->[0];
    } else {
      return $ret;
    }
  }
}

sub DB::postponed {
    # If this is a subroutine, let postponed_sub() deal with it.
    goto &postponed_sub unless ref \$_[0] eq 'GLOB';

    my ($filePath) = @_;
    $filePath =~ s/^.*_<//;

    my ($volume,$directories,$fileName) = File::Spec->splitpath( $filePath );

    #test if the file name match with relative path/absolute path/single file name
    if (exists $DB::break_on_load{$filePath}
        || exists $DB::break_on_load{File::Spec->rel2abs( $filePath)}
        || exists $DB::break_on_load{$fileName}){
        $DB::single = 1;
    }

}


sub fetch_codelines {
  my ($filename, @lines) = @_;

  #use vars qw(@dbline %dbline);
  *dbline = $main::{ '_<' . $filename };
  my @codelines = @dbline;

  # for modules, not sure why
  shift @codelines if not defined $codelines[0];

  # defined!
  @codelines = map { defined($_) ? $_ : "" } @codelines;

  # remove newlines
  s/\s+$// for @codelines;

  # we run it with -d:ebug::Backend, so remove this extra line
  @codelines = grep { $_ ne 'use Devel::ebug::Backend;' } @codelines;

  # for some reasons, the perl internals leave the opening POD line
  # around but strip the rest. so let's strip the opening POD line
  @codelines =
    map { /^=(head|over|item|back|over|cut|pod|begin|end|for)/ ? "" : $_ }
    @codelines;

  if (@lines) {
    @codelines = @codelines[@lines];
  }
  return @codelines;
}

sub break_point_condition {
  my ($filename, $line) = @_;
  *dbline = $main::{ '_<' . $filename };
  return $dbline{$line};
}

sub END {
  $context->{finished} = 1;
  $DB::single = 1;
  DB::fake::at_exit();
}

package
  DB::fake;

sub at_exit {
  1;
}

package DB;    # Do not trace this 1; below!

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Backend

=head1 VERSION

version 0.63

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2020 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
