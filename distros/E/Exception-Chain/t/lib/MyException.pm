package
    MyException;
use Exception::Chain;
sub throw {
    Exception::Chain->throw(
        message => 'others package',
    );
}
1;
