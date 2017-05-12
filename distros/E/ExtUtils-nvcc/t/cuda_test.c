// This is a simple C program that should be easily compilable with nvcc, and
// thus ExtUtils::nvcc. Note that nvcc always invokes the C++ compiler, so we
// should use actual C++ compatible code instead of plain C code:

#include <cstdio>
#include <cstring>

// This is a kernel that 'fixes' fubarred text. The text was fubarred by adding
// 1 to each character; this subtracts 1 from each character.
__global__ void fix_kernel(char * text) {
	text[threadIdx.x] -= 1;
}

// Fubars the message by adding one to each character:
void fubar_message (char * message) {
	int i;
	for (i = 0; i < 11; i++) {
		message[i] += 1;
	}
}

// Creates memory on the device for the message and croaks on error:
char * create_dev_message () {
	// allocate memory on the device and check for errors:
	char * dev_message;
	cudaError_t err = cudaMalloc(&dev_message, 12);
	if (err != cudaSuccess) {
		printf("Trouble with memory!\n");
		exit(1);
	}
	
	return dev_message;
}

// Copies the message to the device and croaks on error:
void copy_message_to_dev(char * message, char * dev_message) {
	cudaError_t err = cudaMemcpy(dev_message, message, 12, cudaMemcpyHostToDevice);
	if (err != cudaSuccess) {
		printf("Trouble copying memory to the device!\n");
		exit(2);
	}
}

// Runs the kernel that's supposed to fix the text, and croaks on error:
void run_fix_kernel(char * dev_message) {
	// run the kernel on the device:
	fix_kernel<<<1, 11>>>(dev_message);
	// Check for errors:
	cudaError_t err = cudaThreadSynchronize();
	if (err != cudaSuccess) {
		printf("Trouble running the kernel!\n");
		exit(3);
	}
}

// Copies the (unfubarred) message back to the host, and croaks on error:
void copy_message_to_host(char * message, char * dev_message) {
	cudaError_t err = cudaMemcpy(message, dev_message, 12, cudaMemcpyDeviceToHost);
	if (err != cudaSuccess) {
		printf("Trouble copying memory back to host!\n");
		exit(4);
	}
}

// Cleans up the memory on the device and croaks on error:
void clean_up_dev_memory(char * dev_message) {
	cudaError_t err = cudaFree(dev_message);
	if (err != cudaSuccess) {
		printf("Trouble freeing device memory!\n");
		exit(5);
	}
}

// Tests that the resulting text is correct:
void test_result(char * message) {
	if (strncmp(message, "good to go!", 12) == 0) {
		printf("Success");
	}
	else {
		printf("%s", message);
	}
}

int main() {
	// This has 11 fidlable characters. The twelfth should not be fiddled:
	char message[12] = "good to go!";
	
	// mess up the message
	fubar_message(message);
	
	// Allocate the device memory and copy the contents:
	char * dev_message = create_dev_message();
	copy_message_to_dev(message, dev_message);
	
	// Run the kernel to fix the message:
	run_fix_kernel(dev_message);
	
	// Copy the result back and clean up the cuda memory:
	copy_message_to_host(message, dev_message);
	clean_up_dev_memory(dev_message);
	
	// Test that the message was restored:
	test_result(message);
}
