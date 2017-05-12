# test 1 - Make sure config options are type checked

print "9 + 16 = ", add(9, 16), "\n";
print "9 - 16 = ", subtract(9, 16), "\n";

use Inline ASM => 'DATA',
    	   AS => 'as',
	   ASFLAGS => '',
           PROTO => {add=>'int(int,int)'};

use Inline ASM => 'DATA',
    	   AS => 'nasm',
	   ASFLAGS => '-f elf',
           PROTO => {subtract=>'int(int,int)'};

__END__
__ASM__

.text
.globl	  add

add:	  movl 4(%esp),%eax
	  addl 8(%esp),%eax
	  ret
__ASM__
          GLOBAL subtract
	  SECTION .text

subtract: mov eax,[esp+4]
          sub eax,[esp+8]
          ret
