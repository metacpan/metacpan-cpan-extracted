
require 5;
package Getopt::Janus::SessionBase;
$VERSION = '1.03';
use strict;
use Getopt::Janus (); # makes sure Getopt::Janus::DEBUG is defined
BEGIN { *DEBUG = \&Getopt::Janus::DEBUG }

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub get_option_values { die "ABSTRACTY" }  # must override in subclass

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub string   { shift->register_option( 'string'  , @_) }
sub yes_no   { shift->register_option( 'yes_no'  , @_) }
sub new_file { shift->register_option( 'new_file', @_) }
sub file     { shift->register_option( 'file'    , @_) }
sub choose   { shift->register_option( 'choose'  , @_) }

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub warm_up {''} # can override in subclass

sub to_run_in_eval {''} # can override in subclass

sub report_run_error { die 'ABSTRACTY'}
 # must override in subclass, IF you override to_run_in_eval with a positive value

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
use Carp qw( confess );
use UNIVERSAL ();

sub set_title { $_[0]{'title'} = $_[1] }
sub set_desc  { $_[0]{'description'}  = $_[1] }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub register_option {
  my $self = shift;
  my $type = shift;
  my $slot = shift;
  my($long, $short) = @$self{ 'long', 'short' };

  DEBUG > 1 and print "Register_option is hitting $type with options ",
    map("<$_> ", @_), "\n";

  confess "Not enough options to $short?!" unless @_;

  my($short_count, $long_count);
  my $new = { 'type' => $type, 'slot' => $slot };
  
  while( @_ and defined $_[0] and !ref($_[0]) and $_[0] =~ m/^-/s ) {
    my $switch = shift;
    if($switch =~ s/^-([_0-9a-zA-Z])$/$1/s) {
      DEBUG > 2 and print "Declaring with short switch -$switch\n";
      confess "But there's already a \"-$switch\" switch defined!"
       if $short->{$switch} and $short->{$switch}{'type'} ne 'HELP';
      $short->{$switch} = $new;
      $new->{'short'} = $switch;
      ++$short_count;

    } elsif($switch =~ s/^--([-_0-9a-zA-Z]{2,})$/$1/s) {
      DEBUG > 2 and print "Declaring with long switch --$switch\n";
      confess "But there's already a \"--$switch\" switch defined!"
       if $long->{$switch} and $long->{$switch}{'type'} ne 'HELP';
      $long->{$switch} = $new;
      $new->{'long'} = $switch;
      ++$long_count;

    } else {
      confess "Illegal switchname \"$switch\" being declared";
    }
  }

  confess "No switchnames specified!?" unless $long_count || $short_count;

  # string $x, '-x';
  # string $x, '-x', \'Thingy', k=>v, k=>v,...;
  # string $x, '-x', \'Thingy', \'This is a thingy', k=>v, k=>v,...;

  if(@_ and ref($_[0] || '') eq 'SCALAR') {
    $new->{'title'} = ${ shift(@_) };
    DEBUG > 2 and print "Noting option-title \"$$new{'title'}\"\n";

    if(@_ and ref($_[0] || '') eq 'SCALAR') {
      $new->{'description'} = ${ shift(@_) };
      DEBUG > 2 and print "Noting option-desc \"$$new{'description'}\"\n";
    }
  }

  confess "Uneven number of parameter items in call to $type: @_" if @_ % 2;

  while( @_ ) {
    my($k,$v) = splice(@_,0,2);
    confess "Can't use undef as an parameter name!" unless defined $k;
    confess "Can't use empty-string as an parameter name!" unless length $k;
    DEBUG > 2 and print "Setting parameter \"$k\" to ",
     defined($v) ? "\"$v\"" : "(undef)",  ".\n";
    confess "Parameter \"$k\" is already set!" if exists $new->{$k};
    $new->{$k} = $v;
  }

  $self->note_new_option( $new );

  push @{ $self->{'options'} }, $new;

  return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub note_new_option {
  my($self, $option) = @_;
  my $m = 'note_new_option_' . $option->{'type'};
  $self->$m($option) if $self->can($m);
  return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub prep_options {
  my($self) = @_;
  foreach my $o (@{ $self->{'options'} } ) {
    $self->prep_option($o);
  }
  return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub prep_option {
  my($self, $option) = @_;
  my $m = 'prep_option_' . $option->{'type'};
  $self->$m($option) if $self->can($m);
  return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub prep_option_choose {
  my($self, $option) = @_;
  my $c = ($option->{'from'} ||= ['NONE DEFINED']);
  return unless @$c; # I guess?
  
  # Force it to be one of the choices
  for my $val ( ${ $option->{'slot'} } ) { # "for" just to get aliasing
    if(defined $val) {
      # just fall thru to the check
    } elsif(defined $option->{'default'}) {
      $val = $option->{'default'};
    } else {
      $val = $c->[0];  # most common case: set to first.
    }
    confess "$val isn't any of the allowed values {@$c}"
     unless grep $val eq $_, @$c;
  }
  return;
}

sub prep_option_string { } # I can't thing of anything that needs doing.

sub prep_option_yes_no {
  my($self, $option) = @_;
  for my $val ( ${ $option->{'slot'} } ) { # "for" just to get aliasing
    $val = !! $val;  # reduce to just boolean
  }
  return;
}

sub prep_option_new_file {
  my($self, $option) = @_;
  for my $slot ( $option->{'slot'} ) { # happy aliasing
    if( defined $$slot and $$slot =~ m/\e/ ) {
      $$slot = $self->_new_out( $$slot );
    }
    if( defined $$slot and length $$slot) {
      push @Getopt::Janus::New_files, $slot;
      DEBUG and print "Potential new-file: $slot",
        ref($slot) ? " ($$slot)" : '',
        "\n  from ",
        $option->{'long'} || $option->{'short'}, ".\n";
    } else {
      DEBUG and print "Snoozing thru new-file option ",
        $option->{'long'} || $option->{'short'}, ".\n";
    }
  }
  return;
}

#==========================================================================
sub run {
  my($self, $sub, $title, $desc) = @_;
  
  confess "first argument to run() should be a subref"
   unless ref($sub) and UNIVERSAL::isa($sub, 'CODE');
  
  $title = $$title if $title and ref($title) eq 'SCALAR';
  $desc  = $$desc  if $desc  and ref($desc ) eq 'SCALAR';
  $self->set_title($title || $0);
  $self->set_desc($desc) if $desc;
  
  $self->prep_options;
  
  $self->get_option_values;
  
  if( $self->to_run_in_eval ) {
    DEBUG and print "Running $sub in an eval...\n";

    eval { local $SIG{'__DIE__'}; &$sub; };

    if( $@ ) {
      DEBUG and print "That threw an error: $@\n";
      $self->report_run_error($@);
    } else {
      DEBUG and print "That didn't throw any errors.\n";
    }
  } else {
    DEBUG and print "Not running $sub in an eval.\n";
    &$sub;
  }

  DEBUG and print "Starting cleanup.\n";
  $self->cleanup();
  DEBUG and print "Ending cleanup.\n";

  DEBUG and print "Now exiting.\n";
  exit;
}
#==========================================================================

sub cleanup {
  my $self = shift;
  $self->review_result( \@Getopt::Janus::New_files );
  return;
}

#==========================================================================

sub review_result {
  my($self, $them) = @_;

  unless(@$them) {
    DEBUG and print "No files to consider.\n";
    return;
  }
  require File::Basename;
  
  if(DEBUG > 1) {
    print "Contents of new_files:\n";
    foreach my $i (@$them) {
      print "  [", ref($i) ? "$i = $$i" : $i, "]\n";
    }
  }
  
  my(@to_display, %seen, $f_out);
  foreach my $f (@$them) {
    next unless defined $f;
    $f = $$f if ref $f eq 'SCALAR';
    next unless defined $f and length $f;
    
    DEBUG > 2 and print "  Considering [$f]\n";

    return if $f eq ".NO."; # magic value
    
    next if $seen{$f}++; # no repeats
    unless( -e $f ) {
      DEBUG and print "   $f doesn't exist\n";
      next;
    }
    unless( -r _ ) {
      DEBUG and print "   $f doesn't readable\n";
      next;
    }

    if(-f _) {
      if(-s _) {
        DEBUG and print "   A good file: $f\n";
        $f_out = $f;
      } else {
        DEBUG and print "   But it's 0-length: $f\n";
        $f_out = undef;
      }
      my $d = File::Basename::dirname( $f );
      $d = '.' if $d eq $f or !length $d;
      push @to_display, [$f    => $d];
    } elsif(-d _) {
      DEBUG and print "  A dir: $f\n";
      push @to_display, [undef => $f];
    } else {
      DEBUG and print "   Odd, what's a $f ?!\n";
    }
  }

  if(DEBUG > 1) {
    print "Contents of to_display: [\n";
    foreach my $i (@to_display) {
      print "  [", ref($i) ? "$i = $$i" : $i, "]\n";
    }
    print "]\n";
  }

  $self->review_result_screen(\@to_display);
  return;
}

sub review_result_screen {
  my($self, $to_display) = @_; # override in a subclass
  return unless @$to_display;
  return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub can_open_files       { $^O =~ m/Win32/ or $^O =~ m/darwin/ };
sub can_open_directories { $^O =~ m/Win32/ or $^O =~ m/darwin/ };

sub open_directory {
  my($self, $i) = @_;
  return $self->open_file($i)
   if $^O =~ m/Win32/ or $^O =~ m/darwin/;
  return;
}

sub open_file {
  my($self, $i) = @_;
  
  if($^O =~ m/darwin/) { 
    # Thanks to Elaine Ashton and Anno Siegel for help on this
    return unless defined $i and length $i;
    DEBUG and print "\nCalling system 'open', $i\n";
    sleep 0;
    system "open", $i;
    sleep 0;
    DEBUG and print "\n";

  } elsif($^O =~ m/Win32/) {
    # Thanks to Elaine Ashton and Anno Siegel for help on this
    return unless defined $i and length $i;
    DEBUG and print "Calling system 'start', qq{\"$i\"}\n";
    sleep 0;
    system "start", qq{"$i"};
    sleep 0;
    DEBUG and print "\n";
  }
  return;
}



#==========================================================================

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $new = bless { short => {}, long => {}, options => [] }, $class;
  DEBUG and print "New $class object.\n";
  $new->_init;
  return $new;
}

# can override in a subclass, if you also call $self->SUPER::_init
sub _init {
  my $self = $_[0];
  $self->{'long' }{'help'} =
  $self->{'short'}{'h'   } =
   {
     'type'  => 'HELP',
     'short' => 'h',
     'long'  => 'help',
     'slot'  => do { my $x; \$x; },   # a dummy slot
     'title' => "Usage summary / general help",
   };
  return;
}

#==========================================================================

sub _new_out {
  # Use like: $outname = $self->_new_out("thing\e.txt");
  #       "\e" means "provide an incremented number here"
  my($self, $in) = @_;

  confess "Can't go on the basis of a null file-specification"
   unless defined $in and length $in;  # sanity

  require File::Basename;
  my $pattern = File::Basename::basename($in);

  my($before, $after) = split "\e", $pattern, 2;
  $after = '' unless defined $after;
  {
    # whip up the pattern:
    my $pat_before = quotemeta $before;
    my $pat_after  = quotemeta $after;
    $pattern = qr/^$pat_before(\d+)$pat_after$/is;
    DEBUG > 1 and print "Made pattern $pattern from $in\n";
  }
  
  # Look for matching files:
  my $dir = File::Basename::dirname($in);
  DEBUG > 2 and print "Dirname of [$in] is [$dir]\n";
  DEBUG > 1 and print "opendir on $dir for $in\n";
  $dir = '.' unless defined $dir;
  opendir(GOODINDIR, $dir) || confess "Can't opendir $dir: $!";
  my $max = -1;
  {
    my $this;
    while( defined($this = readdir(GOODINDIR)) ) {
      next unless $this =~ $pattern;
      if( $1 > $max ) {
        $max = 0 + $1;
        DEBUG > 5 and print " Hm, $this is highest so far.\n";
      }
    }
  }
  closedir(GOODINDIR);
  
  # Now make a filename with one greater:
  if( $max == -1 ) { # none seen
    $max = 100;  # a good starting number
  } else {
    $max++;    # just use one higher than the max
  }
  my $out = $in;
  $out =~ s/\e/$max/  or  $out .= $max;
  DEBUG > 1 and print "_better_out returns $out\n";
  return $out;
}

#==========================================================================
# Generate the methods for particular licenses:

foreach my $licname (qw< artistic gnu either >) {
  my $sub = sub {
    require Getopt::Janus::Licenses;
    @{ $_[0] }{ 'license', 'license_short' } = do {
      no strict 'refs';
      *{"Getopt::Janus::Licenses::$licname"}{CODE} ,
      *{"Getopt::Janus::Licenses::$licname\_short"}{CODE};
    };
    1;
  };
  { no strict 'refs'; *{"license_$licname"} = $sub; }
}
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub _help_message {
  my($self, $long) = @_;
  $long ||= ''; # so it's not undef

  my @out = "Options:\n" . ($long && "\n");
  unshift @out, ( join ' -- ', grep $_,
      $self->{'title'}, $self->{'description'}
    ) . "\n" . ($long && "\n") if $self->{'description'} or $self->{'title'};

  my($type);
  my %seen;
  foreach my $o (@{ $self->{'options'} } ) {
    my $switch = $o->{'short'} ? ( '-' . $o->{'short'})
               : $o->{'long' } ? ('--' . $o->{'long' })
               : next
    ;
    ++$seen{ $o->{'short'} }  if  defined $o->{'short'};
    ++$seen{ $o->{'long' } }  if  defined $o->{'long' };
    $type = $o->{'type'} || 'No type';
    if( $type eq 'yes_no' ) {
      # nothing to add
    } elsif( $type eq 'string' ) {
      $switch .= '=value';
    } elsif( $type eq 'file' ) {
      $switch .= "=file";
    } elsif( $type eq 'new_file' ) {
      $switch .= "=new_file";
    } elsif( $type eq 'choose' ) {
      $switch .= join '' => ( "=option",
        $long ?
          ( "\n    (One of: ", join(q<, >, map qq{"$_"}, @{$o->{'from'}}) )
        : ( " (one of: ", join(q<|>, @{$o->{'from'}}) ),
        ")"
      );
    } else {
      $switch .= " [of type $type]"
    }
    
    if($long and $o->{'short'} and $o->{'long'}) {
      $switch =~ s[^(-.(\S*))]
                  [$1 or --$$o{'long'}$2]s
       or (DEBUG and print "INSANE switch value $switch\n");
    }
    
    push @out, $long ?
       ("$switch\n    ", $o->{'description'} || $o->{'title'} || '')
     : ("$switch :: "  , $o->{'title'} || $o->{'description'} || ''), "\n"  ;
  }
  push @out, "-h     :: show a short help message\n" unless $seen{'h'};
  push @out, "--help :: show a long help message\n"  unless $seen{'help'};
  push @out, "\n", $self->{'license_short'}->() if $self->{'license_short'};
  
  return join '', @out;
}


# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub short_help_message {
  my($self) = @_;

  my @out = "Options:\n";
  unshift @out, ( join ' -- ', grep $_,
      $self->{'title'}, $self->{'description'}
    ) . "\n" if $self->{'description'} or $self->{'title'};

  my($type);
  my %seen;
  foreach my $o (@{ $self->{'options'} } ) {
    my $switch = $o->{'short'} ? ( '-' . $o->{'short'})
               : $o->{'long' } ? ('--' . $o->{'long' })
               : next
    ;
    ++$seen{ $o->{'short'} }  if  defined $o->{'short'};
    ++$seen{ $o->{'long' } }  if  defined $o->{'long' };
    $type = $o->{'type'} || 'No type';
    if( $type eq 'yes_no' ) {
      # nothing to add
    } elsif( $type eq 'string' ) {
      $switch .= '=value';
    } elsif( $type eq 'file' ) {
      $switch .= "=file";
    } elsif( $type eq 'new_file' ) {
      $switch .= "=new_file";
    } elsif( $type eq 'choose' ) {
      $switch .= "=option (one of: " . join(q<|>, @{$o->{'from'}}) . ")";
    } else {
      $switch .= " [of type $type]"
    }
    push @out,
     "$switch :: ", $o->{'title'} || $o->{'description'} || '', "\n";
  }
  push @out, "-h     :: show a short help message\n" unless $seen{'h'};
  push @out, "--help :: show a long help message\n"  unless $seen{'help'};
  push @out, "\n", $self->{'license_short'}->() if $self->{'license_short'};
  
  return join '', @out;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub long_help_message {
  my($self) = @_;

  my @out = "Options:\n\n";
  unshift @out, ( join ' -- ', grep $_,
      $self->{'title'}, $self->{'description'}
    ) . "\n\n" if $self->{'description'} or $self->{'title'};
  my($type);
  my %seen;
  foreach my $o (@{ $self->{'options'} } ) {
    my $switch = $o->{'short'} ? ( '-' . $o->{'short'})
               : $o->{'long' } ? ('--' . $o->{'long' })
               : next
    ;
    ++$seen{ $o->{'short'} }  if  defined $o->{'short'};
    ++$seen{ $o->{'long' } }  if  defined $o->{'long' };
    $type = $o->{'type'} || 'No type';
    if( $type eq 'yes_no' ) {
      # nothing to add
    } elsif( $type eq 'string' ) {
      $switch .= '=value';
    } elsif( $type eq 'file' ) {
      $switch .= "=file";
    } elsif( $type eq 'new_file' ) {
      $switch .= "=new_file";
    } elsif( $type eq 'choose' ) {
      $switch .= "=option\n    (One of: " .
        join(q<, >, map qq{"$_"}, @{$o->{'from'}}) . ")";
    } else {
      $switch .= " [of type $type]"
    }

    if($o->{'short'} and $o->{'long'}) {
      $switch =~ s/^(-.(\S*))/$1 or --$$o{'long'}$2/s or print "WHAT $switch";
    }
    push @out,
     "$switch\n    ", $o->{'description'} || $o->{'title'} || '', "\n";
  }
  push @out, "-h     :: show a short help message\n" unless $seen{'h'};
  push @out, "--help :: show a long help message\n"  unless $seen{'help'};
  push @out, "\n", $self->{'license_short'}->() if $self->{'license_short'};
  
  return join '', @out;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

1;
__END__

