#ifndef PROXYSCHEDULER_HPP_
#define PROXYSCHEDULER_HPP_
#include <string>
#include <vector>
#include <memory>
#include <mesos/scheduler.hpp>
#include <PipeChannel.hpp>

using namespace mesos;

namespace mesos {
namespace perl {

class ProxyScheduler : public Scheduler
{
public:
    MesosChannel* channel_;

    ProxyScheduler(MesosChannel* channel = (new PipeChannel)): channel_(channel) {};
    virtual ~ProxyScheduler(){};

    virtual void registered(SchedulerDriver* driver,
                            const FrameworkID& frameworkId,
                            const MasterInfo& masterInfo);
    virtual void reregistered(SchedulerDriver* driver,
                              const MasterInfo& masterInfo);
    virtual void disconnected(SchedulerDriver* driver);
    virtual void resourceOffers(SchedulerDriver* driver,
                                const std::vector<Offer>& offers);
    virtual void offerRescinded(SchedulerDriver* driver, const OfferID& offerId);
    virtual void statusUpdate(SchedulerDriver* driver, const TaskStatus& status);
    virtual void frameworkMessage(SchedulerDriver* driver,
                                  const ExecutorID& executorId,
                                  const SlaveID& slaveId,
                                  const std::string& data);
    virtual void slaveLost(SchedulerDriver* driver, const SlaveID& slaveId);
    virtual void executorLost(SchedulerDriver* driver,
                              const ExecutorID& executorId,
                              const SlaveID& slaveId,
                              int status);
    virtual void error(SchedulerDriver* driver, const std::string& message);
};

} // namespace perl {
} // namespace mesos {

#endif // PROXYSCHEDULER_HPP_
