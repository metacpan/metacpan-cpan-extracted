use strict;
use warnings;
use Math::Calc::Parser 'calc';
use Test::More;

cmp_ok calc '3+2', '==', 5, 'Addition';
cmp_ok calc '3-2', '==', 1, 'Subtraction';
cmp_ok calc '3*2', '==', 6, 'Multiplication';
cmp_ok calc '3/2', '==', 1.5, 'Division';
cmp_ok calc '3%2', '==', 1, 'Modulo';
cmp_ok calc '3^2', '==', 9, 'Exponent';
cmp_ok calc '3<<2', '==', 12, 'Left shift';
cmp_ok calc '3>>1', '==', 1, 'Right shift';
cmp_ok calc '3!', '==', 6, 'Factorial';

cmp_ok calc '3+2+5', '==', 10, 'Addition/Addition';
cmp_ok calc '3+2-5', '==', 0, 'Addition/Subtraction';
cmp_ok calc '3+2*5', '==', 13, 'Addition/Multiplication';
cmp_ok calc '3+2/5', '==', 3.4, 'Addition/Division';
cmp_ok calc '3+5%2', '==', 4, 'Addition/Modulo';
cmp_ok calc '3+2^5', '==', 35, 'Addition/Exponent';
cmp_ok calc '3+2<<5', '==', 160, 'Addition/Left shift';
cmp_ok calc '3+5>>2', '==', 2, 'Addition/Right shift';
cmp_ok calc '2+3!', '==', 8, 'Addition/Factorial';

cmp_ok calc '3-2+5', '==', 6, 'Subtraction/Addition';
cmp_ok calc '3-2-5', '==', -4, 'Subtraction/Subtraction';
cmp_ok calc '3-2*5', '==', -7, 'Subtraction/Multiplication';
cmp_ok calc '3-2/5', '==', 2.6, 'Subtraction/Division';
cmp_ok calc '3-5%2', '==', 2, 'Subtraction/Modulo';
cmp_ok calc '3-2^5', '==', -29, 'Subtraction/Exponent';
cmp_ok calc '3-2<<5', '==', 32, 'Subtraction/Left shift';
cmp_ok calc '5-1>>2', '==', 1, 'Subtraction/Right shift';
cmp_ok calc '2-3!', '==', -4, 'Subtraction/Factorial';

cmp_ok calc '3*2+5', '==', 11, 'Multiplication/Addition';
cmp_ok calc '3*2-5', '==', 1, 'Multiplication/Subtraction';
cmp_ok calc '3*2*5', '==', 30, 'Multiplication/Multiplication';
cmp_ok calc '3*2/5', '==', 1.2, 'Multiplication/Division';
cmp_ok calc '3*2%5', '==', 1, 'Multiplication/Modulo';
cmp_ok calc '3*2^5', '==', 96, 'Multiplication/Exponent';
cmp_ok calc '3*2<<5', '==', 192, 'Multiplication/Left shift';
cmp_ok calc '3*5>>2', '==', 3, 'Multiplication/Right shift';
cmp_ok calc '2*3!', '==', 12, 'Multiplication/Factorial';

cmp_ok calc '3/2+5', '==', 6.5, 'Division/Addition';
cmp_ok calc '3/2-5', '==', -3.5, 'Division/Subtraction';
cmp_ok calc '3/2*5', '==', 7.5, 'Division/Multiplication';
cmp_ok calc '3/2/5', '==', 0.3, 'Division/Division';
cmp_ok calc '6/3%2', '==', 0, 'Division/Modulo';
cmp_ok calc '6/2^3', '==', 0.75, 'Division/Exponent';
cmp_ok calc '4/2<<5', '==', 64, 'Division/Left shift';
cmp_ok calc '6/2>>1', '==', 1, 'Division/Right shift';
cmp_ok calc '3/2!', '==', 1.5, 'Division/Factorial';

cmp_ok calc '5%3+2', '==', 4, 'Modulo/Addition';
cmp_ok calc '5%3-2', '==', 0, 'Modulo/Subtraction';
cmp_ok calc '5%3*2', '==', 4, 'Modulo/Multiplication';
cmp_ok calc '5%3/2', '==', 1, 'Modulo/Division';
cmp_ok calc '5%3%2', '==', 0, 'Modulo/Modulo';
cmp_ok calc '5%2^2', '==', 1, 'Modulo/Exponent';
cmp_ok calc '5%3<<2', '==', 8, 'Modulo/Left shift';
cmp_ok calc '5%3>>1', '==', 1, 'Modulo/Right shift';
cmp_ok calc '8%3!', '==', 2, 'Modulo/Factorial';

cmp_ok calc '3^2+5', '==', 14, 'Exponent/Addition';
cmp_ok calc '3^2-5', '==', 4, 'Exponent/Subtraction';
cmp_ok calc '3^2*5', '==', 45, 'Exponent/Multiplication';
cmp_ok calc '3^2/5', '==', 1.8, 'Exponent/Division';
cmp_ok calc '3^2%5', '==', 4, 'Exponent/Modulo';
cmp_ok calc '4^2^3', '==', 65536, 'Exponent/Exponent';
cmp_ok calc '3^2<<5', '==', 288, 'Exponent/Left shift';
cmp_ok calc '3^2>>2', '==', 2, 'Exponent/Right shift';
cmp_ok calc '2^3!', '==', 64, 'Exponent/Factorial';

cmp_ok calc '3<<2+5', '==', 384, 'Left shift/Addition';
cmp_ok calc '3<<5-2', '==', 24, 'Left shift/Subtraction';
cmp_ok calc '3<<2*3', '==', 192, 'Left shift/Multiplication';
cmp_ok calc '3<<4/2', '==', 12, 'Left shift/Division';
cmp_ok calc '3<<5%2', '==', 6, 'Left shift/Modulo';
cmp_ok calc '3<<2^3', '==', 768, 'Left shift/Exponent';
cmp_ok calc '3<<2<<5', '==', 384, 'Left shift/Left shift';
cmp_ok calc '3<<2>>3', '==', 1, 'Left shift/Right shift';
cmp_ok calc '3<<3!', '==', 192, 'Left shift/Factorial';

cmp_ok calc '15>>2+1', '==', 1, 'Right shift/Addition';
cmp_ok calc '15>>2-1', '==', 7, 'Right shift/Subtraction';
cmp_ok calc '15>>2*2', '==', 0, 'Right shift/Multiplication';
cmp_ok calc '15>>2/2', '==', 7, 'Right shift/Division';
cmp_ok calc '15>>5%3', '==', 3, 'Right shift/Modulo';
cmp_ok calc '15>>2^2', '==', 0, 'Right shift/Exponent';
cmp_ok calc '15>>3<<1', '==', 2, 'Right shift/Left shift';
cmp_ok calc '15>>2>>1', '==', 1, 'Right shift/Right shift';
cmp_ok calc '15>>3!', '==', 0, 'Right shift/Factorial';

cmp_ok calc '3!+5', '==', 11, 'Factorial/Addition';
cmp_ok calc '3!-5', '==', 1, 'Factorial/Subtraction';
cmp_ok calc '3!*5', '==', 30, 'Factorial/Multiplication';
cmp_ok calc '3!/5', '==', 1.2, 'Factorial/Division';
cmp_ok calc '3!%5', '==', 1, 'Factorial/Modulo';
cmp_ok calc '3!^2', '==', 36, 'Factorial/Exponent';
cmp_ok calc '3!<<2', '==', 24, 'Factorial/Left shift';
cmp_ok calc '3!>>2', '==', 1, 'Factorial/Right shift';
cmp_ok calc '3!!', '==', 720, 'Factorial/Factorial';

done_testing;
