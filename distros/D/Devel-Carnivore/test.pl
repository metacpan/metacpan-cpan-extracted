package My;
use strict;
use Tie::Hash;
use Test::Simple tests => 107;

#use lib "../";
use constant CLASS => "Devel::Carnivore::Tie::Hash";

my %factories = (
	new_attribute        => 'attribute on my %hash',
	new_functional       => 'watch',
	new_blessed          => 'watch on a blessed scalar',
	new_scalar_attribute => 'attribute on my $scalar',
);


my @test_cases = ("Perl", "Larry", {}, []);

foreach my $method_name (keys %factories) { # 8 tests + 16 tests

	my $factory = $factories{$method_name};

	my $obj = Factory->execute($method_name);
	# testing whether the objects are tied to the right class
	ok(tied %$obj, "Object is tied via $factory.");
	ok( (tied %$obj) -> isa(CLASS ), "Object is tied to right class via $factory");
	
	my $filename = ".test.test";
	
	open my $out, ">$filename" or die "unable to open file: $filename due to $!. I was going to write
to a file called '.test.test'. Please make sure I have the neccessary permissions.";
	$Devel::Carnivore::OUT = $out;
	
	my $correct_line_number_cool = 0;
	my $correct_line_number_neat = 0;
	
	foreach my $test_case (@test_cases) { # 4 * 4
		$obj->cool($test_case); $correct_line_number_cool = get_line_number(); # on the same line as change occurs
		$obj->change_somewhere_else($test_case); $correct_line_number_neat = get_line_number(); 
		if(ref $test_case) {
			ok(ref $obj->cool eq ref $test_case, "changing a hash value to a ref still works via $factory");
		} else {
			ok($obj->cool eq $test_case, "changing a hash value still works via $factory");
		}
	}
	
	# testing unwatch
	unwatch $obj;	
	ok(! tied %$obj, "unwatching");
	
	open my $in, $filename or die "unable to open $filename due to $!";
	
	my $last = "";
	my $i    = 0;
	
	my $current_filename = quotemeta get_filename();
	
	# tests for the correct line number are badly needed
	while(<$in>) { # 4 * 4 * 3
		next if /^#/; # filter out comments in the test file
		if(/cool/) { # lines where cool changed
			my $test_case = quotemeta $test_cases[$i];
			ok(/$current_filename line \d+$/, "output tells the right filename via $factory");
			ok(/(\d+)$/, "line number found");
			ok($1 == $correct_line_number_cool, "output tells the right line number via $factory: $1 == $correct_line_number_cool");
			ok(/"cool" changed from "$last" to "$test_case"/, "output tells the right key name and values: $i");
			$last = $test_case;
			$i++;
		}
		elsif(/neat/) { # lines where neat changed 
			ok(/(\d+)$/, "line number found");
			ok($1 == $correct_line_number_neat, "output tells the right line number with 1 extra indirection: $1 == $correct_line_number_neat");
		} else {
			die "there shouldn't be any other lines"	
		}
		
		#warn "line = $_; NEW : $last to $test_case";
		
	}
}

for (0..6) { # 7 tests
	ok(test_fail($_), "things that shouldn't work, no. $_");
}

sub test_fail {
	my $index = shift;	
	local $@;

	my $method = "fail$index";	

	eval { Factory->execute($method) };

	# warn "$index failed: $@" if $@;

	return 1 if $@;
}

sub get_filename {
	my($package,$filename) = caller;
	return $filename;
}

sub get_line_number {
	my($package,$filename,$line) = caller;
	return $line;
}

package Factory;
use Devel::Carnivore;
use strict;

sub execute {
	no strict "refs";
	my($class,$method_name) = @_;
	
	$class->$method_name
}


sub new_attribute {
	my %self : Watch(1) = ();		

	bless \%self, shift;
}

sub new_functional {
	my $self  = {};		

	watch $self, 2;

	bless $self
}

sub new_blessed {
	my $self  = {};	

	bless $self;

	watch $self, 3;

	return $self;
}



sub new_scalar_attribute {
	my $self : Watch(4) = {};		
	bless $self
}


sub fail0 { my $s : Watch = "" }              # watch a string via attribute
sub fail1 { my $s = []; watch $s }            # watch an arrayref via function call
sub fail2 { my $b; my $s = \$b; watch $s }    # watch a scalar ref
sub fail3 { my $s : Watch = [] }              # watch an arrayref via attribute
sub fail4 { my $s : Watch = {}; $s = "fail" } # turn watched var into a string
sub fail5 { my $s : Watch = {}; $s = [] }     # turn watched var into some other reference

sub fail6 { # attempting to watch a var which is already tied
	my %var = (bla => "blub");
	tie %var, "Tie::StdHash";
	watch \%var;
	$var{foo} = "bar";
}

sub change_somewhere_else {
	my($self, $new_value) = @_;
	
	$self->neat($new_value); my $line_number = My::get_line_number();
	
	return $line_number;
}

sub cool {
	my $self      = shift;
	$self->{cool} = shift if @_;
	$self->{cool}
}

sub neat {
	my $self      = shift;
	$self->{neat} = shift if @_;
	$self->{neat}	
}


