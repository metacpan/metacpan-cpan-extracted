use strict;
use warnings;
use Math::Symbolic 0.613 qw(:all);
use Math::Symbolic::Custom::Equation 0.2;
use Math::Symbolic::Custom::CollectSimplify 0.2;
Math::Symbolic::Custom::CollectSimplify->register();
use Physics::Unit::Scalar 0.6 ':ALL';
$Physics::Unit::Scalar::format_string = "%.3f";

print <<'END';
There are 3 boxes connected by cables on pulleys (ideal system).
(see graphic below)
The boxes should move by gravity.
m_1 = 1 kg, m_2 = 1.5 kg, m_3 = 3 kg 
The coefficient of friction between table and m_2 is mu_k = 0.5
Find the acceleration a and tensions T_1, T_2.
 

                   +-----+
     O----<T_1>----| m_2 |----<T_2>---O
     | \__         +-----+        __/ |
     |    #######################     |
  +-----+ ###                 ### +-----+
  | m_1 | ###                 ### | m_3 |
  +-----+ ###                 ### +-----+
          ###                 ###
          ###                 ###


END

print "The system of force equations is:-\n\n";

my $eq1 = Math::Symbolic::Custom::Equation->new('T_1 - m_1*g = m_1*a');
my $eq2 = Math::Symbolic::Custom::Equation->new('T_2 - mu_k*m_2*g - T_1 = m_2*a');
my $eq3 = Math::Symbolic::Custom::Equation->new('m_3*g - T_2 = m_3*a');

print "\t[1]\t", $eq1->to_string(), "\n";
print "\t[2]\t", $eq2->to_string(), "\n";
print "\t[3]\t", $eq3->to_string(), "\n\n";

print "Add [1], [2], [3] to eliminate T1 and T2:\n\n";

my $eq4 = $eq1->add($eq2)->add($eq3)->simplify();

print "\t[4]\t", $eq4->to_string(), "\n\n";

# Find acceleration
print "Isolate the acceleration a in [4]:\n\n";

my $eq_a = $eq4->isolate('a');

print "\t[5]\t", $eq_a->to_string(), "\n\n";

# setup known values. Use Physics::Unit to keep units correct
my %known_vals = (
    m_1     => GetScalar("1 kg"),
    m_2     => GetScalar("1.5 kg"),
    m_3     => GetScalar("3 kg"),
    g       => GetScalar("1 earth-gravity"),
    mu_k    => GetScalar("0.5"),
);

print "Plug known values into [5] to find a:-\n\n";
while ( my ($k, $v) = each %known_vals ) {
    print "\t$k = $v\n";
}
print "\n";

my $a_val = $eq_a->RHS()->value(\%known_vals);

print "From [5] the acceleration a = $a_val\n\n";

# add to hash of known values
$known_vals{a} = $a_val;

# Find T_1
print "Isolate T_1 in [1]:\n\n";

my $eq_T_1 = $eq1->isolate('T_1');

print "\t[6]\t", $eq_T_1->to_string(), "\n\n";

my $T_1_val = $eq_T_1->RHS()->value(\%known_vals);

print "From [6] the tension T_1 = $T_1_val\n\n";

$known_vals{T_1} = $T_1_val;

# Find T_2
print "Isolate T_2 in [3]:\n\n";

my $eq_T_2 = $eq3->isolate('T_2');

print "\t[7]\t", $eq_T_2->to_string(), "\n\n";

my $T_2_val = $eq_T_2->RHS()->value(\%known_vals);

print "From [7] the tension T_2 = $T_2_val\n\n";

$known_vals{T_2} = $T_2_val;

# Plug everything into [2] to check
print "Check [2] holds with computed values:-\n\n";

if ( $eq2->holds(\%known_vals) ) {
    print "\t[2] holds!\n";
}
else {
    print "\tERROR: [2] does not hold with those values!\n";
}


