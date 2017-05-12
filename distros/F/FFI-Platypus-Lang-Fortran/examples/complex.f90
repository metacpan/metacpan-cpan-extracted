! on Linux: gfortran -shared -fPIC -o libcomplex.so complex.f90

!! Platypus does not yet natively support the complex type
!!function complex_combine(r,i) result(ret)
!!  implicit none
!!  complex*16 :: ret
!!  real*8 :: r
!!  real*8 :: i
!!
!!  write(*,*) r
!!  write(*,*) i
!!  
!!  ret = cmplx(r,i)
!!
!!end function complex_combine

subroutine complex_decompose(c,r,i) 
  implicit none
  complex*16 :: c
  real*8 :: r
  real*8 :: i
  
  r = real(c)
  i = aimag(c)
end subroutine complex_decompose
