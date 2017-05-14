#ifndef SCHEDULER_DRIVER_HPP_
#define SCHEDULER_DRIVER_HPP_

#include <mesos/scheduler.hpp>
#include <ProxyScheduler.hpp>
#include <MesosChannel.hpp>
#include <memory>

using namespace mesos;

namespace mesos {
namespace perl {

class SchedulerDriver
{
public:
    Status status_;
    ProxyScheduler* proxyScheduler_;

    SchedulerDriver(const FrameworkInfo& framework,
                    const std::string& master,
                    ProxyScheduler* proxyScheduler = (new ProxyScheduler));
    SchedulerDriver(const FrameworkInfo& framework,
                    const std::string& master,
                    const Credential& credential,
                    ProxyScheduler* proxyScheduler = (new ProxyScheduler));
    virtual ~SchedulerDriver();

    virtual Status start();
    virtual Status stop(bool failover = false);
    virtual Status abort();
    virtual Status join();
    virtual Status run();
    virtual Status requestResources(const std::vector<Request>& requests);
    virtual Status launchTasks(const std::vector<OfferID>& offerIds,
                               const std::vector<TaskInfo>& tasks,
                               const Filters& filters = Filters());
    virtual Status launchTask(const OfferID& offerId,
                              const std::vector<TaskInfo>& tasks,
                              const Filters& filters = Filters());
    virtual Status killTask(const TaskID& taskId);
    virtual Status declineOffer(const OfferID& offerId,
                                const Filters& filters = Filters());
    virtual Status reviveOffers();
    virtual Status sendFrameworkMessage(const ExecutorID& executorId,
                                        const SlaveID& slaveId,
                                        const std::string& data);
    virtual Status reconcileTasks(const std::vector<TaskStatus>& statuses);

private:
    mesos::MesosSchedulerDriver* driver_;
};

} // namespace perl {
} // namespace mesos {

#endif // SCHEDULER_DRIVER_HPP_
