MODULE = Hyperman		PACKAGE = Hyperman::Event::Kqueue

int
available(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hm_backend_kqueue_available();
    OUTPUT:
        RETVAL

MODULE = Hyperman		PACKAGE = Hyperman::Event::Epoll

int
available(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hm_backend_epoll_available();
    OUTPUT:
        RETVAL

MODULE = Hyperman		PACKAGE = Hyperman::Event::Poll

int
available(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hm_backend_poll_available();
    OUTPUT:
        RETVAL

MODULE = Hyperman		PACKAGE = Hyperman::Event::IOUring

int
available(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hm_backend_iouring_available();
    OUTPUT:
        RETVAL
