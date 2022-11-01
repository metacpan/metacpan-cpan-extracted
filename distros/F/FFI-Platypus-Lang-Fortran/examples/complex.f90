subroutine complex_decompose(c, r, i) 
  implicit none
  complex*16, intent(in) :: c
  real*8, intent(out):: r
  real*8, intent(out) :: i
  
  r = real(c)
  i = aimag(c)
end subroutine complex_decompose
