#include <SchedulerDriver.hpp>

namespace mesos {
namespace perl {

SchedulerDriver::SchedulerDriver(const FrameworkInfo& framework,
                                 const std::string& master,
                                 ProxyScheduler* proxyScheduler)
: proxyScheduler_(proxyScheduler),
  driver_(new MesosSchedulerDriver(proxyScheduler_, framework, master))
{

}

SchedulerDriver::SchedulerDriver(const FrameworkInfo& framework,
                                 const std::string& master,
                                 const Credential& credential,
                                 ProxyScheduler* proxyScheduler)
: proxyScheduler_(proxyScheduler),
  driver_(new MesosSchedulerDriver(proxyScheduler_, framework, master))
{

}

SchedulerDriver::~SchedulerDriver()
{
    delete driver_;
    delete proxyScheduler_;
}

Status SchedulerDriver::start()
{
    return status_ = driver_->start();
}

Status SchedulerDriver::stop(bool failover)
{
    return status_ = driver_->stop(failover);
}

Status SchedulerDriver::abort()
{
    return status_ = driver_->abort();
}

Status SchedulerDriver::join()
{
    return status_ = driver_->join();
}

Status SchedulerDriver::run()
{
    return status_ = driver_->run();
}

Status SchedulerDriver::requestResources(const std::vector<Request>& requests)
{
    return status_ = driver_->requestResources(requests);
}

Status SchedulerDriver::launchTasks(const std::vector<OfferID>& offerIds,
                           const std::vector<TaskInfo>& tasks,
                           const Filters& filters)
{
    return status_ = driver_->launchTasks(offerIds, tasks, filters);
}

Status SchedulerDriver::launchTask(const OfferID& offerId,
                           const std::vector<TaskInfo>& tasks,
                           const Filters& filters)
{
    return status_ = driver_->launchTasks(offerId, tasks, filters);
}

Status SchedulerDriver::killTask(const TaskID& taskId)
{
    return status_ = driver_->killTask(taskId);
}

Status SchedulerDriver::declineOffer(const OfferID& offerId,
                            const Filters& filters)
{
    return status_ = driver_->declineOffer(offerId, filters);
}

Status SchedulerDriver::reviveOffers()
{
    return status_ = driver_->reviveOffers();
}

Status SchedulerDriver::sendFrameworkMessage(const ExecutorID& executorId,
                                    const SlaveID& slaveId,
                                    const std::string& data)
{
    return status_ = driver_->sendFrameworkMessage(executorId, slaveId, data);
}

Status SchedulerDriver::reconcileTasks(const std::vector<TaskStatus>& statuses)
{
    return status_ = driver_->reconcileTasks(statuses);
}

} // namespace perl {
} // namespace mesos {
