package Hash::Filler;

use strict;
use Carp;
use vars qw($VERSION $DEBUG $indent);
use Time::HiRes qw(gettimeofday tv_interval);

# How to check for the existence of an element

use constant TRUE	=> 0;	# Test if the value is true
use constant DEFINED	=> 1;	# Use defined()
use constant EXISTS	=> 2;	# Use exists() (default)

use constant INDENT	=> 2;	# How much to indent printouts

$VERSION	= '1.40';
$DEBUG		= '0';

my $indent = 0;

# Preloaded methods go here.

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Hash::Filler";

    my $self = {
	'rules' => {},		# All the rules we know about
	'wild' => [],		# Wildcard rules
	'times' => [],		# Accumulated times for each rule
	'calls' => [],		# How many times each rule has been used
	'id' => 0,		# Current rule id
	'loop' => 1,		# Avoid loops by default
	'method' => EXISTS,	# Which method to use to check for
				# existence of a hash key
    };

    bless $self, $class;
}

sub _sort {			# This is to be used by the sort
				# built-in
    return 
	    $b->{'pref'} <=> $a->{'pref'} or
		@{$a->{'prereq'}} <=> @{$b->{'prereq'}} or
		    $a->{'used'} <=> $b->{'used'};
}

sub _print_rule {
    my $self = shift;
    my $rule = shift;
    my $key = shift;

    printf("%s[%d] rule for key %s, used %s, pref %s, %s be used\n",  
	   ' ' x $indent,
	   $rule->{'id'},
	   defined $rule->{'key'} ? $rule->{'key'} : '<ANY>',
	   $rule->{'used'}, 
	   $rule->{'pref'},
	   $rule->{'use'} ? 'can' : 'cannot');
    printf("%s|[called %d times (%0.6f secs)]\n",
	   ' ' x $indent,
	   $self->{'calls'}->[$rule->{'id'}],
	   $self->{'times'}->[$rule->{'id'}]);
    if (defined $key) {
	printf("%s|[called to get key %s]\n",
	       ' ' x $indent,
	       $key);
    }
    my $pre = 0;
    foreach my $pr (sort @{$rule->{'prereq'}}) {
	printf("%s+- prereq %s\n", ' ' x $indent, $pr);
	++$pre;
    }
    printf("%s+- No prereq\n", ' ' x $indent) unless $pre;
}

sub dump_r_tree {
    my $self = shift;
    foreach my $key (keys %{$self->{'rules'}}) {
	my $dumped = 0;
	print "Rules for key $key:\n";
	foreach my $rule (sort(_sort @{$self->{'rules'}->{$key}})) {
	    ++$dumped;
	    $self->_print_rule($rule);
	}
	print "  No rules.\n" unless $dumped;
    }
    my $dumped = 0;
    print "Wildcard rules:\n";
    foreach my $rule (sort(_sort @{$self->{'wild'}})) {
	++$dumped;
	$self->_print_rule($rule);
    }
    print "  No rules.\n" unless $dumped;
}

sub loop {
    $_[0]->{'loop'} = $_[1];
}

sub method {
    $_[0]->{'method'} = $_[1];
}

sub stats {
    @{$_[0]->{'calls'}};
}

sub profile {
    @{$_[0]->{'times'}};
}

sub remove {
    my $self = shift;
    my $id = shift;

    return unless $id;

    foreach my $key (keys %{$self->{'rules'}}) {
	foreach my $rule (@{$self->{'rules'}->{$key}}) {
	    if ($rule->{'id'} == $id) {
		$rule->{'use'} = 0;
		return;
	    }
	}
    }
    foreach my $rule (@{$self->{'wild'}}) {
	if ($rule->{'id'} == $id) {
	    $rule->{'use'} = 0;
	    return;
	}
    }
}

sub add {
    my $ret;

    if (defined $_[1]) {	# Specific rule
	push @{$_[0]->{'rules'}->{$_[1]}}, {
	    'key' => $_[1],
	    'code' => $_[2],
	    'prereq' => $_[3],
	    'pref' => $_[4] ? $_[4] : 100,
	    'used' => 0,
	    'use' => 1,
	    'id' => $ret = ++ $_[0]->{'id'},
	};
    }
    else {			# Wildcard rule
	push @{$_[0]->{'wild'}}, {
	    'key' => undef,
	    'code' => $_[2],
	    'prereq' => $_[3],
	    'pref' => $_[4] ? $_[4] : 100,
	    'used' => 0,
	    'use' => 1,
	    'id' => $ret = ++ $_[0]->{'id'},
	};
    }
    $ret;
}

sub _exists {
    my $self = shift;
    my $href = shift;
    my $key = shift;

    if ($self->{'method'} == DEFINED) {
	return 1 if defined $href->{$key};
    }
    elsif ($self->{'method'} == EXISTS) {
	return 1 if exists $href->{$key};
    }
    elsif (ref $self->{'method'} eq 'CODE') {
	return 1 if $self->{'method'}->($href, $key);
    }
    else {
	return 1 if $href->{$key};
    }
    return 0;
}

sub fill {
    my $self = shift;
    my $href = shift;
    my $key = shift;
    my $ret = 0;

    croak "->fill() must be given a hash reference"
	unless ref($href) eq 'HASH';

				# Provide a quick exit if the hash
				# key is already defined or if
				# we have no rules to generate it.

    ++ $self->{'calls'}->[0];	# Keep the number of times ->fill
				# has been called.

    return 1 
	if $self->_exists($href, $key);

    return 0 
	unless $self->{'rules'}->{$key} or
	    @{$self->{'wild'}};

				# Look through the available rules
				# and try to find an execution plan
				# to fill the requested $key.

    my @rulelist;

    if ($self->{'rules'}->{$key}) {
	push @rulelist, sort(_sort @{$self->{'rules'}->{$key}});
    }

    push @rulelist, sort(_sort @{$self->{'wild'}});

  RULE:    
    foreach my $rule (@rulelist) {

	next RULE		# Watch out for infinite loops
	    if $self->{'loop'} and 
		$rule->{'used'};

	$rule->{'used'} ++;	# Mark this rule as being used
				# to control infinite recursion

	++ $self->{'calls'}->[$rule->{'id'}];

				# Insure that all prerequisites
				# are there before attempting to
				# call this method

	foreach my $pr (@{$rule->{'prereq'}}) {

				# A rule cannot be invoked to resolve
				# its own prerequisite as this might make
				# no sense.

	    if ($pr eq $key) {
		if (defined $rule->{'key'}) {
		    croak "Rule " 
			. $rule->{'id'} 
		    . " has itself as prerequisite";
		}
		else {		# A wildcard rule...
		    next RULE
			unless $self->_exists($href, $pr);
		}
	    }
	    
				# Recursive call. If required, attempt
				# to fill this prerequisite using the
				# available rules. If the prereq is 
				# already in the hash, this will return 
				# immediatly. The retval of this ->fill()
				# is ignored as there might be more than
				# one rule that can provide the missing
				# prereq.

# XXX - Note that we might want to return false from this rule if the fill
# method for a prereq returns false. The current implementation allows the
# method's return value control the behavior of ->fill more fine-granedly.

	    $indent += INDENT;
	    $self->fill($href, $pr);
	    $indent -= INDENT;

				# Insure that the required hash
				# buckets are already filled
				# before attempting to call the 
				# user supplied function.

	    next RULE
		unless $self->_exists($href, $pr);
	}

	$self->_print_rule($rule, $key) if $DEBUG;

				# Run and profile the execution of
				# the user supplied method.

	my $time = [gettimeofday];
	$ret = $rule->{'code'}->($href, $key);
	$time = tv_interval($time);

	$self->{'times'}->[$rule->{'id'}] += $time;
	$self->{'times'}->[0] += $time;
    }
    continue {
	$rule->{'used'} --;	# Rule is no longer used
	return $ret		# If a user-supplied sub was
	    if $ret;		# succesful, we're done
    }

    return 0;			# No rule matched or was succesful.
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

HashFiller - Programatically fill elements of a hash based in prerequisites

=head1 SYNOPSIS

  use Hash::Filler;

  my $hf = new Hash::Filler;

				# Show how a ->fill() method executes
				# the rules
  $Hash::Filler::DEBUG = 1;

				# Add a set of rules

  $hf->add('key1', sub { my $hr = shift; ... }, ['key2', 'key3'], $pref);
  $hf->add('key1', sub { my $hr = shift; ... }, [], $pref);
  $hf->add('key2', sub { my $hr = shift; ... }, ['key1', 'key3'], $pref);
  $hf->add('key3', sub { my $hr = shift; ... }, ['key1', 'key2'], $pref);
  $hf->add(undef, sub { ... }, [], $pref);

				# Remove rules

  $hf->remove($rule_id);

  $hf->loop(0);			# Don't try to avoid infinite loops

				# Test if a key exists using defined()
  $hf->method($Hash::Filler::DEFINED);

  my %hash;

  $hf->fill(\%hash, 'key1');	# Calculate the value of $hash{key1}
  $hash{'key2'} = 'foo';	# Manually fill a hash position
  $hf->fill(\%hash, 'key2');	# Calculate the value of $hash{key2}
  $hr->dump_r_tree();		# Print the key tree

  my @stats = $hf->stats();	# Obtain statistics about rule invocation
  my @prof = $hf->profile();	# Obtain profiling information about the rules

=head1 DESCRIPTION

C<Hash::Filler> provides an interface so that hash elements can be
calculated depending in the existence of other hash elements, using
user-supplied code references.

One of the first uses of this module was inside a server. In this
server, the responses to commands came from external sources. For each
request, the server needed to contact a number of external sources to
calculate the proper answer. These calculations sometimes attempted
redundant external accesses, thus increased the response time and
load.

To help in this situation, the calculations were rewritten to access a
hash instead of the external sources directly and this module was used
to fill the hash depending on the requirements of the
calculations. The external accesses were also improved so that more
than one choice or rule existed for each datum, depending on wether
prerequisites existed already in the hash or not.

Hopefully this explanation will make it easier to understand what this
module is about :)

There are a few relevant methods, described below:

=over 4

=item C<-E<gt>add($key, $code, $r_prereq, $pref)>

Adds a new rule to the C<Hash::Filler> object. The rule will be used
to fill the hash bucket identified with key $key. To fill this bucket,
the code referenced by $code will be invoked, passing it a reference
to the hash being worked on and the key that is being filled. This
will only be called if all of the hash buckets whose keys are in the
list referenced by $r_prereq C<exist>.

If the user-supplied code returns a false value, failure is assumed.

An optional preference can be supplied. This is used to help the
internal rule selection choose the better rule.

Multiple rules for the same $key and the same $r_prereq can be
added. The module will attempt to use them both but the execution
order will be undefined unless you use $pref. The default $pref is
100.

A special case occurs when $key is undefined. In this case, this rule
is said to be a 'wildcard'. This means that the rule applies to any
key that needs to be filled. Wildcard rules are applied after any
matching rules (ie, after rules that apply specifically to a given
$key). Multiple wildcard rules are selected based in the preference
and availability of prerequisites.

This function returns a 'rule identifier'. This identifier is the
index that designates a given rule. Generally, it is only used in
conjunction with profiling.

=item C<-E<gt>remove($id)>

Removes the rule whose identifier matches $id. The implementation
actually does not remove the rule. Instead it marks the rule as
non-usable.

=item C<-E<gt>dump_r_tree>

This method prints out a representation of the rule tree kept by the
object. The tree lists the rules in the order they would be preferred
for a given key.

Output is sent to STDOUT.

=item C<-E<gt>profile>

Returns an array containing time profiles for the execution of each
rule. The index in the array is the identifier assigned for each
rule. Each slot in the array contain the accumulated time for all the
invocations of that particular rule.

Slot 0 in the array contains the accumulated time for ALL the invoked
rules. This make it easier to find the most important contributors to
the accumulated time.

Note that time is only computed if the user-supplied method must be
called. Whenever the hash bucket to be filled by a rule already has a
value, this method will not be called and no time will be added to
this rule.

=item C<-E<gt>stats>

This method returns an array which counts the number of times a given
rule has been invoked and its user-supplied method has been
called. The index into the array is the rule identifier, just as in
the case of C<-E<gt>profile>. The 0th element of the array contains
the total number of times that C<-E<gt>fill> has been called. This is
useful to deduce how many times the rules needed to be invoked.

=item C<-E<gt>method($val)>

Which method to use to decide if a given key is present in the
hash. The accepted values are:

=over 4

=item C<$Hash::Filler::EXISTS> (default)

    The existence of a hash element or key is calculated using a
    construct like C<exists($hash{$key})>.

=item C<$Hash::Filler::DEFINED>

    The existence of a hash element or key is calculated using a
    construct like C<defined($hash{$key})>.

=item C<$Hash::Filler::TRUE>

    The existence of a hash element or key is calculated using a
    construct like C<$hash{$key}>.

=item Reference to a sub

    This allows the user to specify a function to determine wether a
    hash bucket must be calculated or not. The function is invoked by
    passing it a reference to the hash and the key that must be
    checked. The function must return a TRUE value is the bucket is
    already populated or false if the corresponding rules must be
    applied.

=back

This allow this module to be customized to the particular application
in which it is being used. Be advised that changing this might cause a
change in which and when the rules are invoked for a particular hash
so probably it should only be used before the first call to
C<-E<gt>fill>.

By defult, the module uses exists() to do this check.

=item C<-E<gt>loop($val)>

Controls if the module should try to avoid infinite loops. A true $val
means that it must try (the default). A false value means otherwise.

=item C<-E<gt>fill($r_hash, $key)>

Attempts to fill the bucket $key of the hash referenced by $r_hash
using the supplied rules.

This method will return a true value if there are rules that allow the
requested $key to be calculated (or the $key is in the hash)
and the user supplied code returned true.

To avoid infinite loops, the code will not invoke a rule twice unless
C<-E<gt>loop> is called with a true value. The rules will be used
starting with the ones with less prerequisites, as these are assumed
to be lighter. To use a different ordering, specify $pref. Higher
values of $pref are used first.

=back

=head1 CAVEATS

This code uses recursion to resolve rules. This allows it to figure
out the value for a given key with only an incomplete rule
specification. Be warned that this might be costly if used with large
sets of rules.

=head1 AUTHOR

Luis E. Munoz < lem@cantv.net>

=head1 SEE ALSO

perl(1).

=head1 WARRANTY

Absolutely none.

=cut
