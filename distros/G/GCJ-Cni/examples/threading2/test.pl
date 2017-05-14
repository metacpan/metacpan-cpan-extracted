use strict;
use Benchmark qw(:all);

use Matrix;
use GCJ::Cni;
use threads;

sub populate_matrix {
	my $matrix = shift;
	for ( my $i = 0; $i < $matrix->getRows(); $i++ ) {
		for ( my $j = 0; $j < $matrix->getCols(); $j++ ) {
			$matrix->set($i, $j, $i * $j);
		}
	}
}

sub test_native_java {

	#GCJ::Cni::JvCreateJavaVM(undef);
	#GCJ::Cni::JvAttachCurrentThread(undef, undef);
	
	my $matrix = new Matrix::Matrix(10, 10);
	$matrix->DISOWN();
	populate_matrix($matrix);
	#$matrix->print();
	my $matrix2 = new Matrix::Matrix(10, 10);
	populate_matrix($matrix2);
	$matrix2->DISOWN();
	my $result = $matrix->multiply($matrix2);
	$result->DISOWN();
	$result->print();
	#$matrix = undef;
	#$matrix2 = undef;
	#$result = undef;
	
	#GCJ::Cni::JvDetachCurrentThread();
}

sub test_perl_threads {

	sub thread {
        	#print "Hi from thread: " . threads->tid() . "\n";
        	my $i = 1 + 1;
	}

	my @threads;
	for ( my $i = 0; $i < 10; $i++ ) {
        	my $thread = threads->create("thread");
        	push @threads, $thread;
	}
	
	foreach my $thread ( @threads ) {
	        $thread->join();
	}

}

GCJ::Cni::JvCreateJavaVM(undef);
GCJ::Cni::JvAttachCurrentThread(undef, undef);
#cmpthese( 10, { 'Native Java' => sub { test_native_java() }, 'Perl Threads' => sub { test_perl_threads() } } );
#my $t = timeit(1, sub {test_perl_threads()});
#print "1 loops of other code took:",timestr($t),"\n";
#$t = timeit(1, sub {test_native_java()});
#print "1 loops of other code took:",timestr($t),"\n";
for ( my $i = 0; $i < 100; $i++ ) {
	test_native_java();
}
GCJ::Cni::JvDetachCurrentThread();
