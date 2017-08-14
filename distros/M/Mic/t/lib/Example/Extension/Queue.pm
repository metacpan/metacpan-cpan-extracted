package Example::Extension::Queue;

use Mic::Interface
    object => {
        push => {},
        pop  => {},
        head => {},
        tail => {},
        size => {},
    },
    class => { new => {} }
;

1;
