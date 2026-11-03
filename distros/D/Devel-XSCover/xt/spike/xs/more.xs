MODULE = Spike  PACKAGE = Spike::More

int
triple(x)
    int x
  CODE:
    RETVAL = x * 3;
  OUTPUT:
    RETVAL

int
child_only(x)
    int x
  CODE:
    RETVAL = x + 100;
  OUTPUT:
    RETVAL

int
exit_only(x)
    int x
  CODE:
    RETVAL = x + 200;
  OUTPUT:
    RETVAL

int
never(x)
    int x
  CODE:
    RETVAL = -x;
  OUTPUT:
    RETVAL
