# test 1 - Make sure config options are type checked
use Inline ASM => 'DATA',
           AS => 'as',
	   ASFLAGS => '',
           PROTOTYPES => {lrotate => 'int(long,int)',
			  greet => 'void(char*)',
			 };

print lrotate(0x00040000, 4), "\n";
print lrotate(0x00040000, 14), "\n";

print greet("Neil");

__END__
__ASM__

.data

/* "Greetings, %s\n" */
printfstr:
	.string "Greetings, %s\n"

.text

.globl	  lrotate
.globl    greet
.extern   printf

/* prototype: long lrotate(long x, int num); */
lrotate:  pushl %ebp
          movl %esp,%ebp
          movl 8(%ebp),%eax
          movl 12(%ebp),%ecx
label:    roll $1,%eax
          loop label
          movl %ebp,%esp
          popl %ebp
          ret

/* prototype: void greet(char*); */
greet:    pushl %ebp
	  movl %esp,%ebp
	  movl 8(%ebp),%eax
	  pushl %eax
          pushl $printfstr
          call printf
	  movl %ebp,%esp
	  popl %ebp
          ret

