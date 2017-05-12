#include <mesos/scheduler.hpp>
#include <mesos/executor.hpp>

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

#include <string>
#include <vector>

#include <XS/MesosUtils.hpp>
#include <CommandChannel.hpp>
#include <CommandDispatcher.hpp>
#include <InterruptDispatcher.hpp>
#include <PipeDispatcher.hpp>
#include <ProxyExecutor.hpp>
#include <ProxyScheduler.hpp>
#include <ExecutorDriver.hpp>
#include <SchedulerDriver.hpp>

MODULE = Mesos  PACKAGE = Mesos::Channel

static void
_xs_init(SV* self)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        mesos::perl::CommandChannel* channel = new mesos::perl::CommandChannel();
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) channel, 0);

static void
DEMOLISH(SV* self, ...)
    PPCODE:
        mesos::perl::CommandChannel* channel = (mesos::perl::CommandChannel*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (channel) delete channel;

void
mesos::perl::CommandChannel::send(mesos::perl::MesosCommand command);

mesos::perl::MesosCommand
mesos::perl::CommandChannel::recv();

size_t
mesos::perl::CommandChannel::size();


MODULE = Mesos  PACKAGE = Mesos::Dispatcher

static void
DEMOLISH(SV* self, ...)
    PPCODE:
        mesos::perl::CommandDispatcher* dispatcher = (mesos::perl::CommandDispatcher*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (dispatcher) delete dispatcher;

void
mesos::perl::CommandDispatcher::notify();


MODULE = Mesos  PACKAGE = Mesos::Dispatcher::Interrupt

static void
_xs_init(self, channel, interrupt_cb, interrupt_arg)
        SV*                          self
        mesos::perl::CommandChannel* channel
        void*                        interrupt_cb
        void*                        interrupt_arg
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        mesos::perl::InterruptDispatcher* dispatcher = new mesos::perl::InterruptDispatcher(channel, (interrupt_cb_t) interrupt_cb, interrupt_arg);
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) dispatcher, 0);


MODULE = Mesos  PACKAGE = Mesos::Dispatcher::Pipe

static void
_xs_init(SV* self, mesos::perl::CommandChannel* channel)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        mesos::perl::PipeDispatcher* dispatcher = new mesos::perl::PipeDispatcher(channel);
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) dispatcher, 0);

int
mesos::perl::PipeDispatcher::fd();

int
mesos::perl::PipeDispatcher::read_pipe();


MODULE = Mesos  PACKAGE = Mesos::ExecutorDriver

static void
_xs_init(SV* self, mesos::perl::CommandDispatcher* dispatcher)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        mesos::perl::ProxyExecutor* proxy = new mesos::perl::ProxyExecutor(dispatcher);
        mesos::perl::ExecutorDriver* driver = new mesos::perl::ExecutorDriver(proxy);
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) driver, 0);

Status
mesos::perl::ExecutorDriver::start();

Status
mesos::perl::ExecutorDriver::stop();

Status
mesos::perl::ExecutorDriver::abort();

Status
mesos::perl::ExecutorDriver::sendStatusUpdate(mesos::TaskStatus status);

Status
mesos::perl::ExecutorDriver::sendFrameworkMessage(std::string data);

Status
status(mesos::perl::ExecutorDriver* driver)
    CODE:
        RETVAL = driver->status_;
    OUTPUT:
        RETVAL


MODULE = Mesos PACKAGE = Mesos::SchedulerDriver

static void
_xs_init(self, dispatcher, framework, master, ...)
        SV*                             self
        mesos::perl::CommandDispatcher* dispatcher
        mesos::FrameworkInfo            framework
        std::string                     master
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        mesos::perl::SchedulerDriver* driver;
        mesos::perl::ProxyScheduler* proxy = new mesos::perl::ProxyScheduler(dispatcher);
        if (items > 4) {
            mesos::Credential credential( toMsg<mesos::Credential>(ST(4)) );
            driver = new mesos::perl::SchedulerDriver(framework, master, credential, proxy);
        } else {
            driver = new mesos::perl::SchedulerDriver(framework, master, proxy);
        }

        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) driver, 0);

static void
DEMOLISH(SV* self, ...)
    PPCODE:
        mesos::perl::SchedulerDriver* driver = (mesos::perl::SchedulerDriver*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (driver) delete driver;

Status
mesos::perl::SchedulerDriver::start();

Status
mesos::perl::SchedulerDriver::stop(bool failover = false);

Status
mesos::perl::SchedulerDriver::abort();

Status
mesos::perl::SchedulerDriver::requestResources(std::vector<mesos::Request> requests);

Status
mesos::perl::SchedulerDriver::launchTasks(std::vector<mesos::OfferID> offerIds, std::vector<mesos::TaskInfo> tasks, mesos::Filters filters = mesos::Filters());

Status
mesos::perl::SchedulerDriver::launchTask(mesos::OfferID offerId, std::vector<mesos::TaskInfo> tasks, mesos::Filters filters = mesos::Filters());

Status
mesos::perl::SchedulerDriver::killTask(mesos::TaskID taskId);

Status
mesos::perl::SchedulerDriver::declineOffer(mesos::OfferID offerId, mesos::Filters filters = mesos::Filters());

Status
mesos::perl::SchedulerDriver::reviveOffers();

Status
mesos::perl::SchedulerDriver::sendFrameworkMessage(mesos::ExecutorID executorId, mesos::SlaveID slaveId, std::string data);

Status
mesos::perl::SchedulerDriver::reconcileTasks(std::vector<mesos::TaskStatus> statuses);

Status
status(mesos::perl::SchedulerDriver* driver)
    CODE:
        RETVAL = driver->status_;
    OUTPUT:
        RETVAL

