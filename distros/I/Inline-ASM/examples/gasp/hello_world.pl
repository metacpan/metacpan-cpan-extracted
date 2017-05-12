use Inline ASM => 'DATA',
    	   PROTO => {hello_world => 'void()' };

hello_world();

__END__
__ASM__

# Define some handy preprocessor variables. syscall numbers et al.
write	.EQU $4
exit	.EQU $1
stdout	.EQU $1
kernel	.EQU $0x80

# Use a preprocessor variable to emit the real string.
pvhello	.ASSIGNC "Hello, Inline::ASM"
pvlen	.EQU .LEN(\&pvhello) + 1	# sizeof the string + newline

# Emit the variable into the initialized data segment, followed by \n and 0
hello	.SDATA "\&pvhello",<10>,<0>

# Silly example of a macro. Lets us just call "syscall" instead of int $0x80
.MACRO syscall
	int kernel
.ENDM

# Define a global symbol to start from. ld bitches if it's not _start.
.GLOBAL hello_world

# Entry point.
hello_world:
	# Set up arguments
	movl stdout,	%ebx
	movl $(hello),	%ecx
	movl $(pvlen),	%edx

	# call sys_write and sys_exit 
	movl write, %eax
	syscall
	movl exit, %eax
	syscall
.END
