#!/usr/bin/perl
use strict;
use warnings;

use ExtUtils::nvcc;
use Inline C => DATA => ExtUtils::nvcc::Inline;

# Generate a series of 100 sequential values and pack them
# as an array of floats:
my $data = pack('f*', 1..100);

# Call the Perl-callable wrapper to the CUDA kernel:
cuda_test($data);

# Print the results
print "Got ", join (', ', unpack('f*', $data)), "\n";

END {
	# I was having trouble with memory leaks. This messgae
	# indicates that the segmentation fault occurrs after
	# the end of the script's execution. (However, it no
	# longer appears to be a problem! :-)
	print "Really done!\n";
}

__END__

__C__

// This is a very simple CUDA kernel that triples the value of the
// global data associated with the location at threadIdx.x. NOTE: this
// is a particularly good example of BAD programming - it should be
// more defensive. It is just a proof of concept, to show that you can
// indeed write CUDA kernels using Inline::C.

__global__ void triple(float * data_g) {
	data_g[threadIdx.x] *= 3;
}

// NOTE: Do not make such a kernel a regular habit. Generally, copying
// data to and from the device is very, very slow (compared with all
// other CUDA operations). This is just a proof of concept.

void cuda_test(char * input) {
	// Inline::C knows how to massage a Perl scalar into a char
	// array (pointer), which I can easily cast as a float pointer:
	float * data = (float * ) input;
	
	// Allocate the memory of the device:
	float * data_d;
	unsigned int data_bytes = sizeof(float) * 100;
	cudaMalloc(&data_d, data_bytes);
	
	// Copy the host memory to the device:
	cudaMemcpy(data_d, data, data_bytes, cudaMemcpyHostToDevice);
	
	// Print a status indicator and execuate the kernel
	printf("Trippling values via CUDA\n");

	// Execute the kernel:
	triple <<<1, 100>>>(data_d);
	
	// Copy the contents back to the Perl scalar:
	cudaMemcpy(data, data_d, data_bytes, cudaMemcpyDeviceToHost);
	
	// Free the device memory
	cudaFree(data_d);
}
