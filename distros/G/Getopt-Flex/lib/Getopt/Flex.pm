package Getopt::Flex;
BEGIN {
  $Getopt::Flex::VERSION = '1.07';
}

# ABSTRACT: Option parsing, done different.

use strict; #shut up cpants
use warnings; #shut up cpants
use Clone;
use Hash::Merge qw(merge);
use Moose;
use MooseX::StrictConstructor;
use Getopt::Flex::Config;
use Getopt::Flex::Spec;

#return values for the function that
#determines the type of switch it is
#inspecting
my $_ST_LONG = 1;
my $_ST_SHORT = 2;
my $_ST_BUNDLED = 3;
my $_ST_NONE = 4;

#the raw spec defining the options to be parsed
#and how they are to be handled
has 'spec' => (
    is => 'ro',
    isa => 'HashRef[HashRef[Str|CodeRef|ScalarRef|ArrayRef|HashRef]]',
    required => 1,
	writer => '_set_spec',
);

#the parsed Getopt::Flex::Spec object
has '_spec' => (
    is => 'rw',
    isa => 'Getopt::Flex::Spec',
    init_arg => undef,
);

#the raw config defining any relevant configuration
#parameters               
has 'config' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    default => sub { {} },
);

#the parsed Getopt::Flex::Config object                
has '_config' => (
    is => 'rw',
    isa => 'Getopt::Flex::Config',
    init_arg => undef,
);

#the arguments passed to the calling script,
#clones @ARGV so it won't be modified                
has '_args' => (
    is => 'rw',
    isa => 'ArrayRef',
    init_arg => undef,
); 

#an array of the valid switches passed to the script               
has 'valid_args' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    writer => '_set_valid_args',
    reader => '_get_valid_args',
    init_arg => undef,
    default => sub { [] },
);

#an array of the invalid switches passed to the script                    
has 'invalid_args' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    writer => '_set_invalid_args',
    reader => '_get_invalid_args',
    init_arg => undef,
    default => sub { [] },
);

#an array of anything that wasn't a switch that was encountered                    
has 'extra_args' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    writer => '_set_extra_args',
    reader => '_get_extra_args',
    init_arg => undef,
    default => sub { [] },
);
                    
#error message, for reporting more info about errors
has 'error' => (
    is => 'ro',
    isa => 'Str',
    writer => '_set_error',
    reader => 'get_error',
    init_arg => undef,
    default => '',    
);


sub BUILD {
    my $self = shift;
    
    #set args from argv
    $self->_args(Clone::clone(\@ARGV));
    
    #create the configuration
    $self->_config(Getopt::Flex::Config->new($self->config()));
    
    #create the spec
    $self->_spec(Getopt::Flex::Spec->new({ spec => $self->spec(), config => $self->_config() }));
    
    return;
}


sub getopts {
    my ($self) = @_;
    
    my @args = @{$self->_args()};
    my @valid_args = ();
    my @invalid_args = ();
    my @extra_args = ();
    
    my $non_opt_mode = $self->_config()->non_option_mode();
    
    PROCESS: for(my $i = 0; $i <= $#args; ++$i) {
        my $item = $args[$i];
        
        #stop processing immediately
        last if $item =~ /^--$/;
        
        #not a switch, so an extra argument
        if(!$self->_is_switch($item)) {
            push(@extra_args, $item);
            
            if($non_opt_mode eq 'STOP_RET_0') {
                $self->_set_error("Encountered illegal item $item");
                return 0;
            } elsif($non_opt_mode eq 'STOP') {
                last;
            } elsif($non_opt_mode eq 'VALUE_RET_0') {
                $self->_set_error("Encountered illegal value $item");
                return 0;
            }

            next;
        }
        
        #if we have a switch, parse it and return any values we encounter
        #there are a few ways that values are returned: as scalars, when
        #the accompanying value was not present in the switch passed (i.e.
        #the form "-f bar" was encountered and not "-fbar" or "-f=bar").
        #If an array is returned, the value accompanying the switch was
        #found with it, and $arr[0] contains the switch name and $arr[1]
        #contains the value found. If a hash is returned, it was a bundled
        #switch, and the keys are switch names and the values are those
        #values (if any) that were found.
        my $ret = $self->_parse_switch($item);
        
        #handle scalar returns
        if(ref($ret) eq 'SCALAR') {
            $ret = $$ret; #get our var
            
            if(!$self->_spec()->check_switch($ret)) {
                push(@invalid_args, $ret);
                if($non_opt_mode eq 'STOP_RET_0') {
                    $self->_set_error("Encountered illegal switch $ret");
                    return 0;
                } elsif($non_opt_mode eq 'STOP') {
                    last;
                } elsif($non_opt_mode eq 'SWITCH_RET_0') {
                    $self->_set_error("Encountered illegal switch $ret");
                    return 0;
                }
                next;
            }
            
            if($self->_spec()->switch_requires_val($ret)) { #requires a value?
                #peek forward in args, because we didn't find the
                #necessary value with the switch
                if(defined($args[$i+1]) && !$self->_is_switch($args[$i+1])) {
                    if($self->_spec()->set_switch($ret, $args[$i+1])) {
                        push(@valid_args, $ret);
                        ++$i;
                    } else {
                        $self->_set_error($self->_spec()->get_switch_error($ret));
                        return 0;
                    }
                } else {
                    $self->_set_error("switch $ret requires value, but none given\n");
                    return 0;
                }
            } else { #doesn't require a value, so just use 1
                if($self->_spec()->set_switch($ret, 1)) {
                    push(@valid_args, $ret);
                } else {
                    $self->_set_error($self->_spec()->get_switch_error($ret));
                    return 0;
                }
            }
        #handle hash returns
        } elsif(ref($ret) eq 'HASH') {
            my %rh = %{$ret}; #get the hash
            BUNDLED: foreach my $key (keys %rh) {
                if(!$self->_spec()->check_switch($key)) {
                    if($key ne '~~last') {
                        push(@invalid_args, $key);
                        if($non_opt_mode eq 'STOP_RET_0') {
                            $self->_set_error("Encountered illegal switch $key");
                            return 0;
                        } elsif($non_opt_mode eq 'STOP') {
                            last PROCESS;
                        } elsif($non_opt_mode eq 'SWITCH_RET_0') {
                            $self->_set_error("Encountered illegal switch $key");
                            return 0;
                        }
                    }
                    next BUNDLED;
                }
                
                if(defined($rh{$key})) {
                    if($self->_spec()->set_switch($key, $rh{$key})) {
                        push(@valid_args, $key);
                        next BUNDLED;
                    } else {
                        $self->_set_error($self->_spec()->get_switch_error($key));
                        return 0;
                    }
                }
                
                if(!$self->_spec()->switch_requires_val($key)) {
                    if($self->_spec()->set_switch($key, 1)) {
                        push(@valid_args, $key);
                        next BUNDLED;
                    } else {
                        $self->_set_error($self->_spec()->get_switch_error($key));
                        return 0;
                    }
                }
                
                if($key ne $rh{'~~last'}) {
                    #FFFUUUU
                    $self->_set_error("switch $key requires value, but none given\n");
                    return 0;
                }
                
                if($self->_is_switch($args[$i+1])) {
                    self->_set_error("switch $key requires value, but none given\n");
                    return 0;
                }
                
                #okay, peek
                if($self->_spec()->set_switch($key, $args[$i+1])) {
                    push(@valid_args, $key);
                    ++$i;
                } else {
                    $self->_set_error($self->_spec()->get_switch_error($key));
                    return 0;
                }
            }
        #handle array returns
        } elsif(ref($ret) eq 'ARRAY') {    
            my @arr = @{$ret}; #get the array
            if($#arr != 1) {
                #this would be an error in the module, not bad user input
                Carp::confess "array is wrong length, should never happen\n";
            }
            
            if(!$self->_spec()->check_switch($arr[0])) {
                push(@invalid_args, $arr[0]);
                if($non_opt_mode eq 'STOP_RET_0') {
                    $self->_set_error("Encountered illegal switch $arr[0]");
                    return 0;
                } elsif($non_opt_mode eq 'STOP') {
                    last;
                } elsif($non_opt_mode eq 'SWITCH_RET_0') {
                    $self->_set_error("Encountered illegal switch $arr[0]");
                    return 0;
                }
                next;
            }

            if($self->_spec()->set_switch($arr[0], $arr[1])) {
                push(@valid_args, $arr[0]);
            } else {
                $self->_set_error($self->_spec()->get_switch_error($arr[0]));
                return 0;
            }
        } elsif(!defined($ret)) {    
            push(@invalid_args, $item);
            if($non_opt_mode eq 'STOP_RET_0') {
                $self->_set_error("Encountered illegal switch $item");
                return 0;
            } elsif($non_opt_mode eq 'STOP') {
                last;
            } elsif($non_opt_mode eq 'SWITCH_RET_0') {
                $self->_set_error("Encountered illegal switch $item");
                return 0;
            }
        } else { #should never happen
            my $rt = ref($ret);
            #this would be an error in the module, not bad user input
            Carp::confess "returned val $ret of illegal ref type $rt\n" 
        }
    }
    
    #check to see that all required args were set
    my $argmap = $self->_spec()->_argmap();
    foreach my $alias (keys %{$argmap}) {
        if($argmap->{$alias}->required() && !$argmap->{$alias}->is_set()) {
            my $spec = $argmap->{$alias}->switchspec();
            $self->_set_error("missing required switch with spec $spec\n");
            return 0;
        }
    }
    
    $self->_set_valid_args(\@valid_args);
    $self->_set_invalid_args(\@invalid_args);
    $self->_set_extra_args(\@extra_args);
    
    return 1;
}

around 'getopts' => sub {
	my $orig = shift;
	my $self = shift;
	
	my $ret = $self->$orig();
	
	#if using auto_help and help switch given or bad call, show help
	if($self->_config()->auto_help() && ($self->get_switch('help') || !$ret)) {
		if(!$ret) {
			print "**ERROR**: ", $self->get_error(), "\n";
		}
		print $self->get_help();

		if($ENV{'HARNESS_ACTIVE'}) {
			return $ret;
		}

		if(!$ret) {
			exit(1);
		} else {
			exit(0);
		}
	}

	return $ret;
};

sub _is_switch {
    my ($self, $switch) = @_;
    
    if(!defined($switch)) {
        return 0;
    }
    
    #does he look like a switch?
    return $switch =~ /^(-|--)[a-zA-Z?][a-zA-Z0-9=_?-]*/;
}

sub _parse_switch {
    my ($self, $switch) = @_;
    
    #get the switch type
    my $switch_type = $self->_switch_type($switch);
    
    #no given/when, so use this ugly thing
    if($switch_type == $_ST_LONG) {
        return $self->_parse_long_switch($switch);
    } elsif($switch_type == $_ST_SHORT) {
        return $self->_parse_short_switch($switch);
    } elsif($switch_type == $_ST_BUNDLED) {
        return $self->_parse_bundled_switch($switch);
    } elsif($switch_type == $_ST_NONE) {
        return undef;
    } else {
        #something is wrong here...
        Carp::confess "returned illegal switch type $switch_type\n";
    }
}

sub _switch_type {
    my ($self, $switch) = @_;
    
    #anything beginning with "--" is a
    #long switch
    if($switch =~ /^--/) {
        return $_ST_LONG;
    }
    
    #could be any kind
    #single dash, single letter, definitely short
    if($switch =~ /^-[a-zA-Z_?]$/) {
        return $_ST_SHORT;
    }
    
    #single dash, single letter, equal sign, definitely short
    if($switch =~ /^-[a-zA-Z_?]=.+$/) {
        return $_ST_SHORT;
    }
    
    #short or bundled
    #already determined it isn't a single letter switch, so check
    #the non_option_mode to see if it is long
    if($self->_config()->long_option_mode() eq 'SINGLE_OR_DOUBLE') {
        return $_ST_LONG;
    }
    
    #could be short, bundled, or none
    $switch =~ s/^-//;
    my $c1 = substr($switch, 0, 1);
    my $c2 = substr($switch, 1, 1);
    
    #the first letter doesn't belong to a short switch
    #so this isn't a valid switch
    if(!$self->_spec()->check_switch($c1)) {
        return $_ST_NONE;
    }
    
    #first letter belongs to a switch, but not the second
    #so this is a short switch of the form "-fboo" where
    #-f is the switch
    if($self->_spec()->check_switch($c1) && !$self->_spec()->check_switch($c2)) {
        return $_ST_SHORT;
    }
        
    #no other choices, it's bundled
    return $_ST_BUNDLED;
}

sub _parse_long_switch {
    my ($self, $switch) = @_;
    
    $switch =~ s/^(--|-)//;
    
    my @vals = split(/=/, $switch, 2);
    
    if($#vals == 0) {
        return \$vals[0];
    } else {
        return [$vals[0], $vals[1]];
    }
}

sub _parse_short_switch {
    my ($self, $switch) = @_;
    
    $switch =~ s/^-//;
    
    if(length($switch) == 1) {
        return \$switch;
    } elsif(index($switch, '=') >= 0) {
        my @vals = split(/=/, $switch, 2);
        return {$vals[0] => $vals[1]};
    } else {
        return [substr($switch, 0, 1), substr($switch, 1)];
    }
}

sub _parse_bundled_switch {
    my ($self, $switch) = @_;
    
    $switch =~ s/^-//;
    
    my %rh = ();
    my %fk = ();
    
    my $last_switch;
    for(my $i = 0; $i < length($switch); ++$i) {
        my $c = substr($switch, $i, 1);
        
        
        if(defined($fk{$c})) {
            if(!defined($last_switch)) {
                #oops, illegal switch
                #should never get here, make sure switch
                #is valid and of correct type sooner
                Carp::confess "illegal switch $switch\n";
            }
            
            #switch appears again in bundle, rest of string is an argument to last switch
            $rh{$last_switch} = substr($switch, $i);
            last;
        } elsif($self->_spec()->check_switch($c)) {
            $rh{$c} = undef;
            $fk{$c} = 1;
            $last_switch = $c;
            next;
        } else { #rest of the string was an argument to last switch
            if(!defined($last_switch)) {
                #oops, illegal switch
                #should never get here, make sure switch
                #is valid and of correct type sooner
                Carp::confess "illegal switch $switch\n";
            }
        
            if($c eq '=') {
                $rh{$last_switch} = substr($switch, $i + 1);
            } else {
                $rh{$last_switch} = substr($switch, $i);
            }
            last;
        }
    }
    
    #special value so we can pass on
    #what the last switch was
    $rh{'~~last'} = $last_switch;
    
    return \%rh;
}


sub add_spec {
	my ($self, $spec) = @_;

	my $ospec = $self->spec();
	my $nspec = merge($spec, $ospec);

	$self->_set_spec($nspec);

    $self->_spec(Getopt::Flex::Spec->new({ spec => $self->spec(), config => $self->_config() }));

	return $nspec;
}


sub set_args {
    my ($self, $ref) = @_;
    return $self->_args(Clone::clone($ref));
}


sub get_args {
    my ($self) = @_;
    return @{Clone::clone($self->_args)};
}


sub num_valid_args {
    my ($self) = @_;
    return $#{$self->valid_args} + 1;
}


sub get_valid_args {
    my ($self) = @_;
    return @{Clone::clone($self->_get_valid_args())};
}


sub num_invalid_args {
    my ($self) = @_;
    return $#{$self->invalid_args} + 1;
}


sub get_invalid_args {
    my ($self) = @_;
    return @{Clone::clone($self->_get_invalid_args())};
}


sub num_extra_args {
    my ($self) = @_;
    return $#{$self->extra_args} + 1;
}


sub get_extra_args {
    my ($self) = @_;
    return @{Clone::clone($self->_get_extra_args())};
}


sub get_usage {
    my ($self) = @_;
    
    if($self->_config()->usage() eq '') {
        return "\n";
    }
    return 'Usage: '.$self->_config()->usage()."\n";
}


sub get_help {
    my ($self) = @_;
    
    #find the keys that will give use a unique
    #set of arguments, using the primary_key
    #of each argument object
    my $argmap = $self->_spec()->_argmap();
    my @primaries = ();
    foreach my $key (keys %$argmap) {
        if($argmap->{$key}->primary_name() eq $key && $argmap->{$key}->desc() ne '') {
            push(@primaries, $key);
        }
    }
    
    my @help = ();
    
    #if we have a usage message, include it
    if($self->_config()->usage() ne '') {
        push(@help, 'Usage: ');
        push(@help, $self->_config()->usage());
        push(@help, "\n\n");
    }
    
    #if we have a description, include it
    if($self->_config()->desc() ne '') {
        push(@help, $self->_config()->desc());
        push(@help, "\n\n");
    }
    
    #if any of the keys have a description, then...
    if($#primaries != -1) {
        #...give us a listing of the options
        push(@help, "Options:\n\n");
        foreach my $key (sort @primaries) {
            if($argmap->{$key}->desc() ne '') {
                push(@help, $argmap->{$key}->desc());
            }
        }
    }
    
    #friends don't let friends end things with two newlines
    if($help[$#help] =~ /\n\n$/) { pop(@help); push(@help, "\n"); }
    
    return join('', @help);
}


sub get_desc {
    my ($self) = @_;
    return $self->_config()->desc()."\n";
}



sub get_switch {
    my ($self, $switch) = @_;
    
    return $self->_spec()->get_switch($switch);
}



no Moose;

1;

__END__
=pod

=head1 NAME

Getopt::Flex - Option parsing, done different.

=head1 VERSION

version 1.07

=head1 SYNOPSIS

  use Getopt::Flex;
  my $foo; my $use; my $num; my %has; my @arr;
  
  my $cfg = {
      'non_option_mode' => 'STOP',
  };
  
  my $spec = {
      'foo|f' => {'var' => \$foo, 'type' => 'Str'},
      'use|u' => {'var' => \$use, 'type' => 'Bool'},
      'num|n' => {'var' => \$num, 'type' => 'Num'},
      'has|h' => {'var' => \%has, 'type' => 'HashRef[Int]'},
      'arr|a' => {'var' => \@arr, 'type' => 'ArrayRef[Str]'}
  };
  
  my $op = Getopt::Flex->new({spec => $spec, config => $cfg});
  if(!$op->getopts()) {
      print "**ERROR**: ", $op->get_error();
      print $op->get_help();
      exit(1);
  }

=head1 DESCRIPTION

Getopt::Flex makes defining and documenting command line options in
your program easy. It has a consistent object-oriented interface. 
Creating an option specification is declarative and configuration 
is optional and defaults to a few, smart parameters. Generally,
it adheres to the POSIX syntax with GNU extensions for command 
line options. As a result, options may be longer than a single 
letter, and may begin with "--". Support also exists for 
bundling of command line options and using switches without
regard to their case, but these are not enabled by defualt.

Getopt::Flex is an alternative to other modules in the Getopt::
namespace, including the much used L<Getopt::Long> and
L<Getopt::Long::Descriptive>. Other options include L<App::Cmd>
and L<MooseX::Getopt> (which actually sit on top of L<Getopt::Long::Descriptive>).
If you don't like this solution, try one of those.

=head1 Getting started with Getopt::Flex

Getopt::Flex supports long and single character options. Any character
from [a-zA-Z0-9_?-] may be used when specifying an option. Options
must not end in -, nor may they contain two consecutive dashes.

To use Getopt::Flex in your Perl program, it must contain the following
line:

  use Getopt::Flex;

In the default configuration, bundling is not enabled, long options
must start with "--" and non-options may be placed between options.

Then, create a configuration, if necassary, like so:

  my $cfg = { 'non_option_mode' => 'STOP' };

For more information about configuration, see L<Configuring Getopt::Flex>.
Then, create a specification, like so: 

  my $spec = {
      'foo|f' => {'var' => \$foo, 'type' => 'Str'},
  };

For more information about specifications, see L<Specifying Options to Getopt::Flex>. Create
a new Getopt::Flex object:

  my $op = Getopt::Flex->new({spec => $spec, config => $cfg});

And finally invoke the option processor with:

  $op->getopts();

Getopt::Flex automatically uses the global @ARGV array for options.
If you would like to supply your own, you may use C<set_args()>, like this:

  $op->set_args(\@args);

In the event of an error, C<getopts()> will return false,
and set an error message which can be retrieved via C<get_error()>.

Getopt::Flex also stores information about valid options, invalid options
and extra options. Valid options are those which Getopt::Flex recognized
as valid, and invalid are those that were not. Anything that is not an
option can be found in extra options. These values can be retrieved via:

  my @va = $op->get_valid_args();
  my @ia = $op->get_invalid_args();
  my @ea = $op->get_extra_args();

Getopt::Flex may also be used to provide an automatically formatted help
message. By setting the appropriate I<desc> when specifying an option,
and by setting I<usage> and I<desc> in the configuration, a full help
message can be provided, and is available via:

  my $help = $op->get_help();

Usage and description are also available, via:

  my $usage = $op->get_usage();
  my $desc = $op->get_desc();

An automatically generated help message would look like this:

  Usage: foo [OPTIONS...] [FILES...]
  
  Use this to manage your foo files
  
  Options:
  
        --alpha, --beta,          Pass any greek letters to this argument
        --delta, --eta, --gamma
    -b, --bar                     When set, indicates to use bar
    -f, --foo                     Expects a string naming the foo

=head1 Specifying Options to Getopt::Flex

Options are specified by way of a hash whose keys define valid option
forms and whose values are hashes which contain information about the
options. For instance,

  my $spec = {
      'file|f' => {
          'var' => \$file,
          'type' => 'Str'
      }
  };

Defines a switch called I<file> with an alias I<f> which will set variable
C<$var> with a value when encountered during processing. I<type> specifies
the type that the input must conform to. Only I<type> is required
when specifying an option. If no I<var> is supplied, you may still access
that switch through the C<get_switch> method. It is recommended that you do
provide a I<var>, however. For more information about C<get_switch> see
L<get_switch>. In general, options must conform to the following:

  $_ =~ m/^[a-zA-Z0-9|_?-]+$/ && $_ =~ m/^[a-zA-Z_?]/ && $_ !~ m/\|\|/ && $_ !~ /--/ && $_ !~ /-$/

Which (in plain english) means that you can use any letter A through Z, upper- or lower-case,
any number, underscores, dashes, and question marks. The pipe symbol is used to separate the
various aliases for the switch, and must not appear together (which would produce an empty
switch). No switch may contain two consecutive dashes, and must not end with a dash. A switch
must also begin with A through Z, upper- or lower-case, an underscore, or a question mark.

The following is an example of all possible arguments to an option specification:

  my $spec = {
      'file|f' => {
          'var' => \$file,
          'type' => 'Str',
          'desc' => 'The file to process',
          'required' => 1,
          'validator' => sub { $_[0] =~ /\.txt$/ },
          'callback' => sub { print "File found\n" },
          'default' => 'input.txt',
      }
  };

Additional specifications may be added by calling C<add_spec>. This allows
one to dynamically build up a set of valid options.

=head2 Specifying a var

When specifying a I<var>, you must provide a reference to the variable,
and not the variable itself. So C<\$file> is ok, while C<$file> is not.
You may also pass in an array reference or a hash reference, please see
L<Specifying a type> for more information.

Specifying a I<var> is optional, as discussed above.

=head2 Specifying a type

A valid type is any type that is "simple" or an ArrayRef or HashRef parameterized
with a simple type. A simple type is one that is a subtype of C<Bool>, C<Str>,
C<Num>, or C<Int>.

Commonly used types would be the following:

  Bool Str Num Int ArrayRef[Str] ArrayRef[Num] ArrayRef[Int] HashRef[Str] HashRef[Num] HashRef[Int] Inc

The type C<Inc> is an incremental type (actually simply an alias for Moose's C<Int> type),
whose value will be increased by one each time
its appropriate switch is encountered on the command line. When using an C<ArrayRef>
type, the supplied var must be an array reference, like C<\@arr> and NOT C<@arr>.
Likewise, when using a C<HashRef> type, the supplied var must be a hash reference,
e.g. C<\%hash> and NOT C<%hash>.

You can define your own types as well. For this, you will need to import C<Moose> and
C<Moose::Util::TypeConstraints>, like so:

  use Moose;
  use Moose::Util::TypeConstraints;

Then, simply use C<subtype> to create a subtype of your liking:

  subtype 'Natural'
            => as 'Int'
            => where { $_ > 0 };

This will automatically register the type for you and make it visible to Getopt::Flex.
As noted above, those types must be a subtype of C<Bool>, C<Str>, C<Num>, or C<Int>.
Any other types will cause Getopt::Flex to signal an error. You may use these subtypes
that you define as parameters for the ArrayRef or Hashref parameterizable types, like so:

  my $sp = { 'foo|f' => { 'var' => \@arr, 'type' => 'ArrayRef[Natural]' } };

or

  my $sp = { 'foo|f' => { 'var' => \%has, 'type' => 'HashRef[Natural]' } };

For more information about types and defining your own types, see L<Moose::Manual::Types>.

Specifying a I<type> is required.

=head2 Specifying a desc

I<desc> is used to provide a description for an option. It can be used
to provide an autogenerated help message for that switch. If left empty,
no information about that switch will be displayed in the help output.
See L<Getting started with Getopt::Flex> for more information.

Specifying a I<desc> is optional, and defaults to ''.

=head2 Specifying required

Setting I<required> to a true value will cause it make that value required
during option processing, and if it is not found will cause an error condition.

Specifying I<required> is not required, and defaults to 0.

=head2 Specifying a validator

A I<validator> is a function that takes a single argument and returns a boolean
value. Getopt::Flex will call the validator function when the option is
encountered on the command line and pass to it the value it finds. If the value
does not pass the supplied validation check, an error condition is caused.

Specifying a I<validator> is not required.

=head2 Specifying a callback

A I<callback> is a function that takes a single argument which Getopt::Flex will
then call when the option is encountered on the command line, passing to it the value it finds.

Specifying a I<callback> is not required.

=head2 Specifying a default

I<default>s come in two flavors, raw values and subroutine references.
For instance, one may specify a string as a default value, or a subroutine
which returns a string:

  'default' => 'some string'

or

  'default' => sub { return "\n" }

When specifying a default for an array or hash, it is necessary to use
a subroutine to return the reference like,

  'default' => sub { {} }

or

  'default' => sub { [] }

This is due to the way Perl handles such syntax. Additionally, defaults
must be valid in relation to the specified type and any specified
validator function. If not, an error condition is signalled.

Specifying a I<default> is not required.

=head1 Configuring Getopt::Flex

Configuration of Getopt::Flex is very simple. Such a configuration
is specified by a hash whose keys are the names of configuration
option, and whose values indicate the configuration. Below is a
configuration with all possible options:

  my $cfg = {
      'non_option_mode' => 'STOP',
      'bundling' => 0,
      'long_option_mode' => 'SINGLE_OR_DOUBLE',
      'case_mode' => 'INSENSITIVE',
      'usage' => 'foo [OPTIONS...] [FILES...]',
      'desc' => 'Use foo to manage your foo archives',
	  'auto_help' => 1,
  };

What follows is a discussion of each option.

=head2 Configuring non_option_mode

I<non_option_mode> tells the parser what to do when it encounters anything
which is not a valid option to the program. Possible values are as follows:

  STOP IGNORE SWITCH_RET_0 VALUE_RET_0 STOP_RET_0

C<STOP> indicates that upon encountering something that isn't an option, stop
processing immediately. C<IGNORE> is the opposite, ignoring everything that
isn't an option. The values ending in C<_RET_0> indicate that the program
should return immediately (with value 0 for false) to indicate that there was a
processing error. C<SWITCH_RET_0> means that false should be returned in the
event an illegal switch is encountered. C<VALUE_RET_0> means that upon
encountering a value, the program should return immediately with false. This
would be useful if your program expects no other input other than option
switches. C<STOP_RET_0> means that if an illegal switch or any value is
encountered that false should be returned immediately.

The default value is C<IGNORE>.

=head2 Configuring bundling

I<bundling> is a boolean indicating whether or not bundled switches may be used.
A bundled switch is something of the form:

  -laR

Where equivalent unbundled representation is:

  -l -a -R

By turning I<bundling> on, I<long_option_mode> will automatically be set to
C<REQUIRE_DOUBLE_DASH>.

Warning: If you pass an illegal switch into a bundle, it may happen that the
entire bundle is treated as invalid, or at least several of its switches.
For this reason, it is recommended that you set I<non_option_mode> to
C<SWITCH_RET_0> when bundling is turned on. See L<Configuring non_option_mode>
for more information.

The default value is C<0>.

=head2 Configuring long_option_mode

This indicates what long options should look like. It may assume the
following values:

  REQUIRE_DOUBLE_DASH SINGLE_OR_DOUBLE

C<REQUIRE_DOUBLE_DASH> is the default. Therefore, by default, options
that look like:

  --verbose

Will be treated as valid, and:

  -verbose

Will be treated as invalid. Setting I<long_option_mode> to C<SINGLE_OR_DOUBLE>
would make the second example valid as well. Attempting to set I<bundling> to
C<1> and I<long_option_mode> to C<SINGLE_OR_DOUBLE> will signal an error.

The default value is C<REQUIRE_DOUBLE_DASH>.

=head2 Configuring case_mode

I<case_mode> allows you to specify whether or not options are allowed to be
entered in any case. The following values are valid:

  SENSITIVE INSENSITIVE

If you set I<case_mode> to C<INSENSITIVE>, then switches will be matched without
regard to case. For instance, C<--foo>, C<--FOO>, C<--FoO>, etc. all represent
the same switch when case insensitive matching is turned on.

The default value is C<SENSITIVE>. 

=head2 Configuring usage

I<usage> may be set with a string indicating appropriate usage of the program.
It will be used to provide help automatically.

The default value is the empty string.

=head2 Configuring desc

I<desc> may be set with a string describing the program. It will be used when
providing help automatically.

The default value is the empty string.

=head2 Configuring auto_help

I<auto_help> can be set to true to enable the automatic creation of a C<help|h>
switch, which, when detected, will cause the help to be printed and exit(0) to
be called. Additionally, if the given switches are illegal (according to your
configuration and spec), the error will be printed, the help will be printed,
and exit(1) will be called.

Use of auto_help also means you may not define other switches C<help> or C<h>.

The default value is false.

=head1 METHODS

=head2 getopts

Invoking this method will cause the module to parse its current arguments array,
and apply any values found to the appropriate matched references provided.

=head2 add_spec

Add an additional spec to the current spec.

=head2 set_args

Set the array of args to be parsed. Expects an array reference.

=head2 get_args

Get the array of args to be parsed.

=head2 num_valid_args

After parsing, this returns the number of valid switches passed to the script.

=head2 get_valid_args

After parsing, this returns the valid arguments passed to the script.

=head2 num_invalid_args

After parsing, this returns the number of invalid switches passed to the script.

=head2 get_invalid_args

After parsing, this returns the invalid arguments passed to the script.

=head2 num_extra_args

After parsing, this returns anything that wasn't matched to a switch, or that was not a switch at all.

=head2 get_extra_args

After parsing, this returns the extra parameter passed to the script.

=head2 get_usage

Returns the supplied usage message, or a single newline if none given.

=head2 get_help

Returns an automatically generated help message

=head2 get_desc

Returns the supplied description, or a single newline if none provided.

=head2 get_error

Returns an error message if set, empty string otherwise.

=head2 get_switch

Passing this function the name of a switch (or the switch spec) will
cause it to return the value of a ScalarRef, a HashRef, or an ArrayRef
(based on the type given), or undef if the given switch does not
correspond to any defined switch.

=for Pod::Coverage   BUILD

=head1 REPOSITORY

The source code repository for this project is located at:

  http://github.com/f0rk/getopt-flex

=head1 AUTHOR

Ryan P. Kelly <rpkelly@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Ryan P. Kelly.

This is free software, licensed under:

  The MIT (X11) License

=cut

