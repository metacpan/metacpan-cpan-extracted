#include <ProxyScheduler.hpp>

namespace mesos {
namespace perl {

void ProxyScheduler::registered(SchedulerDriver* driver,
                const FrameworkID& frameworkId,
                const MasterInfo& masterInfo)
{
    CommandArgs args;
    PUSH_MSG(args, frameworkId, "FrameworkID");
    PUSH_MSG(args, masterInfo, "MasterInfo");
    
    channel_->send( MesosCommand("registered", args) );
}

void ProxyScheduler::reregistered(SchedulerDriver* driver,
                  const MasterInfo& masterInfo)
{
    CommandArgs args;
    PUSH_MSG(args, masterInfo, "MasterInfo");
    
    channel_->send( MesosCommand("reregistered", args) );
}

void ProxyScheduler::disconnected(SchedulerDriver* driver)
{
    CommandArgs args;
    channel_->send( MesosCommand("disconnected", args) );
}

void ProxyScheduler::resourceOffers(SchedulerDriver* driver,
                    const std::vector<Offer>& offers)
{
    CommandArgs args;
    std::vector<std::string> strings;
    for (std::vector<Offer>::const_iterator it = offers.begin(); it != offers.end(); ++it) {
        strings.push_back(it->SerializeAsString());
    }
    args.push_back( CommandArg(strings, "Offer") );

    channel_->send( MesosCommand("resourceOffers", args) );
}

void ProxyScheduler::offerRescinded(SchedulerDriver* driver, const OfferID& offerId)
{
    CommandArgs args;
    PUSH_MSG(args, offerId, "OfferID");

    channel_->send( MesosCommand("offerRescinded", args) );
}

void ProxyScheduler::statusUpdate(SchedulerDriver* driver, const TaskStatus& status)
{
    CommandArgs args;
    PUSH_MSG(args, status, "TaskStatus");

    channel_->send( MesosCommand("statusUpdate", args) );
}

void ProxyScheduler::frameworkMessage(SchedulerDriver* driver,
                      const ExecutorID& executorId,
                      const SlaveID& slaveId,
                      const std::string& data)
{
    CommandArgs args;
    PUSH_MSG(args, executorId, "ExecutorID");
    PUSH_MSG(args, slaveId, "SlaveID");
    args.push_back(CommandArg(data));

    channel_->send( MesosCommand("frameworkMessage", args) );
}

void ProxyScheduler::slaveLost(SchedulerDriver* driver, const SlaveID& slaveId)
{
    CommandArgs args;
    PUSH_MSG(args, slaveId, "SlaveID");

    channel_->send( MesosCommand("slaveLost", args) );
}

void ProxyScheduler::executorLost(SchedulerDriver* driver,
                  const ExecutorID& executorId,
                  const SlaveID& slaveId,
                  int status)
{
    CommandArgs args;
    PUSH_MSG(args, executorId, "ExecutorID");
    PUSH_MSG(args, slaveId, "SlaveID");
    args.push_back(CommandArg(std::to_string(status)));

    channel_->send( MesosCommand("executorLost", args) );
}

void ProxyScheduler::error(SchedulerDriver* driver, const std::string& message)
{
    CommandArgs args;
    args.push_back(CommandArg(message));

    channel_->send( MesosCommand("error", args) );
}

} // namespace perl {
} // namespace mesos {
