use Inline ASM => <<'END', PROTOTYPES => {JAxH => 'void(char*)'};

.globl JAxH
.text

# prototype: void JAxH(char *x);
JAxH:	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	pushl %eax
        pushl $jaxhstr
        call printf
	movl %ebp,%esp
	popl %ebp
        ret

.data

jaxhstr:
	.string "Just Another %s Hacker\n"
END

print JAxH('Perl');
