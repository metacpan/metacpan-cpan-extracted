C Compile with gfortran -shared -o libsub.so sub.f
      SUBROUTINE ADD(IRESULT, IA, IB)
          IRESULT = IA + IB
      END

