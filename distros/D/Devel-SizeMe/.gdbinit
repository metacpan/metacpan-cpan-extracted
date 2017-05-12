# http://sourceware.org/gdb/current/onlinedocs/gdb/

set breakpoint pending on
b __asan_report_error
set args -Mblib -MDevel::SizeMe=total_size -e 'total_size(\%::)'
set args -Mblib -MDevel::SizeMe=:all -e '$x=[]; push @$x, $x; sub cv {my $a=shift; cv($a-1) if $a; } cv(0); total_size(\%::)'
set args -Mblib -MDevel::SizeMe=:all -e '$Devel::SizeMe::trace=9; $x=[]; push @$x, $x; sub cv {my $a=shift; cv($a-1) if $a; } cv(0); $x=\&cv; $x=[map { {foo=>1} } 0..2]; total_size($x)'
set args -Mblib -MDevel::SizeMe=:all -e '$Devel::Size::trace=0; sub cv {my $c=[1]; return sub { $c } } 0 ? total_size(\%blib::) : perl_size()'
set args -Mblib -MDevel::SizeMe=:all -e '$Devel::Size::trace=1; sub cv {my $c=[1]; return sub { $c } } perl_size(); exit; total_size(\%blib::)'
set args -Mblib -MDevel::SizeMe=:all -e '$Devel::Size::trace=1; heap_size()'
set args -Mblib -MDevel::SizeMe=:all -e '$Devel::Size::trace=6; perl_size()'

define stack
info stack
end
document stack
Print call stack
end
 
define frame
info frame
info args
info locals
end
document frame
Print stack frame
end

