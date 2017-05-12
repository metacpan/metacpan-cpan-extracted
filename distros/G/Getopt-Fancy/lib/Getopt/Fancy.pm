package Getopt::Fancy;

use strict;
use Getopt::Long;

use vars qw($VERSION);

$VERSION = "0.06";

# GT      = GetOptions spefication (=i, :s, etc)
# EX      = Example arg
# DESC    = Description of arg
# DEF     = Default value
# REQ     = Required arg
# ALLOWED = List of allowed values
# COMMAS  = Allow comma separated values for multi valued guys
# SECTION = The section the arg belongs under (when printing usage)
# REGEX   = regex that the arg has to match

Getopt::Long::Configure ("no_ignore_case");

our %config;
our %intvars;
  
sub new
{
  my $type = shift;
  my $class = ref($type) || $type;
  my $self = bless {}, $class;
  $intvars{$self}->{maxexlen} = 0;
  $intvars{$self}->{maxoptlen} = 0;
  return $self;
}

sub add
{
  my $self = shift;
  my $key = shift;
  my %values = @_;
  my ($aref, $val);
  my $use_yiv = 1;

  return unless $key;
  $intvars{$self}->{maxoptlen} = length ($key) if (length($key) > $intvars{$self}->{maxoptlen});
  $intvars{$self}->{maxexlen} = length ($values{EX}) if ($values{EX} && length($values{EX}) > $intvars{$self}->{maxexlen});
  if ($values{YIV}) {
    if (! ref $values{YIV}) {
      $aref = [$values{YIV}];
    } else {
      $aref = $values{YIV};
    }
    foreach $val (@{$aref}) {
      if (length($val) == 0 || $val =~ m/\$\(.*?\)/o) {
        $use_yiv = 0;
        last;
      }
    }
    $values{DEF} = $values{YIV} if $use_yiv;
  }
  $config{$self}->{$key} = \%values;
}

sub get_values
{
  my $self = shift;
  my ($key, $result, $values);
  my $spaces = " " x ($intvars{$self}->{maxoptlen} + 5);
  my $maxoptlen = $intvars{$self}->{maxoptlen};

  foreach $key (keys %{$self}) {
    if (! ref $self->{$key}) {
      $values = [$self->{$key}];
    } else {
      $values = $self->{$key};
    }
    $result .= sprintf (" %-${maxoptlen}s => %s", $key, join("\n$spaces", @{$values}));
    $result .= "\n";
  }
  return $result;
}

sub get_error
{
  my $self = shift;
  return $intvars{$self}->{error_msg};
}

sub get_options
{
  my $self = shift;
  my ($key, $values, $value);

  # Set the =i, =s stuff
  my @gopts = map {$_ .= $config{$self}->{$_}->{GT};} keys %{$config{$self}};

  # Get the options
  if (!GetOptions($self, @gopts)) {
    $intvars{$self}->{error_msg} = "Invalid option.\n";
    return ($intvars{$self}->{error_msg});
  }

  # Set the default values
  foreach $key (keys %{$config{$self}}) {
    next unless (defined $config{$self}->{$key}->{DEF});
    next if (defined $self->{$key});
    if ($config{$self}->{$key}->{GT} &&
        index($config{$self}->{$key}->{GT}, "@") > 0 &&
        !ref $config{$self}->{$key}->{DEF}) {
      $self->{$key} = [$config{$self}->{$key}->{DEF}];
    } else {
      $self->{$key} = $config{$self}->{$key}->{DEF};
    }
  }

  # Expand any comma separated lists
  foreach $key (keys %{$config{$self}}) {
    next unless ($config{$self}->{$key}->{GT} && index($config{$self}->{$key}->{GT}, "@") > 0);
    next unless ($config{$self}->{$key}->{COMMAS});
    next unless (defined $self->{$key});
    $values = $self->{$key};
    $self->{$key} = [];
    foreach $value (@{$values}) {
      push @{$self->{$key}}, split(/\s*,\s*/, $value);
    }
  }


  # Check for required values
  foreach $key (keys %{$config{$self}}) {
    $intvars{$self}->{error_msg} .= "$key is required, but missing\n" if ($config{$self}->{$key}->{REQ} && ! defined $self->{$key});
  }

  # Check for REGEX conformity
  foreach $key (keys %{$config{$self}}) {
    next unless defined ($config{$self}->{$key}->{REGEX});
    next unless defined ($self->{$key});
    if (! ref $self->{$key}) {
      $values = [$self->{$key}];
    } else {
      $values = $self->{$key};
    }
    foreach $value (@{$values}) {
      $intvars{$self}->{error_msg} .= "$value not a valid value for $key. Does not match regex: ".$config{$self}->{$key}->{REGEX}."\n" if ($value !~ m/$config{$self}->{$key}->{REGEX}/);
    }
  }

  # Check for allowed values
  foreach $key (keys %{$config{$self}}) {
    next unless defined ($config{$self}->{$key}->{ALLOWED});
    next unless defined ($self->{$key});
    my $allowed;
    my %a;
    if (! ref $config{$self}->{$key}->{ALLOWED}) {
      $allowed = [$config{$self}->{$key}->{ALLOWED}];
    } else {
      $allowed = $config{$self}->{$key}->{ALLOWED};
    }
    map {$a{$_} = 1;} @{$allowed};
    
    if (! ref $self->{$key}) {
      $values = [$self->{$key}];
    } else {
      $values = $self->{$key};
    }
    foreach $value (@{$values}) {
      $intvars{$self}->{error_msg} .= "$value not a valid value for $key. Allowed values: " . join(", ", @{$allowed}) . "\n" unless ($a{$value});
    }
  }
  return $intvars{$self}->{error_msg};
}

sub check_for
{
  my $self = shift;
  my $key = shift;
  my $value = shift;
  my $item;

  foreach $item (keys %{$config{$self}}) {
    return 1 if ($config{$self}->{$item}->{$key} == $value);
  }
  return 0;
}

sub have_required
{
  my $self = shift;
  return $self->check_for("REQ", 1);
}

sub have_optional
{
  my $self = shift;
  return $self->check_for("REQ", 0);
}


sub get_usage
{
  my $self = shift;
  my $options = shift;
#  my $req_only = shift;
  my $spaces = " " x ($intvars{$self}->{maxexlen} + $intvars{$self}->{maxoptlen} + 7);
  my $maxexlen = $intvars{$self}->{maxexlen};
  my $maxoptlen = $intvars{$self}->{maxoptlen};
  my ($result, $key, $defs, @keys);
  my $section = "";

  if (defined $options) {
    @keys = @{$options};
  } else {
    @keys = sort { $config{$self}->{$a}->{SECTION} cmp $config{$self}->{$b}->{SECTION} or $a cmp $b} keys %{$config{$self}};
  }

  foreach $key (@keys) {
    my $req = "";
#    if (defined $req_only) {
#      next if ($req_only && !$config{$self}->{$key}->{REQ});
#      next if (!$req_only && $config{$self}->{$key}->{REQ});
#    }
    if (! ref $config{$self}->{$key}->{DEF}) {
      $defs = [$config{$self}->{$key}->{DEF}];
    } else {
      $defs = $config{$self}->{$key}->{DEF};
    }
    if ($section ne $config{$self}->{$key}->{SECTION}) {
      $section = $config{$self}->{$key}->{SECTION};
      $result .= "\n [${section}]:\n";
    }

    $req = "[REQ] " if $config{$self}->{$key}->{REQ};
    $config{$self}->{$key}->{DESC} =~ s/\n/\n$spaces/og if $config{$self}->{$key}->{DESC};
    $result .= sprintf "  -%-${maxoptlen}s %-${maxexlen}s : ${req}%s", $key, $config{$self}->{$key}->{EX}, $config{$self}->{$key}->{DESC};
    $result .= "\n${spaces}Default = " . join(", ", @{$defs}) if $config{$self}->{$key}->{DEF};
    $result .= "\n${spaces}Allowed = " . join(", ", @{$config{$self}->{$key}->{ALLOWED}}) if $config{$self}->{$key}->{ALLOWED};
    $result .= "\n";
  }
  return $result;
}

1;

__END__

=head1 NAME

Getopt::Fancy - Object approach to handling command line options, focusing on end user happiness

=head1 SYNOPSIS

    use Getopt::Fancy;

    my $opts = Getopt::Fancy->new();
    $opts->add("db", GT   => "=s",
                     EX   => "<db_name>",
                     DESC => "The database to dump. Leave unset for all databases.",
                     DEF  => "teen_titans",
                     ALLOWED => ["--all-databases", "mydb", "teen_titans"],
                     REGEX => '^[a-zA-Z0-9\_]+$',
                     REQ  => 0,
                     SECTION => "Required DB Params");

    # Allow just printing out of set options
    $opts->add("check_args", DESC => "Just print all the options", SECTION => "Misc Params");

    # Allow user to specify list of options s/he needs help with
    $opts->add("help", GT => ":s@", EX => "[option1,option2..]", 
               DESC => "Give option names and it'll print the help for just those options, otherwise all.", 
               SECTION=>"Misc Params", COMMAS=>1);

    # Get the command line options
    my $error_msg = $opts->get_options();
    print_usage($error_msg) if $error_msg;

    print "Will dump this database: $opts->{db} \n";
    print "User wants help information on these: " . join(", ", @{$opts->{help}}) . "\n" if ($opts->{help});

    # Copy the options to a hash
    my %opts_hash = %{$opts};

    print "This is my copy of db: $opts_hash{db}\n";


    print_usage() if $opts->{help};
    print_args() if $opts->{check_args};

    sub print_args
    {
      print $opts->get_values();
      exit(0);
    }
 
    sub print_usage
    {
       my $hopts;
       my $msg = shift;

       $hopts = $opts->{help} unless (scalar @{$opts->{help}} == 0);
       print "usage: $0 <REQUIRED_ARGS> <OPTIONAL_ARGS>\n";
       print $opts->get_usage($hopts);

       print "ERROR: $msg\n" if $msg;

       exit(0);
    }

=head1 DESCRIPTION

C<Getopt::Fancy> Allows command line options to be all in one place in your script
including default values, allowed values, user-friendly descriptions,
required flags and pattern matching requirements. Ofttimes script writers skimp
on the usage information or have out-dated help information. This modules helps
script writers to be better citizens.

This module uses Getopt::Long, so the same rules apply.

=head1 METHODS

=over 4

=item C<my $opts = GetOpt::Fancy-E<gt>new()>

Construct a new object.

=item C<$opts-E<gt>add($opt_name, %config)>

C<add()> is where you specify the command line options you want to accept
and the configuration for each.

    $opts->add("hostname", GT   => "=s",
                           EX   => "<my_hostname>",
                           DESC => "The hostname to connect to to do whatever.",
                           DEF  => "batcomputer",
                           REGEX => '^[a-zA-Z0-9\_\-\.]+$',
                           SECTION => "Connection Params");

The possible config values are ...

=over 4

=item *

GT - The Getopts type specification (=i, :s, =s@, etc)

=item *

DEF - The default value for this option if the user running your script doesn't give one. If the option is multivalued,
pass in a reference to an array of values.

=item *

REQ - A flag (1 or 0) denoting if this option is required. (You can just leave this out if it's 0)

=item *

REGEX - A regular expression the value must match.

=item *

ALLOWED - A reference to an array of allowed values. This allows you to restrict the set.

=item *

COMMAS - A flag (1 or 0) denoting if this multivalued option should allow comma separated values.
This only applies to options that have a "@" in their GT (=s@, etc). If this is set, the user of your script
can specify multiple values by just doing something like: -colors red,green,blue

=item *

EX - A human readable example value for the user of your script that is printed during -help

=item *

DESC - A human readable description of the option for the user of your script that is printed during -help

=item *

SECTION - A human readable section header  for the user of your script that is printed during -help. This allows
you to group similar options together

=back

=item C<$opts-E<gt>get_options()>

Call this when it's time to read and parse the command line options. It will return a human readable string describing to the
end user what they did wrong. If all is well, returns undef.

After you call this, you can then treat $opts as a hash ref: $opts->{my_option}

=item C<$opts-E<gt>get_usage([optional,list,of,options])>

Returns a pretty, printable string of all the possible options, example values, descriptions, allowed values and default
values, grouped by SECTION. If a reference to an array of option names is passed in, only usage information for those
options is included.

=item C<$opts-E<gt>get_values()>

Returns a pretty, printable string of all the options and currently set values.

The object pretends to be a hash ref, so if you want values themselves, just do:

    $opts->{my_option}

=item C<$opts-E<gt>get_error()>

Returns the human readable error string describing the error during the options handling. This
string is also returned after C<get_options>

=back

=head1 LEGALESE

Copyright 2006 by Robert Powers, 
all rights reserved. This program is free 
software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2006, Robert Powers <batman@cpan.org>
