      PROGRAM FORMTST

C THIS PROGRAM IS USED FOR TESTING THE Fortran::Format Perl MODULE
C THE PERL MODULE HAS BEEN WRITTEN TO REPRODUCE THE OUTPUT OF THE INTEL
C FORTRAN COMPILER. G77 GIVE ALMOST EXACTLY THE SAME OUTPUT EXCEPT FOR
C SOME OPTIONAL DIFFERENCES (THE USE OF 'D' VS 'E' FOR EXPONENTS) AND
C ONE MINOR DETAIL WHERE G77 DOESN'T COMPLY WITH THE STANDARD: 
C    WRITE (*, 'F1.0'), 0.0
C WHICH GIVES '.' IN G77 AND '*' IN IFC

      INTEGER IARR(21)
      DOUBLE PRECISION DARR(16)
      INTEGER I
      CHARACTER*40 IFORMS(99), DFORMS(99), LFORMS(99), CFORMS(99)
      CHARACTER*10 CARR(10)
      LOGICAL LARR(6)

      DATA IARR /1,2,3,4,5,6,7,8,9,10,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1, 0/
      DATA DARR /0.0, 1.2346, -1.2346, 12.346, 123.46, 1234.6, 12346.0,
     .   1.2346D12, 1.2346D-12, -1.2346D12, -1.2346D-12, -0.0,
     .   1.2346D123, 1.2346D-123, 0.12346, -0.12346/
      DATA LARR /.TRUE., .FALSE., .TRUE., .TRUE., .FALSE., .TRUE./
      DATA CARR /'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE',
     .   'A B C D E', 'ABCDEFGHIJ', '   RRR',
     .   'LLL   ', '   MMM   '/
      
      IFORMS( 1)='(2I4)'
      IFORMS( 2)='(2(I4))'
      IFORMS( 3)='(I4I4)'
      IFORMS( 4)='(I4 I4)'
      IFORMS( 5)='(I 4 I 4)'
      IFORMS( 6)='(I4, I4)'
      IFORMS( 7)='(I4 ''  J OE'' I4)'
      IFORMS( 8)='((I4I4))'
      IFORMS( 9)='(2I4.2)'
      IFORMS(10)='(2I4I4)'
      IFORMS(11)='(2I1)'
      IFORMS(12)='(I4''JOE1''I4''JOE2'')'
      IFORMS(13)='(I4 '' JOE''''S'' I4)'
      IFORMS(14)='(I4SPI4)'
      IFORMS(15)='(SSI4SPI4)'
      IFORMS(16)='(SI4SPI4)'
      IFORMS(17)='(2(I2I4))'
      IFORMS(18)='(2(I2,3(I3I4)))'
      IFORMS(19)='(I1 8)'
      IFORMS(20)='(I4,1X,I4)'
      IFORMS(21)='(I4,X,I4)'
      IFORMS(22)='(I4XI4)'
      IFORMS(23)='(I4,4XI4)'
      IFORMS(24)='(I4X''X''I4)'
      IFORMS(25)='(I4T2I4)'
      IFORMS(26)='(I4TL2I4)'
      IFORMS(27)='(I4TR2I4)'
      IFORMS(28)='(2(I8),I2)'
      IFORMS(29)='(''ODD ''I4/''EVEN''I4)'
      IFORMS(30)='(''ODD ''I4,4X/''EVEN''I4)'
      IFORMS(31)='(I4 :''  J OE'' I4)'
      IFORMS(32)='(I4,8HH-STRING,I4)'
      IFORMS(33)='(I4,8HH-STRINGI4)'
      IFORMS(34)='(I4,10HH-STRING''SI4)'
      IFORMS(35)='(I9, 2(I6))'
      IFORMS(36)='(I9, 2(I6, 3(I4)))'
      IFORMS(37)='(4I8.0)'
C      IFORMS(36)='(I9, 2(I6), 2(''HELLO''))'

      DO 10 I=1,37
         WRITE (*, '(''IFORMAT''A)') IFORMS(I)
         WRITE (*, IFORMS(I)) IARR
         WRITE (*, '()')
 10   CONTINUE

      DFORMS( 1)='(F16.4)'
      DFORMS( 2)='(F8.2)'
      DFORMS( 3)='(F8.3)'
      DFORMS( 4)='(F16.0)'
      DFORMS( 5)='(SPF8.3)'
      DFORMS( 6)='(D8.3)'
      DFORMS( 7)='(E8.3)'
      DFORMS( 8)='(E14.3E5)'
      DFORMS( 9)='(1P1E10.3)'
      DFORMS(10)='(-1P1E10.3)'
      DFORMS(11)='(+1P1E10.3)'
      DFORMS(12)='(D12.3)'
      DFORMS(13)='(E12.3)'
      DFORMS(14)='(F6.5)'
      DFORMS(15)='(F2.0)'
      DFORMS(16)='(F2.1)'
      DFORMS(17)='(F1.0)'
      DFORMS(18)='(-2P1E10.3)'
      DFORMS(19)='(+2P1E10.3)'
      DFORMS(20)='(-8P1E10.3)'
      DFORMS(21)='(F6.4)'
      DFORMS(22)='(SPF6.4)'
      DFORMS(23)='(E8.2)'
      DFORMS(24)='(SPE8.2)'
      DFORMS(25)='(E18.4E4)'
      DFORMS(26)='(E18.4E3)'
      DFORMS(27)='(E18.4E2)'
      DFORMS(28)='(E18.4E1)'
      DFORMS(29)='(E18.4E10)'
      DFORMS(30)='(G18.3)'
      DFORMS(31)='(G18.3E4)'
      DFORMS(32)='(0PF16.4)'
      DFORMS(33)='(-3PF16.4)'
      DO 20 I=1,33
         WRITE (*, '(''DFORMAT''A)') DFORMS(I)
         WRITE (*, DFORMS(I)) DARR
         WRITE (*, '()')
 20   CONTINUE

      LFORMS( 1)='(L1)'
      LFORMS( 2)='(L8)'
      LFORMS( 3)='(L1L2L3L4)'
      LFORMS( 4)='(L2L2L2)'
      DO 30 I=1,4
         WRITE (*, '(''LFORMAT''A)') LFORMS(I)
         WRITE (*, LFORMS(I)) LARR
         WRITE (*, '()')
 30   CONTINUE

      CFORMS( 1)='(A)'
      CFORMS( 2)='(A20)'
      CFORMS( 3)='(A4)'
      CFORMS( 4)='(3A)'
      CFORMS( 5)='(3A20)'
      DO 40 I=1,5
         WRITE (*, '(''CFORMAT''A)') CFORMS(I)
         WRITE (*, CFORMS(I)) CARR
         WRITE (*, '()')
 40   CONTINUE

C      WRITE (*, 100) 123
C  100 FORMAT(7HHELLO  ,I4)
C  101 FORMAT(I4, X, I3)
C  102 FORMAT(I4, 2X, I3)
      END

