use Inline ASM => <<'END', PROTOTYPES => {JAxH => 'void(char*)'};

	BITS 32
	GLOBAL JAxH
	EXTERN printf

	SECTION .text

; prototype: void JAxH(char *x);
JAxH	push ebp
	mov ebp,esp
	mov eax,[ebp+8]
	push dword eax		; x
        push dword jaxhstr	; "just ..."
        call printf
	mov esp,ebp
	pop ebp
        ret

	SECTION .data

jaxhstr	db "Just Another %s Hacker", 10, 0
END

print JAxH('Perl');
