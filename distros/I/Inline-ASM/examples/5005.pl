# test 1 - Make sure config options are type checked
use Inline ASM => 'DATA',
           AS => 'as',
	   ASFLAGS => '',
           PROTOTYPES => {add => 'SV*(int,int)',
			 };

print add(10, "12"), "\n";

__END__
__ASM__

.data

/* "Greetings, %s\n" */
printfstr:
	.string "Greetings, %s\n"

.text

.globl    add
.extern   Perl_newSViv

/* prototype: int add(int,int); */
add:      pushl %ebp
	  movl %esp,%ebp
	  movl 8(%esp),%eax
	  addl 12(%esp),%eax
	  pushl %eax
	  call Perl_newSViv
	  addl $4,%esp
	  leave
          ret
