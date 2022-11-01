subroutine print_array10(a)
  implicit none
  integer, dimension(10) :: a
  integer :: i
  
  do i=1,10
    print *, a(i)
  end do
  
end subroutine print_array10
