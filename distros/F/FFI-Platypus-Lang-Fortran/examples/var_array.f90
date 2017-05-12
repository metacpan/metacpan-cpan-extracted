function sum_array(size,a) result(ret)
  implicit none
  integer :: size
  integer, dimension(size) :: a
  integer :: i
  integer :: ret
 
  ret = 0
  
  do i=1,size
    ret = ret + a(i)
  end do
  
end function sum_array
