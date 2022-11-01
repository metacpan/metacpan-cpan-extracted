subroutine print_array2x5(a)
  implicit none
  integer, dimension(2,5) :: a
  integer :: i,n
  
  do i=1,5
    print *, a(1,i), a(2,i)
  end do

end subroutine print_array2x5
