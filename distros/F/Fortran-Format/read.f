      PROGRAM FORMTST

      DOUBLE PRECISION D
      INTEGER I
      CHARACTER*40 INFORM, C, IFORM, CFORM, DFORM, LFORM, LINE
      CHARACTER*1  CTYPE
      LOGICAL L

      DATA IFORM /'(I10)'/
      DATA DFORM /'(E16.3)'/
      DATA LFORM /'(L1)'/
      DATA CFORM /'(A40)'/

      OPEN (UNIT=77,FILE='read_tests.txt' )

C     READ TEST FILE
 10   CONTINUE
         READ(77, '(A1,6X,A40)', END=177, ERR=77) CTYPE, INFORM
         WRITE (*, '(A1''FORMAT''A40)') CTYPE, INFORM
         READ(77, '(A)', END=177, ERR=77) LINE
         WRITE (*, '(A40)') LINE
         IF (CTYPE.EQ.'I') THEN
            READ (LINE, INFORM, END=177, ERR=77) I
            WRITE (*, '(A1''FORMAT''A40)') CTYPE, IFORM
            WRITE (*, IFORM) I
         ELSE IF (CTYPE.EQ.'D') THEN
            READ(LINE, INFORM, END=177, ERR=77) D
            WRITE (*, '(A1''FORMAT''A40)') CTYPE, DFORM
            WRITE(*, DFORM) D
         ELSE IF (CTYPE.EQ.'L') THEN
            READ(LINE, INFORM, END=177, ERR=77) L
            WRITE (*, '(A1''FORMAT''A40)') CTYPE, LFORM
            WRITE(*, LFORM) L
         ELSE IF (CTYPE.EQ.'C') THEN
            READ(LINE, INFORM, END=177, ERR=77) C
            WRITE (*, '(A1''FORMAT''A40)') CTYPE, CFORM
            WRITE(*, CFORM) C
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
C      WRITE (*, '(''END'')')

      END

