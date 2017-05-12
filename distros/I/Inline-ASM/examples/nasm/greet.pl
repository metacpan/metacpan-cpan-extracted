# test 1 - Make sure config options are type checked
use Inline ASM => 'DATA',
           PROTOTYPES => {lrotate => 'int(long,int)',
			  greet => 'void(char*)',
			 };

print lrotate(0x00040000, 4), "\n";
print lrotate(0x00040000, 14), "\n";

print greet("Neil");

__END__
__ASM__

          BITS 32
          GLOBAL lrotate        ; [1]
          GLOBAL greet          ; [1]
          EXTERN printf         ; [10]

          SECTION .text

; prototype: long lrotate(long x, int num);
lrotate:                        ; [1]
          push ebp
          mov ebp,esp
          mov eax,[ebp+8]
          mov ecx,[ebp+12]
.label    rol eax,1             ; [4] [8]
          loop .label           ; [9] [12]
          mov esp,ebp
          pop ebp
          ret

; prototype: void greet(char*);
greet   push ebp
	mov ebp,esp
	mov eax,[ebp+8]
	push dword eax	
        push dword printfstr 
        call printf
	mov esp,ebp
	pop ebp
        ret

        SECTION .data

; "Greetings, %s\n"
printfstr db "Greetings, %s", 10, 0

