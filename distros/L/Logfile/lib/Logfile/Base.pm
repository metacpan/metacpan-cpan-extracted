#                              -*- Mode: Perl -*- 
# $Basename: Base.pm $
# $Revision: 1.3 $
# Author          : Ulrich Pfeifer
# Created On      : Mon Mar 25 09:58:31 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Apr 29 09:08:33 2003
# Language        : Perl
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 

package Logfile::Base;
use Carp;
use vars qw($VERSION $nextfh);
use strict;

# $Format: "$\VERSION = sprintf '%5.3f', ($ProjectMajorVersion$ * 100 + ($ProjectMinorVersion$-1))/1000;"$
$VERSION = sprintf '%5.3f', (2 * 100 + (3-1))/1000;

$Logfile::MAXWIDTH = 40;
my ($HaveParseDate, $HaveGetDate, $HaveDateGetDate); 
$nextfh = 'fh000';

sub isafh { 
  my $f = shift; 
  ref $f eq 'GLOB' 
  or ref \$f eq 'GLOB' 
  or (ref $f) =~ /^IO::/ 
}

sub new {
    my $type = shift;
    my %par  = @_;
    my $self = {};
    my $file = $par{File};

    if (ref $par{Group}) {
        $self->{Group} = $par{Group};
    } else {
        $self->{Group} = [$par{Group}];
    }       
    if ($file) {
      if (isafh $file) {
        $self->{Fh} = $file;
      } else {
        *S = "${type}::".++$nextfh;
        $self->{Fh} = *S;
        if ($file =~ /\.gz$/) {
            open(S, "gzip -cd $file|") 
                or die "Could not open $file: $!\n";
        } else {
            open(S, "$file") 
                or die "Could not open $file: $!\n";
        }

      }
    } else {
        $self->{Fh} = *ARGV;
    }
    bless $self, $type || ref($type);
    $self->readfile;
    close S if $self->{File};
    $self;
}

sub norm { $_[2]; }             # dummy

sub group {
    my ($self, $group) = @_;

    if (ref($group)) {
        join $;, @{$group};
    } else {
        $group;
    }
}

sub key {
    my ($self, $group, $rec) = @_;
    my $key = '';

    if (ref($group)) {
        $key = join $;, map($self->norm($_, $rec->{$_}), @{$group});
    } else {
        $key = $self->norm($group, $rec->{$group});
    }
    $key;
}

sub readfile {
    my $self  = shift;
    my $fh    = $self->{Fh};
    my @group = @{$self->{Group}};
    my $group;

    while (!eof($fh)) {
        my $rec = $self->next;
        last unless $rec;
        for $group (@group) {
            my $gname = $self->group($group);
            my $key = $self->key($group, $rec);

            if (defined $self->{$gname}->{$key}) {
                $self->{$gname}->{$key}->add($rec,$group); # !!
            } else {
                $self->{$gname}->{$key} = $rec->copy;
            }
        }
    }
}

sub report {
    my $self  = shift;
    my %par = @_;
    my $group = $self->group($par{Group});
    my $sort  = $par{Sort} || $group;
    my $rever = (($sort =~ /Date|Hour/) xor $par{Reverse});
    my $list  = $par{List};
    my ($keys, $key, $val, %keys);
    my $mklen  = length($group); 
    my $direction = ($rever)?'increasing':'decreasing';
    my (@list, %absolute);
    my @mklen = map(length($_), split($;, $group));

    croak "No index for $group\n" unless $self->{$group};

    if ($list) {
        if (ref($list)) {
            @list = @{$list};
        } else {
            @list = ($list);
        }
    } else {
        @list = qw(Records);
    }

    @absolute{@list} = (0) x @list;
    $sort =~ s/$;.*//;
    #print STDERR "sort = $sort\n";
    while (($key,$val) = each %{$self->{$group}}) {
        $keys{$key} = $val->{$sort};
        if ($key =~ /$;/) {
            my  @key = split $;, $key;
            for (0 .. $#key) {
                $mklen[$_] = length($key[$_])
                    if length($key[$_]) > $mklen[$_];
            }
            $mklen = $#mklen;
            grep ($mklen += $_, @mklen);
        } else {
            $mklen = length($key) if length($key) > $mklen;
        }
        for (@list) {
          $absolute{$_} += $val->{$_} if defined $val->{$_};
        }
    }
    # chop keys to $Logfile::MAXWIDTH chars maximum;
    grep (($_=($_>$Logfile::MAXWIDTH)?$Logfile::MAXWIDTH:$_), @mklen);
    if ($group =~ /$;/) {
        my @key =  split $;, $group;
        for (0 .. $#key) {
            printf "%-${mklen[$_]}s ", $key[$_];
        }
    } else {
        printf ("%-${mklen}s ", $group);
    }
    for (@list) {
        printf("%16s ", $_);
    }
    print "\n";
    print '=' x ($mklen + (@list * 17));
    print "\n";
    #for $key (keys %keys) {
    #    print STDERR "** $key $keys{$key}\n";
    #}
    for $key (sort {&srt($rever, $keys{$a}, $keys{$b})} 
              keys %keys) {
        my $val = $self->{$group}->{$key};
        if ($key =~ /$;/) {
            my @key =  split $;, $key;
            for (0 .. $#key) {
                printf "%-${mklen[$_]}s ", substr($key[$_],0,$mklen[$_]);
            }
        } else {
            printf "%-${mklen}s ", $key;
        }
        for $list (@list) {
            my $ba = (defined $val->{$list})?$val->{$list}:0;
            if ($absolute{$list} > 0) {
                my $br = $ba/$absolute{$list}*100;
                printf "%9d%6.2f%% ", $ba, $br;
            } else {
                printf "%15s ", $ba;
            }
        }
        print "\n";
        last if defined $par{Top} && --$par{Top} <= 0;
    }
    print "\f";
}

sub srt {
    my $rev = shift;
    my ($y,$x);
    if ($rev) {
        ($x,$y) = @_;
    } else {
        ($y,$x) = @_;
    }

    if ($x =~ /[^\d.]|^$/o or $y =~ /[^\d.]|^$/o) {
        lc $y cmp lc $x;
    } else {
        $x <=> $y;
    }
}

sub keys {
    my $self  = shift;
    my $group = shift;

    keys %{$self->{$group}};
}

sub all {
    my $self  = shift;
    my $group = shift;

    %{$self->{$group}};
}

package Logfile::Base::Record;

BEGIN {
  eval {require GetDate;};
  $HaveGetDate = ($@ eq "") and import GetDate 'getdate';
  unless ($HaveGetDate) {
    eval {require Date::GetDate};
    $HaveDateGetDate = ($@ eq "") and import GetDate 'getdate';
    unless ($HaveDateGetDate) {
      eval {
        require Time::ParseDate;
        sub parsedate { &Time::ParseDate::parsedate(@_) }
      };
      $HaveParseDate = ($@ eq "");
    }
  }
};

unless ($HaveGetDate or $HaveDateGetDate
        or $HaveParseDate) {
    eval join '', <DATA>;
    croak("Could not load my own date parsing: $@")
      if length($@);
}

use Net::Country;

sub new {
    my $type = shift;
    my %par  = @_;
    my $self = {};
    my ($sec,$min,$hours,$mday,$mon,$year, $time);

    %{$self} = %par;

    if ($par{Date}) {
        #print "$par{Date} => ";
        if ($HaveGetDate) {
            $par{Date} =~ s!(\d\d\d\d):!$1 !o;
            $par{Date} =~ s!/! !go;
            $time = getdate($par{Date});
        } elsif ($HaveDateGetDate) {
            $par{Date} =~ s!(\d\d\d\d):!$1 !o;
            $par{Date} =~ s!/! !go;
            $time = Date::GetDate::getdate($par{Date});
        } elsif ($HaveParseDate) {

            $time = parsedate($par{Date},
                                   FUZZY => 1,
                              NO_RELATIVE => 1);
        } else {
            $time = &Time::String::to_time($par{Date});
        }
	($sec,$min,$hours,$mday,$mon,$year) = localtime($time);
        #print "$par{Date} => (s>$sec,m>$min,h>$hours,m>$mday,m>$mon,y>$year)\n";
        $self->{Hour}  = sprintf "%02d", $self->{Hour}||$hours;
        $self->{Date}  = sprintf("%02d%02d%02d", $year%100, $mon+1, $mday);
    }
    if ($par{Host}) {
        my $host = $self->{Host}   = lc($par{Host});
        if ($host =~ /[^\d.]/) {
            if ($host =~ /\./) {
                $self->{Domain} = Net::Country::Name((split /\./, $host)[-1]);
            } else {
                $self->{Domain} = 'Local';
            }
        } else {
            $self->{Domain} = 'Unresolved';
        }
    }
    $self->{Records} = 1;

    bless $self, $type;
}

sub add {
    my $self   = shift;
    my $other  = shift;
    my $ignore = shift;

    for (keys %{$other}) {
        next if $_ eq $ignore;
        next unless defined $other->{$_};
        next unless length($other->{$_});
        next if $other->{$_} =~ /\D/;
        $self->{$_} += $other->{$_};
    }

    $self;
}

sub copy {
    my $self = shift;
    my %new  = %{$self};

    bless \%new, ref($self);
}

sub requests {$_[0]->{Records};}

1;

__DATA__

package Time::String;

use Time::Local;

my @moname = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %monnum;
my $monreg = '(' . join('|', @moname) . ')';

{ my $i = 0;
  for (@moname) {
      $monnum{lc($_)} = $i++;
  }
}

sub to_time {
    my $date = shift;
    my($sec,$min,$hours,$mday,$mon,$year) = (0)x3;

    #print "$date => ";
    if ($date =~ s!\b(\d+)/(\d+)/(\d+)\b! !) {
        ($mon, $mday, $year) = ($1, $2, $3);
        $mon--;
    } elsif ($date =~ s!\b(\d+)/(\w+)/(\d+)\b! !) {
        ($mday, $mon, $year) = ($1, $monnum{lc($2)}, $3);
    } elsif ($date =~ s!\b(\d+)\s+(\w+)\s+(\d+)\b! !) {
        ($mday, $mon, $year) = ($1, $monnum{lc($2)}, $3);
    } elsif ($date =~ s!\b$monreg\b(\s+(\d+))?! !io) {
        $mon = $monnum{lc($1)};
        $mday = $3;             # possibly not set
        if ($date =~ s/19(\d\d)/ /) {
            $year = $1;
        }
    }
    if ($date =~ s!\b(\d+):(\d+)(:(\d+))?! !) {
        ($hours, $min, $sec) = ($1, $2, $4);
    }
    $year -= 1900 if $year > 1900;
    
    #print "($sec,$min,$hours,$mday,$mon,$year);";

    my $gmtime = timegm($sec,$min,$hours,$mday,$mon,$year);
    if ($date =~ s!([-+]\d+)! !) {
        $gmtime += $1*36;
    }
    $gmtime;
}

1;
