use Hash::Filler;

my $hf = new Hash::Filler;	# The hash filler object

				# The following line will produce
				# abundant information about how
				# each ->fill method is fulfilled.

$Hash::Filler::DEBUG = 1;

				# This is an example of a user-supplied
				# function to see if a given hash key 
				# exists already.

sub method {
    my $rhash = shift;
    my $key = shift;
    print "Checking key {$key}... "; 
    if ($rhash->{$key}) {
	print "ok\n";
	return 1;
    }
    else {
	print "fail\n";
	return 0;
    }
}

##
## These are the rules that control how to populate the hash automatically.
## Some of them are explained. Note that the return values for ->add
## are discarded as we do not need them. In practice, you only need them
## if you plan to manage the rules or do detailed profiling with them.
##

				# This is a simple rule. It applies to 
				# the 'key0' hash key. It does not
				# require any prerequisite keys to be
				# defined() in the hash.
$hf->add(
	 'key0', 
	 sub { $_[0]->{$_[1]} = 'i:key0'; sleep 1;},
    []);

$hf->add(
    'key2', 
    sub { $_[0]->{$_[1]} = 'i:key2'; }, 
    []);

				# This is a rule to generate hash key 'key1'.
				# It needs the hash key 'key0' to be present
				# in the hash for it to be applied.
$hf->add(
    'key1', 
    sub { $_[0]->{$_[1]} = 'k1(' . $_[0]->{'key0'} . ')'; sleep 1;}, 
    ['key0']);

				# This rule uses a higher precedence (1000)
				# to indicate that it must be used instead
				# of other rules with default precedences.
				# The precedence is more important than the
				# prerequisites of a rule when determining 
				# which rule to use.
$hf->add(
    'key2', 
    sub { $_[0]->{$_[1]} = 'k2(' . $_[0]->{'key1'} . ')'; }, 
    ['key1'], 1000);

$hf->add(
    'key3', 
    sub { $_[0]->{$_[1]} = 'k3(' . $_[0]->{'key4'} . ')'; }, 
    ['key4'], 1000);

$hf->add(
    'key4', 
    sub { $_[0]->{$_[1]} = 'k4(' . $_[0]->{'key3'} . ')'; sleep 1;}, 
    ['key3'], 1000);

$hf->add(
    'key4', 
    sub { $_[0]->{$_[1]} = 'i:key4'; }, 
    []);

$hf->add(
    'key5', 
    sub { 1; }, 
    []);

$hf->add(
    'key6', 
    sub { $_[0]->{$_[1]} = '<does' . 
	      ((exists $_[0]->{'key5'}) ? '' : ' not') . ' exist>'; 1; }, 
    ['key5']);

				# This is a wildcard rule. It will be
				# used to generate any missing key in
				# the hash. Keep in mind that this rule
				# can also be used to generate
				# missing prerequisites. It could also have
				# prerequisites.
$hf->add(
    undef, 
    sub { $_[0]->{$_[1]} = 'wildcard(' . $_[1] . ')'; 1; }, 
    []);

				# This allows the specification of the 
				# method to use to determine if a given
				# hash key must be filled.
$hf->method(\&method);
# $hf->method(Hash::Filler::EXISTS);

# $hf->dump_r_tree;

my %hash;

				# The following is a code example that uses
				# fill to populate the hash.

foreach my $key (qw(key7 key2 key3 key6 key6))
{
    print "*** Filling of key $key:\n";
    if ($hf->fill(\%hash, $key)) {
	print "*** Succeeded\n";
    }
    else {
	print "*** Failed\n";
    }
    print "*** Value of $key is ", $hash{$key}, "\n";
}
				# Dump the whole rule tree
$hf->dump_r_tree;
