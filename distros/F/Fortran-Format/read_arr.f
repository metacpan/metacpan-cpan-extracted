      PROGRAM FORMTST

      DOUBLE PRECISION D
      INTEGER I, IA(4), IM(2,2)
      CHARACTER*40 INFORM, C, IFORM, CFORM, DFORM, LFORM, LINE
      CHARACTER*1  CTYPE
      LOGICAL L

      DATA IFORM /'(I10)'/
      DATA DFORM /'(E16.3)'/
      DATA LFORM /'(L1)'/
      DATA CFORM /'(A40)'/

      OPEN (UNIT=77,FILE='read_arr_tests.txt' )

C     READ TEST FILE
 10   CONTINUE
         READ(77, '(A1,6X,A40)', END=177, ERR=77) CTYPE, INFORM
         WRITE (*, '(A1''FORMAT''A40)') CTYPE, INFORM
         IF (CTYPE.EQ.'A') THEN
            READ(77, INFORM, END=177, ERR=77) IA
            WRITE (*, '(A1''FORMAT''A40)') 'I', IFORM
            WRITE(*, IFORM) IA
         ELSE IF (CTYPE.EQ.'M') THEN
            READ(77, INFORM, END=177, ERR=77) IM
            WRITE (*, '(A1''FORMAT''A40)') 'I', IFORM
            WRITE(*, IFORM) IM
C           REMEMBER IT GOES 'VERTICALLY'!
C            WRITE(*, IFORM) IM(1,1), IM(1,2), IM(2,1), IM(2,2)
         ENDIF
         READ (77, *)
         WRITE (*, '()')
      GOTO 10
 77   CONTINUE
C        "HANDLE" ERROR
         WRITE (*, '(''ERROR!!'')')
         READ (77, *)
         WRITE (*, '()')
      GOTO 10
 177  CONTINUE
      WRITE (*, '(''END'')')

      END

