# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.


BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::ES;
$loaded = 1;
print "Module import ............ ok 1\n";

######################### End of black magic.

print "General sphere test ...... " ; print &test1 ? "ok 2\n" : "not ok 2\n";
print "Stairs function test ..... " ; print &test2 ? "ok 3\n" : "not ok 3\n";
print "Schwefel function test ... " ; print &test3 ? "ok 4\n" : "not ok 4\n";




sub test1 {

my $e = new Math::ES (
		      'debug' => 0,
		      'elite' => 0,
		      'individuals' => 10,
		      'children'    => 25,
		      'populations' => 3,
		      'selection_scheme' => 1,
		      'generations' => 100,
		      'migrators' => 2,
		      'isolation' => 50,
		      'genes'  => [ -100,-50, 5, 200],
		      'gene_deviations' => [ 1,1,1,1],
		      'max_gene_values' => [ 500, 500, 500, 500],
		      'min_gene_values' => [-500,-500,-500,-500],
		      'rating_function' => \&f1,
		      );

$e->start();

my @genes = $e->return_best_genes();
my $value = $e->return_best_value();

my $ok = 1;
foreach (@genes, $value) {
    $ok = 0 if ($_ > 1.0e-3);
}

return ($ok);
}

sub test2 {
my $e = new Math::ES (
		      'elite' => 2,
		      'individuals' => 10,
		      'children'    => 25,
		      'populations' => 1,
		      'migrators'   => 0,
		      'selection_scheme' => 2,
		      'isolation'   => 0,
		      'generations' => 200,
		      'genes'  => [ -10, 0, 4.2, -7.77],
		      'gene_deviations' => [ 2,0.5,1,1.5],
		      'max_gene_values' => [ 50, 10, 50, 10],
		      'min_gene_values' => [-50,-10,-50,-10],
		      'rating_function' => \&f3,
		      );
$e->start();

my @genes = $e->return_best_genes();
my $value = $e->return_best_value();

my $ok = 1;
$ok = 0 unless (int($genes[0]) >= 48 );
$ok = 0 unless (int($genes[1]) >= 8);
$ok = 0 unless (int($genes[2]) >= 48);
$ok = 0 unless (int($genes[3]) >= 8);
$ok = 0 unless (int($value) <= 2*48+2*8);

return ($ok);

}

sub test3 {
my $e = new Math::ES (
		      'elite' => 1,
		      'individuals' => 5,
		      'children'    => 15,
		      'populations' => 4,
		      'generations' => 60,
		      'migrators'   => 0,
		      'isolation' => 50,
		      'genes'  => [ 10, 1.1, 42, 7.77, 100, 777, 2.3],
		      'gene_deviations' => [ 2, 0.5, 1, 1.5, 2, 5, 0.1],
		      'max_gene_values' => [ 50, 10, 50, 10, 200, 1000, 3.14],
		      'min_gene_values' => [ 0, 0, 0, 0, 0, 0, 0],
		      'rating_function' => \&f7,
		      );

$e->start();

my $ok = 0;
while (not $ok) {
    $e->{'generations'} = 20;
    $e->run();

    my @genes = $e->return_best_genes();
    my $value = $e->return_best_value();

    $ok = 1;
    foreach (@genes, $value) {
	$ok = 0 if ($_ > 1.0e-3);
    }
    
}

return ($ok);
}

#
# Sphere
#
sub f1 {
    my $sum;
    foreach my $x (@_) {
	$sum += $x*$x;
    }
    return($sum);
}


#
# Stairs function
#
sub f3 {
    my $sum;
    foreach my $x (@_) {
	$sum += int($x);
    }
    return(-$sum);
}


#
# Schwefel 1
#
#
# Minimum at (0,0,...0) with 0
#  for x_i >= 0
sub f7 {
    my $sum;
    foreach my $x (@_) {
	$sum += $x;
    }
    $sum = $sum*$sum;
    return($sum);    
}









