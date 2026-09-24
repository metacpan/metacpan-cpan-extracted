#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <limits.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/signalfd.h>

#define LES_UNATTACHED 0
#define LES_ACTIVE 1
#define LES_CANCELLED 2
#define LES_BATCH 64

typedef struct les_service les_service;
typedef struct les_signal les_signal;
typedef struct les_link les_link;

typedef struct les_descriptor {
    SV *callback;
} les_descriptor;

struct les_link {
    int number;
    les_signal *signal;
    les_link *previous;
    les_link *next;
};

struct les_signal {
    les_service *service;
    les_descriptor *descriptor;
    SV *descriptor_sv;
    SV *self_sv;
    SV *loop_sv;
    SV *data_sv;
    les_link *links;
    size_t link_count;
    les_signal *service_previous;
    les_signal *service_next;
    int state;
    int in_callback;
    int cleanup_pending;
};

struct les_service {
    int fd;
    pid_t owner_pid;
    pthread_t owner_thread;
    sigset_t mask;
    les_link *heads[NSIG];
    les_link *tails[NSIG];
    unsigned int references[NSIG];
    unsigned char restore_unblock[NSIG];
    les_signal *active_head;
    les_signal *active_tail;
    unsigned long long active_signals;
    unsigned long long active_subscriptions;
    unsigned long long read_calls;
    unsigned long long records;
    unsigned long long dispatches;
    unsigned long long callbacks;
};

static les_service *les_owners[NSIG];

static les_descriptor *
les_descriptor_from_sv(SV *object)
{
    if (!SvROK(object) || !sv_derived_from(object,
            "Linux::Event::Kernel::Signal::_Descriptor"))
        croak("not a Signal descriptor object");
    return INT2PTR(les_descriptor *, SvIV(SvRV(object)));
}

static les_service *
les_service_from_sv(SV *object)
{
    if (!SvROK(object) || !sv_derived_from(object,
            "Linux::Event::Kernel::Signal::_Service"))
        croak("not a Signal service object");
    return INT2PTR(les_service *, SvIV(SvRV(object)));
}

static les_signal *
les_signal_from_sv(SV *object)
{
    if (!SvROK(object) || !sv_derived_from(object, "Linux::Event::Kernel::Signal"))
        croak("not a Signal object");
    return INT2PTR(les_signal *, SvIV(SvRV(object)));
}

static void
les_service_verify(les_service *service, const char *operation)
{
    if (!service)
        croak("%s(): Signal service is closed", operation);
    if (service->owner_pid != getpid())
        croak("%s(): Signal service cannot be used after fork", operation);
    if (!pthread_equal(service->owner_thread, pthread_self()))
        croak("%s(): Signal service must be used from its owning thread",
            operation);
}

static int
les_signal_has_number(const les_signal *signal, int number)
{
    size_t index;
    for (index = 0; index < signal->link_count; index++)
        if (signal->links[index].number == number)
            return 1;
    return 0;
}

static void
les_signal_release_refs(les_signal *signal)
{
    SV *descriptor_sv;
    SV *data_sv;
    SV *loop_sv;
    SV *self_sv;
    if (!signal) return;
    descriptor_sv = signal->descriptor_sv;
    data_sv = signal->data_sv;
    loop_sv = signal->loop_sv;
    self_sv = signal->self_sv;
    signal->descriptor = NULL;
    signal->descriptor_sv = NULL;
    signal->data_sv = NULL;
    signal->loop_sv = NULL;
    signal->self_sv = NULL;
    signal->service = NULL;
    signal->cleanup_pending = 0;
    if (descriptor_sv) SvREFCNT_dec(descriptor_sv);
    if (data_sv) SvREFCNT_dec(data_sv);
    if (loop_sv) SvREFCNT_dec(loop_sv);
    if (self_sv) SvREFCNT_dec(self_sv);
}

static void
les_signal_finish_terminal(les_signal *signal)
{
    if (signal->in_callback) {
        signal->cleanup_pending = 1;
        return;
    }
    les_signal_release_refs(signal);
}

static void
les_service_list_add(les_service *service, les_signal *signal)
{
    signal->service_previous = service->active_tail;
    signal->service_next = NULL;
    if (service->active_tail)
        service->active_tail->service_next = signal;
    else
        service->active_head = signal;
    service->active_tail = signal;
    service->active_signals++;
}

static void
les_service_list_remove(les_service *service, les_signal *signal)
{
    if (signal->service_previous)
        signal->service_previous->service_next = signal->service_next;
    else
        service->active_head = signal->service_next;
    if (signal->service_next)
        signal->service_next->service_previous = signal->service_previous;
    else
        service->active_tail = signal->service_previous;
    signal->service_previous = signal->service_next = NULL;
    if (service->active_signals)
        service->active_signals--;
}

static void
les_link_add(les_service *service, les_link *link)
{
    int number = link->number;
    link->previous = service->tails[number];
    link->next = NULL;
    if (service->tails[number])
        service->tails[number]->next = link;
    else
        service->heads[number] = link;
    service->tails[number] = link;
    service->references[number]++;
    service->active_subscriptions++;
}

static void
les_link_remove(les_service *service, les_link *link)
{
    int number = link->number;
    if (link->previous)
        link->previous->next = link->next;
    else
        service->heads[number] = link->next;
    if (link->next)
        link->next->previous = link->previous;
    else
        service->tails[number] = link->previous;
    link->previous = link->next = NULL;
    if (service->references[number])
        service->references[number]--;
    if (service->active_subscriptions)
        service->active_subscriptions--;
}

static void
les_service_set_fd_mask(les_service *service, const sigset_t *mask,
    const char *operation)
{
    if (signalfd(service->fd, mask, SFD_NONBLOCK | SFD_CLOEXEC) < 0)
        croak("%s(): signalfd mask update failed: %s",
            operation, strerror(errno));
}

static void
les_signal_activate(SV *signal_obj, les_signal *signal, SV *loop_obj,
    les_service *service)
{
    sigset_t additions;
    sigset_t old_mask;
    sigset_t rollback;
    size_t index;
    int error;

    if (!signal || signal->state != LES_UNATTACHED || signal->service)
        croak("add(): Signal is not unattached");
    les_service_verify(service, "add");
    sigemptyset(&additions);

    for (index = 0; index < signal->link_count; index++) {
        int number = signal->links[index].number;
        if (service->references[number] == 0) {
            if (les_owners[number] && les_owners[number] != service)
                croak("add(): signal %d is already owned by another Loop",
                    number);
            sigaddset(&additions, number);
        }
    }

    error = pthread_sigmask(SIG_BLOCK, &additions, &old_mask);
    if (error)
        croak("add(): pthread_sigmask failed: %s", strerror(error));

    for (index = 0; index < signal->link_count; index++) {
        int number = signal->links[index].number;
        if (service->references[number] == 0) {
            les_owners[number] = service;
            service->restore_unblock[number]
                = sigismember(&old_mask, number) == 1 ? 0 : 1;
            sigaddset(&service->mask, number);
        }
    }

    if (signalfd(service->fd, &service->mask,
            SFD_NONBLOCK | SFD_CLOEXEC) < 0) {
        int update_error = errno;
        sigemptyset(&rollback);
        for (index = 0; index < signal->link_count; index++) {
            int number = signal->links[index].number;
            if (service->references[number] != 0)
                continue;
            les_owners[number] = NULL;
            sigdelset(&service->mask, number);
            if (service->restore_unblock[number])
                sigaddset(&rollback, number);
            service->restore_unblock[number] = 0;
        }
        pthread_sigmask(SIG_UNBLOCK, &rollback, NULL);
        croak("add(): signalfd mask update failed: %s",
            strerror(update_error));
    }
    signal->service = service;
    signal->self_sv = newSVsv(signal_obj);
    signal->loop_sv = newSVsv(loop_obj);
    if (SvROK(signal->loop_sv)) sv_rvweaken(signal->loop_sv);
    signal->state = LES_ACTIVE;
    les_service_list_add(service, signal);
    for (index = 0; index < signal->link_count; index++)
        les_link_add(service, &signal->links[index]);
}

static void
les_signal_cancel_native(les_signal *signal)
{
    les_service *service;
    sigset_t next_mask;
    sigset_t removals;
    size_t index;
    int error;

    if (!signal || signal->state == LES_CANCELLED)
        return;
    if (signal->state == LES_UNATTACHED) {
        signal->state = LES_CANCELLED;
        les_signal_finish_terminal(signal);
        return;
    }

    service = signal->service;
    les_service_verify(service, "cancel");
    next_mask = service->mask;
    sigemptyset(&removals);
    for (index = 0; index < signal->link_count; index++) {
        int number = signal->links[index].number;
        if (service->references[number] == 1)
            sigdelset(&next_mask, number);
    }
    les_service_set_fd_mask(service, &next_mask, "cancel");

    for (index = 0; index < signal->link_count; index++) {
        int number = signal->links[index].number;
        les_link_remove(service, &signal->links[index]);
        if (service->references[number] == 0) {
            les_owners[number] = NULL;
            if (service->restore_unblock[number])
                sigaddset(&removals, number);
            service->restore_unblock[number] = 0;
        }
    }
    service->mask = next_mask;
    les_service_list_remove(service, signal);
    signal->state = LES_CANCELLED;
    error = pthread_sigmask(SIG_UNBLOCK, &removals, NULL);
    les_signal_finish_terminal(signal);
    if (error)
        croak("cancel(): pthread_sigmask failed: %s", strerror(error));
}

static SV *
les_signal_call(pTHX_ les_service *service, les_signal *signal,
    int number, unsigned long long count)
{
    SV *error = NULL;
    if (!signal->descriptor || !signal->descriptor->callback)
        croak("Signal callback descriptor is unavailable");
    signal->in_callback = 1;
    ENTER;
    SAVETMPS;
    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 3);
        PUSHs(signal->self_sv);
        PUSHs(sv_2mortal(newSViv(number)));
        PUSHs(sv_2mortal(newSVuv((UV)count)));
        PUTBACK;
        call_sv(signal->descriptor->callback, G_DISCARD | G_VOID | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            error = newSVsv(ERRSV);
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        PUTBACK;
    }
    FREETMPS;
    LEAVE;
    service->callbacks++;
    signal->in_callback = 0;
    if (signal->cleanup_pending)
        les_signal_release_refs(signal);
    return error;
}

static void
les_service_dispatch(pTHX_ les_service *service)
{
    struct signalfd_siginfo records[LES_BATCH];
    unsigned long long counts[NSIG];
    ssize_t bytes;
    int number;
    SV *first_error = NULL;

    les_service_verify(service, "dispatch");
    memset(counts, 0, sizeof(counts));
    service->dispatches++;
    for (;;) {
        do {
            bytes = read(service->fd, records, sizeof(records));
        } while (bytes < 0 && errno == EINTR);
        service->read_calls++;
        if (bytes < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK)
                break;
            croak("read signalfd failed: %s", strerror(errno));
        }
        if (bytes == 0)
            croak("signalfd returned end of file");
        if ((size_t)bytes % sizeof(struct signalfd_siginfo) != 0)
            croak("signalfd returned a partial record");
        {
            size_t index;
            size_t count = (size_t)bytes / sizeof(struct signalfd_siginfo);
            service->records += (unsigned long long)count;
            for (index = 0; index < count; index++) {
                unsigned int signo = records[index].ssi_signo;
                if (signo > 0 && signo < NSIG
                    && counts[signo] != ULLONG_MAX)
                    counts[signo]++;
            }
        }
    }

    for (number = 1; number < NSIG; number++) {
        AV *snapshot;
        les_link *link;
        SSize_t index, last;
        if (!counts[number] || !service->heads[number])
            continue;
        snapshot = newAV();
        for (link = service->heads[number]; link; link = link->next)
            if (link->signal->self_sv)
                av_push(snapshot, newSVsv(link->signal->self_sv));
        last = av_len(snapshot);
        for (index = 0; index <= last; index++) {
            SV **item = av_fetch(snapshot, index, 0);
            les_signal *signal;
            SV *error;
            if (!item) continue;
            signal = les_signal_from_sv(*item);
            if (!signal || signal->state != LES_ACTIVE
                || signal->service != service
                || !les_signal_has_number(signal, number))
                continue;
            error = les_signal_call(aTHX_ service, signal,
                number, counts[number]);
            if (error) {
                if (!first_error)
                    first_error = error;
                else
                    SvREFCNT_dec(error);
            }
        }
        SvREFCNT_dec((SV *)snapshot);
    }
    if (first_error)
        croak_sv(first_error);
}

static int
les_service_fork_child_drop(les_service *service)
{
    les_signal *signal;
    sigset_t removals;
    int number;
    int error;
    if (!service) return 0;
    if (service->owner_pid == getpid())
        croak("_fork_child_drop(): Signal service is not inherited");

    sigemptyset(&removals);
    for (number = 1; number < NSIG; number++) {
        if (les_owners[number] == service) {
            les_owners[number] = NULL;
            if (service->restore_unblock[number])
                sigaddset(&removals, number);
        }
    }
    error = pthread_sigmask(SIG_UNBLOCK, &removals, NULL);

    while ((signal = service->active_head)) {
        les_signal *next = signal->service_next;
        signal->state = LES_CANCELLED;
        signal->service_previous = signal->service_next = NULL;
        signal->service = NULL;
        signal->cleanup_pending = 0;
        les_signal_release_refs(signal);
        service->active_head = next;
        if (next) next->service_previous = NULL;
    }
    close(service->fd);
    free(service);
    return error;
}

static void
les_service_destroy(les_service *service)
{
    les_signal *signal;
    sigset_t empty_mask;
    sigset_t removals;
    int same_owner;
    int number;
    if (!service) return;
    same_owner = service->owner_pid == getpid()
        && pthread_equal(service->owner_thread, pthread_self());
    sigemptyset(&empty_mask);
    sigemptyset(&removals);
    if (same_owner)
        signalfd(service->fd, &empty_mask, SFD_NONBLOCK | SFD_CLOEXEC);
    for (number = 1; number < NSIG; number++) {
        if (les_owners[number] == service) {
            les_owners[number] = NULL;
            if (same_owner && service->restore_unblock[number])
                sigaddset(&removals, number);
        }
    }
    if (same_owner)
        pthread_sigmask(SIG_UNBLOCK, &removals, NULL);
    while ((signal = service->active_head)) {
        les_signal *next = signal->service_next;
        signal->state = LES_CANCELLED;
        signal->service_previous = signal->service_next = NULL;
        signal->service = NULL;
        signal->cleanup_pending = 0;
        les_signal_release_refs(signal);
        service->active_head = next;
        if (next) next->service_previous = NULL;
    }
    close(service->fd);
    free(service);
}

MODULE = Linux::Event::Kernel::Signal    PACKAGE = Linux::Event::Kernel::Signal::_Descriptor
PROTOTYPES: DISABLE

SV *
new(CLASS, callback)
    const char *CLASS
    SV *callback
  PREINIT:
    les_descriptor *descriptor;
  CODE:
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("Signal on_signal must resolve to a coderef");
    descriptor = (les_descriptor *)calloc(1, sizeof(*descriptor));
    if (!descriptor) croak("cannot allocate Signal descriptor");
    descriptor->callback = newSVsv(callback);
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)descriptor);
  OUTPUT:
    RETVAL

void
DESTROY(descriptor_obj)
    SV *descriptor_obj
  PREINIT:
    les_descriptor *descriptor;
  CODE:
    descriptor = les_descriptor_from_sv(descriptor_obj);
    if (descriptor) {
        if (descriptor->callback) SvREFCNT_dec(descriptor->callback);
        free(descriptor);
        sv_setiv(SvRV(descriptor_obj), 0);
    }

MODULE = Linux::Event::Kernel::Signal    PACKAGE = Linux::Event::Kernel::Signal::_Service
PROTOTYPES: DISABLE

SV *
new(CLASS)
    const char *CLASS
  PREINIT:
    les_service *service;
  CODE:
    service = (les_service *)calloc(1, sizeof(*service));
    if (!service) croak("cannot allocate Signal service");
    sigemptyset(&service->mask);
    service->fd = signalfd(-1, &service->mask, SFD_NONBLOCK | SFD_CLOEXEC);
    if (service->fd < 0) {
        int error = errno;
        free(service);
        croak("signalfd creation failed: %s", strerror(error));
    }
    service->owner_pid = getpid();
    service->owner_thread = pthread_self();
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)service);
  OUTPUT:
    RETVAL

void
_fork_child_drop(service_obj)
    SV *service_obj
  PREINIT:
    les_service *service;
    int error;
  CODE:
    service = les_service_from_sv(service_obj);
    if (service) {
        sv_setiv(SvRV(service_obj), 0);
        error = les_service_fork_child_drop(service);
        if (error)
            croak("_fork_child_drop(): pthread_sigmask failed: %s", strerror(error));
    }

void
DESTROY(service_obj)
    SV *service_obj
  PREINIT:
    les_service *service;
  CODE:
    service = les_service_from_sv(service_obj);
    if (service) {
        sv_setiv(SvRV(service_obj), 0);
        les_service_destroy(service);
    }

int
fd(service_obj)
    SV *service_obj
  PREINIT:
    les_service *service;
  CODE:
    service = les_service_from_sv(service_obj);
    les_service_verify(service, "fd");
    RETVAL = service->fd;
  OUTPUT:
    RETVAL

SV *
objects(service_obj)
    SV *service_obj
  PREINIT:
    les_service *service;
    les_signal *signal;
    AV *objects;
  CODE:
    service = les_service_from_sv(service_obj);
    les_service_verify(service, "objects");
    objects = newAV();
    for (signal = service->active_head; signal; signal = signal->service_next)
        if (signal->self_sv) av_push(objects, newSVsv(signal->self_sv));
    RETVAL = newRV_noinc((SV *)objects);
  OUTPUT:
    RETVAL

void
dispatch(service_obj)
    SV *service_obj
  PREINIT:
    les_service *service;
  CODE:
    service = les_service_from_sv(service_obj);
    les_service_dispatch(aTHX_ service);

SV *
stats(service_obj)
    SV *service_obj
  PREINIT:
    les_service *service;
    HV *result;
  CODE:
    service = les_service_from_sv(service_obj);
    les_service_verify(service, "stats");
    result = newHV();
    hv_stores(result, "active_signals", newSVuv(service->active_signals));
    hv_stores(result, "active_subscriptions", newSVuv(service->active_subscriptions));
    hv_stores(result, "read_calls", newSVuv(service->read_calls));
    hv_stores(result, "records", newSVuv(service->records));
    hv_stores(result, "dispatches", newSVuv(service->dispatches));
    hv_stores(result, "callbacks", newSVuv(service->callbacks));
    RETVAL = newRV_noinc((SV *)result);
  OUTPUT:
    RETVAL

MODULE = Linux::Event::Kernel::Signal    PACKAGE = Linux::Event::Kernel::Signal
PROTOTYPES: DISABLE

SV *
_new_native(CLASS, descriptor_obj, numbers, data)
    const char *CLASS
    SV *descriptor_obj
    SV *numbers
    SV *data
  PREINIT:
    les_descriptor *descriptor;
    les_signal *signal;
    AV *array;
    SSize_t last;
    SSize_t index;
  CODE:
    descriptor = les_descriptor_from_sv(descriptor_obj);
    if (!descriptor || !descriptor->callback)
        croak("Signal descriptor is closed");
    if (!SvROK(numbers) || SvTYPE(SvRV(numbers)) != SVt_PVAV)
        croak("Signal numbers must be an array reference");
    array = (AV *)SvRV(numbers);
    last = av_len(array);
    if (last < 0)
        croak("Signal numbers cannot be empty");
    signal = (les_signal *)calloc(1, sizeof(*signal));
    if (!signal) croak("cannot allocate Signal object");
    signal->link_count = (size_t)last + 1;
    signal->links = (les_link *)calloc(signal->link_count, sizeof(les_link));
    if (!signal->links) {
        free(signal);
        croak("cannot allocate Signal subscriptions");
    }
    for (index = 0; index <= last; index++) {
        SV **item = av_fetch(array, index, 0);
        IV number = item ? SvIV(*item) : 0;
        if (number <= 0 || number >= NSIG
            || number == SIGKILL || number == SIGSTOP) {
            free(signal->links);
            free(signal);
            croak("signal number %" IVdf " cannot be used with signalfd", number);
        }
        signal->links[index].number = (int)number;
        signal->links[index].signal = signal;
    }
    signal->state = LES_UNATTACHED;
    signal->descriptor = descriptor;
    signal->descriptor_sv = newSVsv(descriptor_obj);
    signal->data_sv = SvOK(data) ? newSVsv(data) : NULL;
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)signal);
  OUTPUT:
    RETVAL

void
DESTROY(signal_obj)
    SV *signal_obj
  PREINIT:
    les_signal *signal;
  CODE:
    signal = les_signal_from_sv(signal_obj);
    if (signal) {
        if (signal->state != LES_CANCELLED)
            les_signal_cancel_native(signal);
        if (signal->descriptor_sv || signal->data_sv || signal->loop_sv)
            les_signal_release_refs(signal);
        free(signal->links);
        free(signal);
        sv_setiv(SvRV(signal_obj), 0);
    }

SV *
_attach_native(signal_obj, loop_obj, service_obj)
    SV *signal_obj
    SV *loop_obj
    SV *service_obj
  PREINIT:
    les_signal *signal;
    les_service *service;
  CODE:
    signal = les_signal_from_sv(signal_obj);
    service = les_service_from_sv(service_obj);
    les_signal_activate(signal_obj, signal, loop_obj, service);
    RETVAL = newSVsv(signal_obj);
  OUTPUT:
    RETVAL

SV *
cancel(signal_obj)
    SV *signal_obj
  CODE:
    les_signal_cancel_native(les_signal_from_sv(signal_obj));
    RETVAL = newSVsv(signal_obj);
  OUTPUT:
    RETVAL

SV *
signals(signal_obj)
    SV *signal_obj
  PREINIT:
    les_signal *signal;
    AV *numbers;
    size_t index;
  CODE:
    signal = les_signal_from_sv(signal_obj);
    numbers = newAV();
    for (index = 0; index < signal->link_count; index++)
        av_push(numbers, newSViv(signal->links[index].number));
    RETVAL = newRV_noinc((SV *)numbers);
  OUTPUT:
    RETVAL

SV *
data(signal_obj, ...)
    SV *signal_obj
  PREINIT:
    les_signal *signal;
  CODE:
    signal = les_signal_from_sv(signal_obj);
    if (items > 1) {
        if (signal->state == LES_CANCELLED)
            croak("data(): terminal Signal cannot retain data");
        if (signal->data_sv) SvREFCNT_dec(signal->data_sv);
        signal->data_sv = SvOK(ST(1)) ? newSVsv(ST(1)) : NULL;
    }
    RETVAL = signal->data_sv ? newSVsv(signal->data_sv) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
loop(signal_obj)
    SV *signal_obj
  PREINIT:
    les_signal *signal;
  CODE:
    signal = les_signal_from_sv(signal_obj);
    RETVAL = signal->loop_sv ? newSVsv(signal->loop_sv) : &PL_sv_undef;
  OUTPUT:
    RETVAL

const char *
state(signal_obj)
    SV *signal_obj
  PREINIT:
    les_signal *signal;
  CODE:
    signal = les_signal_from_sv(signal_obj);
    RETVAL = signal->state == LES_UNATTACHED ? "unattached"
        : signal->state == LES_ACTIVE ? "active" : "cancelled";
  OUTPUT:
    RETVAL

int
is_active(signal_obj)
    SV *signal_obj
  CODE:
    RETVAL = les_signal_from_sv(signal_obj)->state == LES_ACTIVE;
  OUTPUT:
    RETVAL

int
is_terminal(signal_obj)
    SV *signal_obj
  CODE:
    RETVAL = les_signal_from_sv(signal_obj)->state == LES_CANCELLED;
  OUTPUT:
    RETVAL
