package MailBot::IniConf;  # modified from Hutton's original IniConf.  --rhn
# package IniConf;

# below is original copyright notice.  --rhn

# AUTHOR

#  Scott Hutton (shutton@indiana.edu)

# COPYRIGHT

# Copyright (c) 1996 Scott Hutton. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

# patched 1/97.  --rhn

require 5.002;
# $VERSION = 0.91;

use strict;
use Carp;
use vars qw( $VERSION @instance $instnum @oldhandler @errors );


#
# Package variables
#
@instance = ( );
$instnum  = 0;
@oldhandler =  ( );
@errors = ( );


sub new {
  my $class = shift;
  my %parms = @_;

  my $errs = 0;
  my @groups = ( );

  my $self           = {};
  $self->{cf}        = '';
  $self->{firstload} = 1;
  $self->{default}   = '';

  # Parse options
  my($k, $v);
  local $_;
  while (($k, $v) = each %parms) {
    if ($k eq '-file') {
      $self->{cf} = $v;
    }
    elsif ($k eq '-reloadsig') {
      $v =~ s/^SIG//;
      $self->{reloadsig} = uc($v);
    }
    elsif ($k eq '-default') {
      $self->{default} = $v;
    }
    elsif ($k eq '-nocase') {
      $self->{nocase} = $v ? 1 : 0;
    }
    elsif ($k eq '-reloadwarn') {
      $self->{reloadwarn} = $v ? 1 : 0;
    }
    else {
      carp "Unknown named parameter $k=>$v";
      $errs++;
    }
  }

  croak "must specify -file parameter for new $class" 
    unless $self->{cf};

  return undef if $errs;

  # Set up a signal handler if requested
  my($sig, $oldhandler, $newhandler);
  if ($sig = $self->{reloadsig}) {
    $oldhandler[$instnum] = $SIG{$sig};
    $newhandler = "${class}::SigHand_$instnum";
    my $toeval = <<"EOT";

	sub $newhandler {
	  \$SIG{$sig} = 'IGNORE';
	  \$${class}::instance[$instnum]->ReadConfig;
	  if (\$oldhandler[$instnum] && \$oldhandler[$instnum] ne 'IGNORE') {
	    eval '&$oldhandler[$instnum];';
	  }
	  \$SIG{$sig} = '$newhandler'
	}

EOT
    
    eval $toeval;
  }

  bless $self, $class;

  $instance[$instnum++] = $self;

  if ($self->ReadConfig) {
    $SIG{$sig} = $newhandler if $sig;
    return $self;
  } else {
    return undef;
  }
}


sub val {
  my $self = shift;
  my $sect = shift;
  my $parm = shift;

  if ($self->{nocase}) {
    $sect = lc($sect);
    $parm = lc($parm);
  }
#   my $val = $self->{v}{$sect}{$parm} || $self->{v}{$self->{default}}{$parm};
  my $val = $self->{v}{$sect}{$parm};  # --rhn
  if (ref($val) eq 'ARRAY') {
    return wantarray ? @$val : join($/, @$val);
  } else {
    return $val;
  }
}

sub setval {
  my $self = shift;
  my $sect = shift;
  my $parm = shift;
  my @val  = @_;

  if (defined($self->{v}{$sect}{$parm})) {
    if (@val > 1) {
      $self->{v}{$sect}{$parm} = \@val;
    } else {
      $self->{v}{$sect}{$parm} = shift @val;
    }
    return 1;
  } else {
    return undef;
  }
}

sub ReadConfig {
  my $self = shift;

  local *CF;
  my($lineno, $sect);
  my($group, $groupmem);
  my($parm, $value);
  my @cmts;
  @errors = ( );

  # Initialize (and clear out) storage hashes
  $self->{sects}  = [];		# Sections
  $self->{groups} = {};		# Subsection lists
  $self->{v}      = {};		# Parameter values
  $self->{sCMT}   = {};		# Comments above section

  my $nocase = $self->{nocase};

  my ($ss, $mm, $hh, $DD, $MM, $YY) = (localtime(time))[0..5];
  printf STDERR
    "PID %d reloading config file %s at %d.%02d.%02d %02d:%02d:%02d\n",
    $$, $self->{cf}, $YY+1900, $MM+1, $DD, $hh, $mm, $ss
    unless $self->{firstload} || !$self->{reloadwarn};

  $self->{firstload} = 0;

  open(CF, $self->{cf}) || carp "open $self->{cf}: $!";
  local $_;
  my ($parm, $val);
  while (<CF>) {
    chop;
    $lineno++;

    if (/^\s*$/) {				# ignore blank lines
      next;
    }
    elsif (/^\s*[\#\;]/) {			# collect comments
      push(@cmts, $_);
      next;
    }
    elsif (/^\s*\[([^\]]+)\]\s*$/) {		# New Section
      $sect = $1;
      $sect = lc($sect) if $nocase;
      push(@{$self->{sects}}, $sect);
      if ($sect =~ /(\S+)\s+(\S+)/) {		# New Group Member
	($group, $groupmem) = ($1, $2);
	if (!defined($self->{group}{$group})) {
	  $self->{group}{$group} = [];
	}
	push(@{$self->{group}{$group}}, $groupmem);
      }
      if (!defined($self->{v}{$sect})) {
	$self->{sCMT}{$sect} = [@cmts] if @cmts > 0;
	$self->{pCMT}{$sect} = {};		# Comments above parameters
	$self->{parms}{$sect} = [];
	@cmts = ( );
	$self->{v}{$sect} = {};
      }
    }
    elsif (($parm, $val) = /\s*(\S+)\s*=\s*(.*)/) {	# new parameter
      $parm = lc($parm) if $nocase;
      $self->{pCMT}{$sect}{$parm} = [@cmts];
      @cmts = ( );
      if ($val =~ /^<<(.*)/) {			# "here" value
	my $eotmark  = $1;
	my $foundeot = 0;
	my $startline = $lineno;
	my @val = ( );
	while (<CF>) {
	  chop;
	  $lineno++;
	  if ($_ eq $eotmark) {
	    $foundeot = 1;
	    last;
	  } else {
	    push(@val, $_);
	  }
	}
	if ($foundeot) {
	  $self->{v}{$sect}{$parm} = \@val;
	  $self->{EOT}{$sect}{$parm} = $eotmark;
	} else {
	  push(@errors, sprintf('%d: %s', $startline, 
			      qq#no end marker ("$eotmark") found#));
	}
      } else {
	$self->{v}{$sect}{$parm} = $val;
      }
      push(@{$self->{parms}{$sect}}, $parm);
    }
    else {
      push(@errors, sprintf('%d: %s', $lineno, $_));
    }
  }
  close(CF);
  @errors ? undef : 1;
}

sub Sections {
  my $self = shift;
  @{$self->{sects}};
}

sub Parameters {
  my $self = shift;
  my $sect = shift;
  @{$self->{parms}{$sect}};
}

sub GroupMembers {
  my $self  = shift;
  my $group = shift;

  @{$self->{group}{$group}};
}

sub WriteConfig {
  my $self = shift;
  my $file = shift;

  local(*F);
  open(F, "> $file.new") || do {
    carp "Unable to write temp config file $file: $!";
    return undef;
  };
  my $oldfh = select(F);
  $self->OutputConfig;
  close(F);
  select($oldfh);
  rename "$file.new", $file || do {
    carp "Unable to rename temp config file to $file: $!";
    return undef;
  };
  return 1;
}

sub RewriteConfig {
  my $self = shift;
  $self->WriteConfig($self->{cf});
}

sub OutputConfig {
  my $self = shift;

  my($sect, $parm, @cmts);
  my $notfirst = 0;
  local $_;
  foreach $sect (@{$self->{sects}}) {
    print "\n" if $notfirst;
    $notfirst = 1;
    if ((ref($self->{sCMT}{$sect}) eq 'ARRAY') &&
	(@cmts = @{$self->{sCMT}{$sect}})) {
      foreach (@cmts) {
	print "$_\n";
      }
    }
    print "[$sect]\n";

    foreach $parm (@{$self->{parms}{$sect}}) {
      if ((ref($self->{pCMT}{$sect}{$parm}) eq 'ARRAY') &&
	  (@cmts = @{$self->{pCMT}{$sect}{$parm}})) {
	foreach (@cmts) {
	  print "$_\n";
	}
      }
      my $val = $self->{v}{$sect}{$parm};
      if (ref($val) eq 'ARRAY') {
	my $eotmark = $self->{EOT}{$sect}{$parm};
	print "$parm= <<$eotmark\n";
	foreach (@{$val}) {
	  print "$_\n";
	}
	print "$eotmark\n";
      } else {
	print "$parm=", $self->{v}{$sect}{$parm}, "\n";
      }
    }
  }
}

1;
