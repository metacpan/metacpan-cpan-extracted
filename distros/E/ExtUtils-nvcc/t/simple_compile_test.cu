// This is a simple C program that should be easily compilable with nvcc, and
// thus ExtUtils::nvcc. Note that nvcc always invokes the C++ compiler, so we
// should use actual C++ compatible code instead of plain C code:

#include <cstdio>

int main() {
	printf("good to go!");
	return 0;
}
