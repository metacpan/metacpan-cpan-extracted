recursive function fib(x) result(ret)
  integer, intent(in) :: x
  integer :: ret
  
  if (x == 1 .or. x == 2) then
    ret = 1
  else
    ret = fib(x-1) + fib(x-2)
  end if

end function fib
