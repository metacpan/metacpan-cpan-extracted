subroutine print_array10(a)
  implicit none
  integer, dimension(10) :: a
  integer :: i
  
  do i=1,10
    print *, a(i)
  end do
  
end subroutine print_array10

subroutine print_array2x5(a)
  implicit none
  integer, dimension(2,5) :: a
  integer :: i,n
  
  do i=1,5
    print *, a(1,i), a(2,i)
  end do

end subroutine print_array2x5
