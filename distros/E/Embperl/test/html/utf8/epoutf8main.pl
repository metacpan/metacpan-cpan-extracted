
use utf8 ;
use Embperl::Object ;
use FindBin ;
use Data::Dumper ;

my $a = 'Это русский текст в переменной'; 
my $len = length($a) ;

print "a:<$a>\nlen: $len\n" ;

my $tmp = {
    inputfile        => $FindBin::Bin . '/epoutf8inc.htm',
    object_base      => 'epoutf8base.htm',
    object_stopdir   => $FindBin::Bin,
    output           => \$out,
    appname          => 'Test1',
    param            => [ 'параметр', 'param2' ],
    input_charset    => 'utf8',
    debug            => 0x7fffffff,
    } ;

print "Exeecute ", Dumper ($tmp) ;
    
Embperl::Object::Execute($tmp);
    
print "After Embperl: utf8: ", utf8::is_utf8($out)?'yes':'no' ;

print "Output:\n" ;
print $out, "\n" ;
print "----------------------------\n" ;



