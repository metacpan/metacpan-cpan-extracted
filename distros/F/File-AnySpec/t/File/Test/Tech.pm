#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Test::Tech;

use 5.001;
use strict;
use warnings;
use warnings::register;

use Test ();   # do not import the "Test" subroutines
use Data::Secs2 qw(stringify);

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.17';
$DATE = '2004/04/09';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(tech_config plan ok skip skip_tests stringify demo finish);

#######
# For subroutine interface keep all data hidden in a local hash of private object
# 
my $tech_p = new Test::Tech;

sub new
{

   ####################
   # $class is either a package name (scalar) or
   # an object with a data pointer and a reference
   # to a package name. A package name is also the
   # name of a class
   #
   my ($class, @args) = @_;
   $class = ref($class) if( ref($class) );
   my $self = bless {}, $class;

   ######
   # Make Test variables visible to tech_config
   #  
   $self->{Test}->{ntest} = \$Test::ntest;
   $self->{Test}->{TESTOUT} = \$Test::TESTOUT;
   $self->{Test}->{TestLevel} = \$Test::TestLevel;
   $self->{Test}->{ONFAIL} = \$Test::ONFAIL;
   $self->{Test}->{TESTERR} = \$Test::TESTERR if defined $Test::TESTERR; 

   $self->{TestDefault}->{TESTOUT} = $Test::TESTOUT;
   $self->{TestDefault}->{TestLevel} = $Test::TestLevel;
   $self->{TestDefault}->{ONFAIL} = $Test::ONFAIL;
   $self->{TestDefault}->{TESTERR} = $Test::TESTERR if defined $Test::TESTERR; 

   ######
   # Test::Tech object data
   #
   $self->{Skip_Tests} = 0;
   $self->{test_name} = '';
   $self->{passed} = [];
   $self->{failed} = [];
   $self->{skipped} = [];
   $self->{missed} = [];
   $self->{unplanned} = [];
   $self->{last_test} = 0;
   $self->{num_tests} = 0;
   $self->{highest_test} = 0;

   ######
   # Redirect Test:: output thru Test::Tech::Output handle
   #   unless been redirected and never restored!!
   #
   unless( \*TESTOUT eq $Test::TESTOUT ) {
       $self->{test_out} = $Test::TESTOUT;
       tie *TESTOUT, 'Test::Tech::Output', $Test::TESTOUT, $self;
       $Test::TESTOUT = \*TESTOUT;
   }

   $self;

}
 

#####
# Restore the Test:: moduel variable back to where they were when found
#
sub finish
{
    my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift @_ : $tech_p;

    $Test::TESTOUT = $self->{TestDefault}->{TESTOUT};
    $Test::TestLevel = $self->{TestDefault}->{TestLevel};
    $Test::ONFAIL = $self->{TestDefault}->{ONFAIL};
    $Test::TESTERR = $self->{TestDefault}->{TESTERR} if defined $Test::TESTERR;

    return unless $Test::TESTOUT;  # if IO::Handle object may be destroyed and undef
    return unless $self->{last_test} && $self->{num_tests};  

    my $missing = $self->{last_test} + 1;
    while($missing <= $self->{num_tests}) {
         push @{$self->{missed}}, $missing++;
    }
    if(@{$self->{unplanned}}) {
        print $Test::TESTOUT '# Extra  : ' . (join ' ', @{$self->{unplanned}}) . "\n";
    }
    if(@{$self->{missed}}) {
        print $Test::TESTOUT '# Missing: ' . (join ' ', @{$self->{missed}}) . "\n";
    }
    if(@{$self->{skipped}}) {
        print $Test::TESTOUT '# Skipped: ' . (join ' ', @{$self->{skipped}}) . "\n";
    }
    if(@{$self->{failed}}) {
        print $Test::TESTOUT '# Failed : ' . (join ' ', @{$self->{failed}}) . "\n";
    }
    use integer;

    my $total = $self->{num_tests} if $self->{num_tests};
    $total = $self->{last_test} if $self->{last_test} && $self->{num_tests} < $self->{last_test};
    $total -= @{$self->{skipped}};

    my $passed =  @{$self->{passed}};
    print $Test::TESTOUT '# Passed : ' . "$passed/$total " . ((100*$passed)/$total) . "%\n" if $total;

    return ($total,$self->{unplanned},$self->{missed},$self->{skipped},$self->{passed},$self->{failed})
          if wantarray;

    $passed;
}

# *finish = &*Test::Tech::DESTORY; # DESTORY is alias for finish
sub DESTORY 
{
    finish( @_ );

}



######
# Cover function for &Test::plan that sets the proper 'Test::TestLevel'
# and outputs some info on the current site
#
sub plan
{
   ######
   # This subroutine uses no object data; therefore,
   # drop any class or object.
   #
   shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

   &Test::plan( @_ );

   ###############
   #  
   # Establish default for Test
   #
   # Test 1.24 resets global variables in plan which
   # never happens in 1.15
   #
   $Test::TestLevel = 1;

   my $loctime = localtime();
   my $gmtime = gmtime();

   my $perl = "$]";
   if(defined(&Win32::BuildNumber) and defined &Win32::BuildNumber()) {
       $perl .= " Win32 Build " . &Win32::BuildNumber();
   }
   elsif(defined $MacPerl::Version) {
       $perl .= " MacPerl version " . $MacPerl::Version;
   }

   print $Test::TESTOUT <<"EOF" unless 1.20 < $Test::VERSION ;
# OS            : $^O
# Perl          : $perl
# Local Time    : $loctime
# GMT Time      : $gmtime
# Test          : $Test::VERSION
EOF

   print $Test::TESTOUT <<"EOF";
# Test::Tech    : $VERSION
# Data::Secs2   : $Data::Secs2::VERSION
# =cut 
EOF

   1
}


######
# Cover function for &Test::ok that adds capability to test 
# complex data structures.
#
sub ok
{

   ######
   # If no object, use the default $tech_p object.
   #
   my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;

   my ($diagnostic,$name) = ('',''); 
   my $options = {};
   if( ref($_[-1]) ) {
       $options = pop @_;
       if( ref($options) eq 'ARRAY') {
           my %options = @$options;
           $options = \%options;
       }
       elsif( ref($options) ne 'HASH') {
           $options = {};
       }
   }
   $diagnostic = $options->{diagnostic} if defined $options->{diagnostic};
   $name = $options->{name} if defined $options->{name};

   my ($actual_result, $expected_result, $diagnostic_in, $name_in) = @_;


   ######### 
   # Fill in undefined inputs
   #
   $diagnostic = $diagnostic_in if defined $diagnostic_in;
   $name = $name_in if defined $name_in;
   $diagnostic = $name unless defined $diagnostic;
   $self->{test_name} = $name;  # used by tied handle Test::Tech::Output

   if($self->{Skip_Tests}) { # skip rest of tests switch
       &Test::skip( 1, 0, '');
       if($self->{Skip_Diag}) {
           my $test_number = $Test::ntest - 1;
           print $Test::TESTOUT "# Test $test_number got:\n";
           print $Test::TESTOUT "# Expected: ($self->{Skip_Diag})\n";
       }
       return 1; 
   }

   &Test::ok(stringify($actual_result), stringify($expected_result), $diagnostic);

}


######
#
#
sub skip
{

   ######
   # If no object, use the default $tech_p object.
   #
   my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;

   my ($diagnostic,$name) = ('',''); 
   my $options = {};
   if( ref($_[-1]) ) {
       $options = pop @_;
       if( ref($options) eq 'ARRAY') {
           my %options = @$options;
           $options = \%options;
       }
       elsif( ref($options) ne 'HASH') {
           $options = {};
       }
   }
   $diagnostic = $options->{diagnostic} if $options->{diagnostic};
   $name = $options->{name} if $options->{name};

   my ($mod, $actual_result, $expected_result, $diagnostic_in, $name_in) = @_;

   $diagnostic = $diagnostic_in if defined $diagnostic_in;
   $name = $name_in if defined $name_in;
   $diagnostic = $name unless defined $diagnostic;
   $self->{test_name} = $name;  # used by tied handle Test::Tech::Output

   if($self->{Skip_Tests}) {  # skip rest of tests switch
       &Test::skip( 1, 0, '');
       if($self->{Skip_Diag}) {
           my $test_number = $Test::ntest - 1;
           print $Test::TESTOUT "# Test $test_number got:\n";
           print $Test::TESTOUT "# Expected: ($self->{Skip_Diag})\n";
       }
       return 1; 
   }
  
   &Test::skip($mod, stringify($actual_result), stringify($expected_result), $diagnostic);

}


######
#
#
sub skip_tests
{

   ######
   # If no object, use the default $tech_p object.
   #
   my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;

   my ($value,$diagnostic) =  @_;
   my $result = $self->{Skip_Tests};
   $value = 1 unless (defined $value);
   $self->{Skip_Tests} = $value;
   $diagnostic = 'Test not performed because of previous failure.' unless defined $diagnostic;
   $self->{Skip_Diag} = $value ? $diagnostic : '';
   $result;   
}


#######
# This accesses the values in the %tech hash
#
# Use a dot notation for following down layers
# of hashes of hashes
#
sub tech_config
{

   ######
   # If no object, use the default $tech_p object.
   #
   my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;

   my ($key, $value) = @_;
   my @keys = split /\./, $key;

   #########
   # Follow the hash with the current
   # dot index until there are no more
   # hashes. For success, the dot hash 
   # notation must match the structure.
   #
   my $key_p = $self;
   while (@keys) {

       $key = shift @keys;

       ######
       # Do not allow creation of new configs
       #
       if( defined( $key_p->{$key}) ) {

           ########
           # Follow the hash
           # 
           if( ref($key_p->{$key}) eq 'HASH' ) { 
               $key_p  = $key_p->{$key};
           }
           else {
              if(@keys) {
                   warn( "More key levels than hashes.\n");
                   return undef; 
              } 
              last;
           }
       }
   }


   #########
   # References to arrays and scalars in the config may
   # be transparent.
   #
   my $current_value = $key_p->{$key};
   if( ref($current_value) eq 'SCALAR') {
       $current_value = $$current_value;
   }
   if (defined $value && $key ne 'ntest') {
       if( ref($value) eq 'SCALAR' ) {
           ${$key_p->{$key}} = $$value;
       }
       else {
           ${$key_p->{$key}} = $value;
       }
   }

   $current_value;

}



######
# Demo
#
sub demo
{
   use Data::Dumper;

   ######
   # This subroutine uses no object data; therefore,
   # drop any class or object.
   #
   shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

   my ($quoted_expression, @expression) = @_;

   #######
   # A demo trys to simulate someone typing expresssions
   # at a console.
   #

   #########
   # Print quoted expression so that see the non-executed
   # expression. The extra space is so when pasted into
   # a POD, the POD will process the line as code.
   #
   $quoted_expression =~ s/(\n+)/$1 => /g;
   print $Test::TESTOUT ' => ' . $quoted_expression . "\n";   

   ########
   # @data is the result of the script executing the 
   # quoted expression.
   #
   # The demo output most likely will end up in a pod. 
   # The the process of running the generated script
   # will execute the setup. Thus the input is the
   # actual results. Putting a space in front of it
   # tells the POD that it is code.
   #
   return unless @expression;
  
   $Data::Dumper::Terse = 1;
   my $data = Dumper(@expression);
   $data =~ s/(\n+)/$1 /g;
   $data =~ s/\\\\/\\/g;
   $data =~ s/\\'/'/g;

   print $Test::TESTOUT ' ' . $data . "\n" ;

}


########
# Handle Tie to catch the Test module output
# so that it may be modified.
#
package Test::Tech::Output;
use Tie::Handle;
use vars qw(@ISA);
@ISA=('Tie::Handle');

#####
# Tie 
#
sub TIEHANDLE
{
     my($class, $test_handle, $tech) = @_;
     $class = ref($class) if ref($class); 
     bless {test_out => $test_handle, tech => $tech}, $class;
}


#####
#  Print out the test output
#
sub PRINT
{
    my $self = shift;   
    my $buf = join(defined $, ? $, : '',@_);
    $buf .= $\ if defined $\;
    my $test_name = $self->{tech}->{test_name};
    $buf =~ s/(ok \d+)/$1 - $test_name /g if($test_name);
    $self->stats($buf);
    my $handle = $self->{test_out};
    print $handle $buf;
}

#####
# 
#
sub PRINTF
{
    my $self = shift;   
    $self->PRINT (sprintf(shift,@_));
}

sub stats
{
    my ($self,$buf) = @_;
    #####
    # Stats
    my $tech = $self->{tech};
    my $test_num;
    if($buf =~ /^\s*(not ok|ok)\s*(\d+)/) {
        $test_num = $2;
    }
    if($test_num) {
        if( $tech->{num_tests} < $test_num) {
            push @{$tech->{unplanned}},$test_num;
        }
        if($tech->{last_test} + 1 != $test_num) {
            push @{$tech->{missing}},$test_num;
        }
        $tech->{last_test} = $test_num;
    }
    if($buf =~ /^\d+\.\.(\d+)/) {
        $tech->{num_tests} = $1;
    }
    elsif ($buf =~ /^\s*ok\s*(\d+).*?\#\s*skip/i) {
        push @{$tech->{skipped}},$1;
    }
    elsif ($buf =~ /^\s*not ok\s*(\d+)/i) { 
       push @{$tech->{failed}},$1;
    }
    elsif ($buf =~ /^\s*ok\s*(\d+)/i) {
       push @{$tech->{passed}},$1;
    }
}

1

__END__

=head1 NAME
  
Test::Tech - adds skip_tests and test data structures capabilities to the "Test" module

=head1 SYNOPSIS

 #######
 # Procedural (subroutine) Interface
 #
 # (use for &Test::plan, &Test::ok, &Test::skip drop in)
 #  
 use Test::Tech qw(plan ok skip skip_tests tech_config stringify demo);

 $new_value  = tech_config( $key, $old_value);

 $success = plan(@args);

 $test_ok = ok($actual_results, $expected_results, [@options]);
 $test_ok = ok($actual_results, $expected_results, {@options});
 $test_ok = ok($actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = ok($actual_results, $expected_results, $diagnostic, {@options});
 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name, {@options});

 $test_ok = skip($skip_test, $actual_results,  $expected_results, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, {@options});
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, {@options});
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, {@options});

 $state = skip_tests( $on_off, $skip_diagnostic);
 $state = skip_tests( $on_off );
 $state = skip_tests( );

 $string = stringify( $var, @options); # imported from Data::Secs2
 $string = $tech->stringify($var, [@options]);
 $string = $tech->stringify($var, {@options});

 (@stats) = finish( );
 $num_passed = finish( );

 demo($quoted_expression, @expression)


 #####
 # Object Interface
 # 
 $tech = new Test::Tech;

 $test_ok = $tech->ok($actual_results, $expected_results, [@options]);
 $test_ok = $tech->ok($actual_results, $expected_results, {@options]};
 $test_ok = $tech->ok($actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = $tech->ok($actual_results, $expected_results, $diagnostic, {@options]};
 $test_ok = $tech->ok($actual_results, $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = $tech->ok($actual_results, $expected_results, $diagnostic, $test_name, {@options]};

 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, [@options]);
 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, {@options});
 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, $diagnostic, [@options]);
 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, $diagnostic, {@options});
 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, {@options});

 $state  = $tech->skip_tests( );
 $state  = $tech->skip_tests( $on_off );
 $state = skip_tests( $on_off, $skip_diagnostic );

 $string = $tech->stringify($var); # imported from Data::Secs2
 $string = $tech->stringify($var, @options); 
 $string = $tech->stringify($var, [@options]);
 $string = $tech->stringify($var, {@options});

 $new_value = $tech->tech_config($key, $old_value);

 (@stats) = $tech->finish( );
 $num_passed = $tech->finish( );

 $tech->demo($quoted_expression, @expression)

=head1 DESCRIPTION

The "Test::Tech" module extends the capabilities of the "Test" module.

The design is simple. 
The "Test::Tech" module loads the "Test" module without exporting
any "Test" subroutines into the "Test::Tech" namespace.
There is a "Test::Tech" cover subroutine with the same name
for each "Test" module subroutine.
Each "Test::Tech" cover subroutine will call the &Test::$subroutine
before or after it adds any additional capabilities.
The "Test::Tech" module procedural (subroutine) interface 
is a drop-in for the "Test" module.

The "Test::Tech" has a hybrid interface. The subroutine/methods that use
object data are the 'new', 'ok', 'skip', 'skip_tests', 'tech_config' and 'finish'
subroutines/methods.

When the module is loaded it creates a default object. If any of the
above subroutines/methods are used procedurally, without a class or
object, the subroutine/method will use the default method. 

The "Test::Tech" module extends the capabilities of
the "Test" module as follows:

=over 4

=item *

Compare almost any data structure by passing variables
through the L<Data::Secs2::stringify() subroutine|Data::Secs2/stringify subroutine>
before making the comparision

=item *

Method to skip the rest of the tests, with a $dianostic input,
upon a critical failure. 

=item *

Adds addition $name, [@option], {@option} inputs to the ok and skip subroutines.
The $name input is print as  "ok $test_num - $name" or "not ok $test_num - $name".

=item *

Method to generate demos that appear as an interactive
session using the methods under test

=back

=head2 plan subroutine

 $success = plan(@args);

The I<plan> subroutine is a cover method for &Test::plan.
The I<@args> are passed unchanged to &Test::plan.
All arguments are options. Valid options are as follows:

=over 4

=item tests

The number of tests. For example

 tests => 14,

=item todo

An array of test that will fail. For example

 todo => [3,4]

=item onfail

A subroutine that the I<Test> module will
execute on a failure. For example,

 onfail => sub { warn "CALL 911!" } 

=back

=head2 ok subroutine

 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name, {@options});

The $diagnostic, $test_name, [@options], and {@options} inputs are optional.
The $actual_results and $expected_results inputs may be references to
any type of data structures.  The @options is a hash input that will
process the 'diagnostic' key the same as the $diagnostic input and the
'name' key the same as the $test_name input.

The I<ok> method is a cover function for the &Test::ok subroutine
that extends the &Test::ok routine as follows:

=over 4

=item *

Prints out the I<$test_name> to provide an English identification
of the test. The $test_name appears as either "ok $test_num - $name" or
"not ok $test_num - $name".

=item *

The I<ok> subroutine passes referenced inputs
I<$actual_results> and I<$expectet_results> through 
L<Data::Secs2::stringify() subroutine|Data::Secs2/stringify subroutine>.
The I<ok> method then uses &Test::ok to compare the text results
from L<Data::Secs2::stringify() subroutine|Data::Secs2/stringify subroutine>.

=item *

The I<ok> subroutine method passes variables that are not a reference
directly to &Test::ok unchanged.

=item *

Responses to a flag set by the L<skip_tests subroutine|Test::Tech/skip_tests> subroutine
and skips the test completely.

=back

=head2 skip subroutine

 $test_ok = skip($actual_results, $expected_results, $diagnostic $test_name, [@options]);
 $test_ok = skip($actual_results, $expected_results, $diagnostic $test_name, {@options});

The $diagnostic, $test_name, [@options], and {@options} inputs are optional.
The $actual_results and $expected_results inputs may be references to
any type of data structures.  The @options is a hash input that will
process the 'diagnostic' key the same as the $diagnostic input and the
'name' key the same as the $test_name input.

The I<skip> subroutine is a cover function for the &Test::skip subroutine
that extends the &Test::skip the same as the 
L<ok subroutine|Test::Tech/ok> subroutine extends
the I<&Test::ok> subroutine.

=head2 skip_tests method

 $state = skip_tests( $on_off );
 $state = skip_tests( );

The I<skip_tests> subroutine sets a flag that causes the
I<ok> and the I<skip> methods to skip testing.

=head2 stringify subroutine

 $string = stringify( $var );

The I<stringify> subroutine will stringify I<$var> using
the "L<Data::Secs2::stringify subroutine|Data::Secs2/stringify subroutine>" 
module only if I<$var> is a reference;
otherwise, it leaves it unchanged.

=head2 tech_config subroutine

 $old_value = tech_config( $dot_index, $new_value );

The I<tech_config> subroutine reads and writes the
below configuration variables

 dot index              contents           mode
 --------------------   --------------     --------
 Test.ntest             $Test::ntest       read only 
 Test.TESTOUT           $Test::TESTOUT     read write
 Test.TestLevel         $Test::TestLevel   read write
 Test.ONFAIL            $Test::ONFAIL      read write
 Test.TESTERR           $Test::TESTERR     read write
 Skip_Tests             # boolean          read write
 
The I<tech_config> subroutine always returns the
I<$old_value> of I<$dot_index> and only writes
the contents if I<$new_value> is defined.

The 'SCALAR' and 'ARRAY' references are transparent.
The I<tech_config> subroutine, when it senses that
the I<$dot_index> is for a 'SCALAR' and 'ARRAY' reference,
will read or write the contents instead of the reference.

The The I<tech_config> subroutine will read 'HASH" references
but will never change them. 

The variables for the top level 'Dumper' I<$dot_index> are
established by "L<Data::Dumper|Data::Dumper>" module;
for the top level 'Test', the "L<Test|Test>" module.

=head2 finish subroutine

 (@stats) = $tech->finish( );
 $num_passed = $tech->finish( );

The finish() subroutine/method outputs the test steps
that are missing, failed, unplanned and other statistics.

The finish() subroutine/method restores changes made
to the 'Test' module module made by the 
'tech_config' subroutine/method or directly.

When the 'new' subroutine/method creates a 'Test::Tech'
object, the Perl will automatically run the
'finish' method when that object is destoried.

Running the 'finish' method without a class or object,
restores the 'Test' module to the values when
the 'Test::Tech' module was loaded.

The @stats array consists of the following:

=over 4

=item 0

number of tests

This is calculated as the maximum of the tests planned
and the highest test number. From the maximum, substract
the skipped tests. In other words, the sum of the missed,
passed and failed test steps.

=item 1

reference to the unplanned test steps

=item 2

reference to the missed test steps

=item 3

reference to the skipped test steps

=item 4

reference to the passed test steps

=item 5

reference to the failed test steps

=back

=head2 demo subroutine

 demo($quoted_expression, @expression)

The demo subroutine/method provides a session like out.
The '$quoted_express' is printed out as typed in from
the keyboard.
The '@expression' is executed and printed out as the
results of '$quoted_expression'.

=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Spec;

 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     use Text::Scrub;
 =>     my $s = 'Text::Scrub';

 =>     use File::SmartNL;
 =>     my $snl = 'File::SmartNL';

 =>     my $uut = 'Test::Tech';
 => $snl->fin('techA0.t')
 '#!perl
 #
 #
 use 5.001;
 use strict;
 use warnings;
 use warnings::register;
 use vars qw($VERSION $DATE);
 $VERSION = '0.11';
 $DATE = '2004/04/08';

 BEGIN {
    use FindBIN;
    use File::Spec;
    use Cwd;
    use vars qw( $__restore_dir__ );
    $__restore_dir__ = cwd();
    my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
    chdir $vol if $vol;
    chdir $dirs if $dirs;
    use lib $FindBin::Bin;

    # Add the directory with "Test.pm" version 1.15 to the front of @INC
    # Thus, 'use Test;' in  Test::Tech, will find Test.pm 1.15 first
    unshift @INC, File::Spec->catdir ( cwd(), 'V001015'); 

    # Create the test plan by supplying the number of tests
    # and the todo tests
    require Test::Tech;
    Test::Tech->import( qw(plan ok skip skip_tests tech_config finish) );
    plan(tests => 8, todo => [4, 8]);
 }

 END {
    # Restore working directory and @INC back to when enter script
    @INC = @lib::ORIG_INC;
    chdir $__restore_dir__;
 }

 my $x = 2;
 my $y = 3;

 #  ok:  1 - Using Test 1.15
 ok( $Test::VERSION, '1.15', '', 'Test version');

 skip_tests( 1 ) unless ok( #  ok:  2 - Do not skip rest
     $x + $y, # actual results
     5, # expected results
     '', 'Pass test'); 

 #  ok:  3
 #
 skip( 1, # condition to skip test   
       ($x*$y*2), # actual results
       6, # expected results
       '','Skipped tests');

 #  zyw featureUnder development, i.e todo
 ok( #  ok:  4
     $x*$y*2, # actual results
     6, # expected results
     '','Todo Test that Fails');

 skip_tests(1) unless ok( #  ok:  5
     $x + $y, # actual results
     6, # expected results
     '','Failed test that skips the rest'); 

 ok( #  ok:  6
     $x + $y + $x, # actual results
     9, # expected results
     '', 'A test to skip');

 ok( #  ok:  7
     $x + $y + $x + $y, # actual results
     10, # expected results
     '', 'A not skip to skip');

 skip_tests(0);
 ok( #  ok:  8
     $x*$y*2, # actual results
          12, # expected results
          '', 'Stop skipping tests. Todo Test that Passes');

 ok( #  ok:  9
     $x * $y, # actual results
     6, # expected results
     {name => 'Unplanned pass test'}); 

 finish(); # pick up stats

 __END__

 =head1 COPYRIGHT

 This test script is public domain.

 =cut

 ## end of test script file ##

 '

 =>     my $actual_results = `perl techA0.t`;
 =>     $snl->fout('tech1.txt', $actual_results);
 => $s->scrub_probe($s->scrub_file_line($actual_results))
 '1..8 todo 4 8;
 ok 1 - Test version 
 ok 2 - Pass test 
 ok 3 - Skipped tests  # skip
 not ok 4 - Todo Test that Fails 
 # Test 4 got: '12' (xxxx.t at line 000 *TODO*)
 #   Expected: '6'
 not ok 5 - Failed test that skips the rest 
 # Test 5 got: '5' (xxxx.t at line 000)
 #   Expected: '6'
 ok 6 - A test to skip  # skip
 # Test 6 got:
 # Expected: (Test not performed because of previous failure.)
 ok 7 - A not skip to skip  # skip
 # Test 7 got:
 # Expected: (Test not performed because of previous failure.)
 ok 8 - Stop skipping tests. Todo Test that Passes  # (xxxx.t at line 000 TODO?!)
 ok 9 - Unplanned pass test 
 # Extra  : 9
 # Skipped: 3 6 7
 # Failed : 4 5
 # Passed : 4/6 66%
 '

 => $snl->fin('techC0.t')
 '#!perl
 #
 #
 use 5.001;
 use strict;
 use warnings;
 use warnings::register;

 use vars qw($VERSION $DATE);
 $VERSION = '0.12';
 $DATE = '2004/04/08';

 BEGIN {
    use FindBIN;
    use File::Spec;
    use Cwd;
    use vars qw( $__restore_dir__ );
    $__restore_dir__ = cwd();
    my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
    chdir $vol if $vol;
    chdir $dirs if $dirs;
    use lib $FindBin::Bin;

    # Add the directory with "Test.pm" version 1.24 to the front of @INC
    # Thus, load Test::Tech, will find Test.pm 1.24 first
    unshift @INC, File::Spec->catdir ( cwd(), 'V001024'); 

    # Create the test plan by supplying the number of tests
    # and the todo tests
    require Test::Tech;
    Test::Tech->import( qw(plan ok skip skip_tests tech_config finish) );
    plan(tests => 2, todo => [1]);

 }

 END {
    # Restore working directory and @INC back to when enter script
    @INC = @lib::ORIG_INC;
    chdir $__restore_dir__;
 }

 # 1.24 error goes to the STDERR
 # while 1.15 goes to STDOUT
 # redirect STDERR to the STDOUT
 tech_config('Test.TESTERR', \*STDOUT);

 my $x = 2;
 my $y = 3;

 #  xy feature Under development, i.e todo
 ok( #  ok:  1
     [$x+$y,$y-$x], # actual results
     [5,1], # expected results
     '', 'Todo test that passes');

 ok( #  ok:  2
     [$x+$y,$x*$y], # actual results
     [6,5], # expected results
     '', 'Test that fails');

 finish() # pick up stats

 __END__

 =head1 COPYRIGHT

 This test script is public domain.

 =cut

 ## end of test script file ##

 '

 =>     $actual_results = `perl techC0.t`;
 =>     $snl->fout('tech1.txt', $actual_results);
 => $s->scrub_probe($s->scrub_file_line($actual_results))
 '1..2 todo 1;
 ok 1 - Todo test that passes  # (xxxx.t at line 000 TODO?!)
 not ok 2 - Test that fails 
 # Test 2 got: 'L[4]
   A[0] 
   A[5] ARRAY
   A[1] 5
   A[1] 6
 ' (xxxx.t at line 000)
 #   Expected: 'L[4]
   A[0] 
   A[5] ARRAY
   A[1] 6
   A[1] 5
 '
 # Failed : 2
 # Passed : 1/2 50%
 '

 => $snl->fin('techE0.t')
 '#!perl
 #
 #
 use 5.001;
 use strict;
 use warnings;
 use warnings::register;

 use vars qw($VERSION $DATE);
 $VERSION = '0.07';
 $DATE = '2004/04/08';

 BEGIN {
    use FindBIN;
    use File::Spec;
    use Cwd;
    use vars qw( $__restore_dir__ );
    $__restore_dir__ = cwd();
    my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
    chdir $vol if $vol;
    chdir $dirs if $dirs;
    use lib $FindBin::Bin;

    # Add the directory with "Test.pm" version 1.24 to the front of @INC
    # Thus, load Test::Tech, will find Test.pm 1.24 first
    unshift @INC, File::Spec->catdir ( cwd(), 'V001024'); 

    require Test::Tech;
    Test::Tech->import( qw(plan ok skip skip_tests tech_config finish) );
    plan(tests => 8, todo => [4, 8]);
 }

 END {
    # Restore working directory and @INC back to when enter script
    @INC = @lib::ORIG_INC;
    chdir $__restore_dir__;
 }

 # 1.24 error goes to the STDERR
 # while 1.15 goes to STDOUT
 # redirect STDERR to the STDOUT
 tech_config('Test.TESTERR', \*STDOUT);

 my $x = 2;
 my $y = 3;

 #  ok:  1 - Using Test 1.24
 ok( $Test::VERSION, '1.24', '', 'Test version');

 skip_tests( 1 ) unless ok(   #  ok:  2 - Do not skip rest
     $x + $y, # actual results
     5, # expected results
     {name => 'Pass test'} ); 

 skip( #  ok:  3
       1, # condition to skip test   
       ($x*$y*2), # actual results
       6, # expected results
       {name => 'Skipped tests'});

 #  zyw feature Under development, i.e todo
 ok( #  ok:  4
     $x*$y*2, # actual results
     6, # expected results
     [name => 'Todo Test that Fails',
     diagnostic => 'Should Fail']);

 skip_tests(1,'Skip test on') unless ok(  #  ok:  5
     $x + $y, # actual results
     6, # expected results
     [diagnostic => 'Should Turn on Skip Test', 
      name => 'Failed test that skips the rest']); 

 ok( #  ok:  6 
     $x + $y + $x, # actual results
     9, # expected results
     '', 'A test to skip');

 finish() # pick up stats

 __END__

 =head1 COPYRIGHT

 This test script is public domain.

 =cut

 ## end of test script file ##

 '

 =>     $actual_results = `perl techE0.t`;
 =>     $snl->fout('tech1.txt', $actual_results);
 => $s->scrub_probe($s->scrub_file_line($actual_results))
 '1..8 todo 4 8;
 ok 1 - Test version 
 ok 2 - Pass test 
 ok 3 - Skipped tests  # skip
 not ok 4 - Todo Test that Fails 
 # Test 4 got: '12' (xxxx.t at line 000 *TODO*)
 #   Expected: '6' (Should Fail)
 not ok 5 - Failed test that skips the rest 
 # Test 5 got: '5' (xxxx.t at line 000)
 #   Expected: '6' (Should Turn on Skip Test)
 ok 6 - A test to skip  # skip
 # Test 6 got:
 # Expected: (Skip test on)
 # Missing: 7 8
 # Skipped: 3 6
 # Failed : 4 5
 # Passed : 2/6 33%
 '

 => my $tech = new Test::Tech
 => $tech->tech_config('Test.TestLevel')
 undef

 => $tech->tech_config('Test.TestLevel', 2)
 undef

 => $tech->tech_config('Test.TestLevel')
 2

 => $Test::TestLevel
 2

 => $tech->finish( )
 => $Test::TestLevel
 undef

 => unlink 'tech1.txt'

=head1 QUALITY ASSURANCE

Running the test script 'Tech.t' found in
the "Test-Tech-$VERSION.tar.gz" distribution file verifies
the requirements for this module.

All testing software and documentation
stems from the 
Software Test Description (L<STD|Docs::US_DOD::STD>)
program module 't::Test::Tech::Tech',
found in the distribution file 
"Test-Tech-$VERSION.tar.gz". 

The 't::Test::Tech::Tech' L<STD|Docs::US_DOD::STD> POD contains
a tracebility matix between the
requirements established above for this module, and
the test steps identified by a
'ok' number from running the 'Tech.t'
test script.

The t::Test::Tech::Tech' L<STD|Docs::US_DOD::STD>
program module '__DATA__' section contains the data 
to perform the following:

=over 4

=item *

to generate the test script 'Tech.t'

=item *

generate the tailored 
L<STD|Docs::US_DOD::STD> POD in
the 't::Test::Tech::Tech' module, 

=item *

generate the 'Tech.d' demo script, 

=item *

replace the POD demonstration section
herein with the demo script
'Tech.d' output, and

=item *

run the test script using Test::Harness
with or without the verbose option,

=back

To perform all the above, prepare
and run the automation software as 
follows:

=over 4

=item *

Install "Test_STDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back
  
=item *

manually place the script tmake.pl
in "Test_STDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

place the 't::Test::Tech::Tech' at the same
level in the directory struture as the
directory holding the 'Test::Tech'
module

=item *

execute the following in any directory:

 tmake -test_verbose -replace -run -pm=t::Test::Tech::Tech

=back

=head1 NOTES

=head2 FILES

The installation of the
"Test-Tech-$VERSION.tar.gz" distribution file
installs the 'Docs::Site_SVD::Test_Tech'
L<SVD|Docs::US_DOD::SVD> program module.

The __DATA__ data section of the 
'Docs::Site_SVD::Test_Tech' contains all
the necessary data to generate the POD
section of 'Docs::Site_SVD::Test_Tech' and
the "Test-Tech-$VERSION.tar.gz" distribution file.

To make use of the 
'Docs::Site_SVD::Test_Tech'
L<SVD|Docs::US_DOD::SVD> program module,
perform the following:

=over 4

=item *

install "ExtUtils-SVDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back

=item *

manually place the script vmake.pl
in "ExtUtils-SVDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

Make any appropriate changes to the
__DATA__ section of the 'Docs::Site_SVD::Test_Tech'
module.
For example, any changes to
'File::Package' will impact the
at least 'Changes' field.

=item *

Execute the following:

 vmake readme_html all -pm=Docs::Site_SVD::Test_Tech

=back

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<US DOD 490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###