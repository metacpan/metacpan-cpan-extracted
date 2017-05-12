#-----------------------------------------------------------------------------
# File: Brick_mason.pm
#
# This package encapsulates Mason components within a perl class.
#-----------------------------------------------------------------------------

package HTML::Bricks::Brick_mason;

use strict;

use HTML::Bricks::Config;
use HTML::Mason;
use HTML::Mason::Parser;
use HTML::Mason::Component;
use HTML::Mason::Request;

use Carp;

use vars qw($AUTOLOAD);

my %comp_cache;

our $VERSION = '0.02';

my $parser = new HTML::Mason::Parser();
my $interp = new HTML::Mason::Interp (parser => $parser,
                                      comp_root => $HTML::Bricks::Config{bricks_root},
                                      data_dir => $HTML::Bricks::Config{mason_data_root},
 				      max_recurse => 256,
      				      out_mode => 'stream',
    				      out_method => sub { 
                                        return if !defined $HTML::Bricks::enable_output;
                                        my $d = shift; 
                                        print $d if defined $d });

my $request = new HTML::Mason::Request(interp => $interp);
$HTML::Mason::Commands::m = $request;
$interp->set_global('m' => $request);

#-----------------------------------------------------------------------------
# get_bricks_list
#-----------------------------------------------------------------------------
sub get_bricks_list($$) {
  my ($rself, $rpaths) = @_;

  my $r = Apache->request;
  my @list;
 
  foreach my $path (@$rpaths) {

    my $fullpath = $HTML::Bricks::Config{bricks_root} . "/$path";

    opendir(PATH,$fullpath) || next;
    my @filenames = readdir(PATH);
    closedir(PATH);

    foreach (@filenames) {
      next if (-d $fullpath . "/$_");

      if ($_ =~ /(.*)\.mc$/) {
        my $name = $1;
        my $comp = load_comp("/$path/$_");

        next if $comp->method_exists('dont_list');
 
        push @list, $name;
      }
    }
  }

  return \@list;
}

#-----------------------------------------------------------------------------
# get_assemblies_list
#-----------------------------------------------------------------------------
sub get_assemblies_list($$) {
  my ($rself, $rpaths) = @_;

  my $r = Apache->request;
  my @list;
 
  foreach my $path (@$rpaths) {

    my $fullpath = $HTML::Bricks::Config{bricks_root} . "/$path";

    opendir(PATH,$fullpath) || next;
    my @filenames = readdir(PATH);
    closedir(PATH);

    foreach (@filenames) {
      next if (-d $fullpath . "/$_");

      if ($_ =~ /(.*)\.mc$/) {
        my $name = $1;
        my $comp = load_comp("/$path/$_");

        next if ! $comp->method_exists('is_assembly');

        push @list, $name;
      }
    }
  }

  return \@list;
}

#-----------------------------------------------------------------------------
# load_comp
#-----------------------------------------------------------------------------
sub load_comp($) {

  my ($comp_name) = @_;

  my $comp;
  my $r = Apache->request;
  my $file_name = $HTML::Bricks::Config{bricks_root} . $comp_name;

  use Apache::File;
  my $fh = Apache::File->new($file_name);
  return undef if !defined $fh;

  my @stat_data = stat($file_name);
  my $mtime = $stat_data[9];

  if ((!exists $comp_cache{$comp_name}) || (${$comp_cache{$comp_name}}[0] != $mtime)) {
    $comp = $interp->load($comp_name);

    if (defined $comp) {
      $comp_cache{$comp_name}[0] = $mtime;
      $comp_cache{$comp_name}[1] = $comp;
    }
  }
  else {
    $comp = ${$comp_cache{$comp_name}}[1]; 
  }
  
  return $comp;

}

#-----------------------------------------------------------------------------
# get_class_data
#-----------------------------------------------------------------------------
sub get_class_data($$$) {

  my ($rself, $rpaths, $brick_name) = @_;

  my $r = Apache->request;
 
  foreach my $path (@$rpaths) {
    
    my $comp_name = "/$path/$brick_name.mc";
    my $file_name = $HTML::Bricks::Config{bricks_root} . $comp_name;

    if (-e $file_name) {

      my $comp = load_comp($comp_name);
      last if !defined $comp;

      my %class_data;
      $class_data{comp} = $comp;
      $class_data{name} = $brick_name;
      $class_data{filename} = $comp_name;
      $class_data{class_name} = 'HTML::Bricks::Brick_mason';

      return \%class_data;
    }
  }

  return undef;

}

#-----------------------------------------------------------------------------
# fetch
#-----------------------------------------------------------------------------
sub fetch($$$) {

  my $ref = shift;
  my $rpaths = shift;
  my $brick_name = shift;

  my $rclass_data = get_class_data($ref,$rpaths,$brick_name);
  return undef if !defined $rclass_data;

  my $rself;

  $$rself{rsuper_class_data} = [];
  $$rself{class_level} = 0;

  push @{$$rself{rsuper_class_data}}, $rclass_data;

  bless $rself, 'HTML::Bricks::Brick_mason';
  $$rself{rclass_data} = $rclass_data;

  $$rself{name} = $$rclass_data{name};
  $$rself{data} = {};

  return $rself;
}

#-----------------------------------------------------------------------------
# push_supers
#-----------------------------------------------------------------------------
sub push_supers {
  my $rself = shift;

  my $rsuper_class_data = $$rself{rsuper_class_data};

  foreach (@_) {
    my $rclass_data = HTML::Bricks::get_class_data($_);
    push @$rsuper_class_data, $rclass_data;
  }
}

#-----------------------------------------------------------------------------
# AUTOLOAD
#-----------------------------------------------------------------------------
sub AUTOLOAD {

  my $rself = shift;

  (my $func = $AUTOLOAD) =~ s/^.*::(_?)//;

  unless ($1) {
    my $method = $rself->can($func);

    if ($method) {

#
#  Uncomment the following to print out the name of every mason brick and method called
#
#my $rd = @{$$rself{rsuper_class_data}}[$$rself{class_level}];
#print STDERR "$$rd{name}:$func $$rself{name} $$rself{class_level}\n";

      return &$method(@_);
    }
  }

return;
#  croak sprintf q{Can't locate object method "%s" via package "%s"}, $func, ref($rself);

}

#-----------------------------------------------------------------------------
# super
#-----------------------------------------------------------------------------
sub super {

  my $rself = shift;
  my $method;

  my $rsuper = {};
  %$rsuper = %$rself;

  $$rsuper{in_super} = ++$$rsuper{class_level};

  my $rclass_data = ${$$rself{rsuper_class_data}}[$$rsuper{class_level}];
  $$rsuper{rclass_data} = $rclass_data;

  # print STDERR "super: class_name=$$rsuper{name} super_class_name=$$rclass_data{name} $$rsuper{class_level}\n";

  bless $rsuper, $$rclass_data{class_name}; 


  return $rsuper;
}

#-----------------------------------------------------------------------------
# base 
#-----------------------------------------------------------------------------
sub base {

  my $rself = shift;
  my $method;

  my $rbase = {};
  %$rbase = %$rself;

  $$rbase{class_level} = 0;

  my $rclass_data = ${$$rself{rsuper_class_data}}[$$rbase{class_level}];
  $$rbase{rclass_data} = $rclass_data;

  bless $rbase, $$rclass_data{class_name}; 

  return $rbase;
}

#-----------------------------------------------------------------------------
# can
#-----------------------------------------------------------------------------
sub can {
  my ($rself, $func) = @_;

  my $method = UNIVERSAL::can($rself,$func);
  return $method if defined $method;

  return undef if !defined $$rself{rsuper_class_data};
  return undef if $func eq 'DESTROY';

  my $rclass_data = $$rself{rclass_data};

  if ((!exists $$rself{in_super}) && ($$rself{class_level} != 0)) {
    $method = $rself->base->can($func,@_);
  }
  elsif ($$rclass_data{comp}->method_exists($func)) {
    $method = sub { $$rclass_data{comp}->call_method($func,$rself,@_) };
  }
  elsif ($#{$$rself{rsuper_class_data}} > $$rself{class_level}) {
    # if there is a super class, then see if it has the method
    $method = $rself->super->can($func,@_);
  }

  delete $$rself{in_super};

  return $method;
}

1;
