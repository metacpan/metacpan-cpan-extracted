
require 5;
package Getopt::Janus::CLI;
# Get command-line interface options (yup, from @ARGV)

@ISA = ('Getopt::Janus::SessionBase');
$VERSION = '1.03';
use strict;
use Getopt::Janus (); # makes sure Getopt::Janus::DEBUG is defined
BEGIN { *DEBUG = \&Getopt::Janus::DEBUG }
use Getopt::Janus::SessionBase;

Getopt::Janus::DEBUG and print "Revving up ", __PACKAGE__, "\n";

sub open_new_files { }  # block it happening

# TODO: make -h / --help produce help/longhelp (latter with license)

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub review_result { }  # no need for this all

sub get_option_values {
  my $self = shift;

  if($^O =~ m/Win32/) {
    while( @ARGV and !length $ARGV[-1] ) { pop @ARGV }
  }

  my $run_flag = 1;
  my @args = @ARGV;
  my %unknowns;

  my @values;
  $self->parse_values(\@values, \@args, \%unknowns, \$run_flag);

  if( $run_flag ) {
    DEBUG and print "parse_values has run_flag on, with values @values\n";
    $self->consider_values( \@values );
  } else {
    DEBUG and print "parse_values has run_flag off\n values [@values]",
      "\n unknowns [@{[sort keys %unknowns]}]\n args [@args]\n";
    $self->complain_about( \@args, \%unknowns );
    exit 1;
  }
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub parse_values {
  my($self, $values, $args, $unknowns, $run_flag_s) = (@_);
  my($long, $short) = @$self{ 'long', 'short' };

  my $dummy = {'type' => 'yes_no', "_HACK_", 1};

  local $_;
  while(@$args) {
    $_ = $args->[0];
    last  if  $_ eq '-';  # not a switch at all
    shift(@$args), last  if  $_ eq '--'; # switch meaning 'end of switches'

    if( m/^-([_0-9a-zA-Z])$/s or m/^--?([-_0-9a-zA-Z]{2,})$/s ) { # -x or --xax
        # And tolerate -xax
      if(not( $short->{$1} || $long->{$1} )) {
        ++$unknowns->{$1};
        DEBUG and print "Unknown option $1\n";
        shift @$args;
      } elsif(
         'yes_no' eq ( $short->{$1} || $long->{$1} )->{'type'}
        or 'HELP' eq ( $short->{$1} || $long->{$1} )->{'type'}
      ) {
        push @$values, $1 => 1;  # just note it as a true value and move on
        shift @$args;
      } else {
        # It's a nonboolean value -- so snare the value and re-cycle
        #  it as a -x=foo or --xax=foo for the next pass
        push @$args, '' if @$args == 1 and $^O =~ m/Win32/;
        $args->[0] .= '=' . splice(@$args,1,1);
      }

    } elsif( m/^-([_0-9a-zA-Z])=(.*?)$/s ) {  # -x=foo
      unless( exists $short->{$1} ) {
        ++$unknowns->{$1};
      } else {
        push @$values, $1 => $2;
      }
      shift(@$args);
      
    } elsif( m/^--?([-_0-9a-zA-Z]{2,})=(.*?)$/s ) {  # --xax=foo
       # and tolerate -xax=foo
      unless( exists $long->{$1} ) {
        ++$unknowns->{$1};
      } else {
        push @$values, $1 => $2;
      }
      shift(@$args);

    } else {
      $$run_flag_s = 0;
      last;   # leaving things unprocessed
    }
  }
  $$run_flag_s = 0 if keys %$unknowns or @$args;
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub complain_about {
  my( $self, $args, $unknowns ) = @_;
  
  if( keys %$unknowns ) {
    my @them = sort keys %$unknowns;
    foreach (@them) { s/^(.)$/-$1/s or s/^(.+)$/--$1/s } # add the prefixes
    print "Unknown options that you used: [@them]\n\n"
  }
  print "Arguments left unprocessed: [@$args]\n\n"  if  @$args;
  print $self->short_help_message;
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub consider_values {
  my( $self, $values ) = @_;
  my($long, $short) = @$self{ 'long', 'short' };
  
  my %seen;
  my($option, $key, $value, $type, $oldval);
  DEBUG and print "Values: @$values\n";
  while( @$values ) {
    $key    = $values->[0];
    $option = ( (length($key) == 1) ? $short : $long )->{$key};
    ++$seen{$option};
    $type   = $option->{'type'};
    my $slot_r = $option->{'slot'};
    $oldval = $$slot_r;
    $$slot_r = $values->[1];

    splice @$values,0,2;

    DEBUG and print "Option \"$key\" = \"$$slot_r\"\n";

    if( $type eq 'HELP' ) {
      print '', (length($key) == 1)
        ? $self->short_help_message : $self->long_help_message;
      exit;
    }
    
    if( $seen{$option} > 1 ) {
      print "Duplicate setting for option ",
        join('/', grep defined($_), @$option{'short', 'long'}),
        ":  \"$oldval\" and \"$$slot_r\".\n";
      exit;
    }

    if( $type eq 'yes_no' ) {
      DEBUG > 1 and print "(Type $type needs no checking.)\n";
      
    } elsif( $type eq 'string' ) {
      DEBUG > 1 and print "(Type $type needs no checking.)\n";

    } elsif( $type eq 'new_file' ) {
      if(!length $$slot_r) {
        #die "Option $key can't take \"\" as a value" unless length $$slot_r;
        # No, it's okay to set this to null.
      } else {
        # Any further checking?
      }

    } elsif( $type eq 'file' ) {
      if(!length $$slot_r) {
        #die "Option $key can't take \"\" as a value" unless length $$slot_r;
        # No, it's okay to set this to null.
      } else {
        -e $$slot_r or die "Setting to a non-existent file in $key=$$slot_r\n";
        -d _       and die "Setting to a directory in $key=$$slot_r\n";
        -f _        or die "Setting to a non-file in $key=$$slot_r\n";
        -r _        or die "Setting to an unreadable file in $key=$$slot_r\n";
        DEBUG > 1 and print "File $$slot_r checks out.\n";
      }

    } elsif( $type eq 'choose' ) {
      if( grep $_ eq $$slot_r, @{$option->{'from'}} ) { 
        DEBUG > 1 and print "Choice $$slot_r checks out.\n";
      } else {
        die(
         "Option $key=$$slot_r needs to be one of: [" . 
          join( '|',  @{$option->{'from'}}) . "]\n"
        );
      }
      
    } else {
      DEBUG and print "I don't know how to check an option of type $type\n";
    }

  }


  
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
1;

__END__

