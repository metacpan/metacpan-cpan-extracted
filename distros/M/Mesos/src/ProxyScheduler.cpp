#include <ProxyScheduler.hpp>

namespace mesos {
namespace perl {

ProxyScheduler::ProxyScheduler(CommandDispatcher* dispatcher)
: dispatcher_(dispatcher)
{

}

void ProxyScheduler::registered(SchedulerDriver* driver,
                                const FrameworkID& frameworkId,
                                const MasterInfo& masterInfo)
{
    CommandArgs args;
    PUSH_MSG(args, frameworkId, "FrameworkID");
    PUSH_MSG(args, masterInfo, "MasterInfo");
    
    dispatcher_->send( MesosCommand("registered", args) );
}

void ProxyScheduler::reregistered(SchedulerDriver* driver,
                                  const MasterInfo& masterInfo)
{
    CommandArgs args;
    PUSH_MSG(args, masterInfo, "MasterInfo");
    
    dispatcher_->send( MesosCommand("reregistered", args) );
}

void ProxyScheduler::disconnected(SchedulerDriver* driver)
{
    CommandArgs args;
    dispatcher_->send( MesosCommand("disconnected", args) );
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

    dispatcher_->send( MesosCommand("resourceOffers", args) );
}

void ProxyScheduler::offerRescinded(SchedulerDriver* driver,
                                    const OfferID& offerId)
{
    CommandArgs args;
    PUSH_MSG(args, offerId, "OfferID");

    dispatcher_->send( MesosCommand("offerRescinded", args) );
}

void ProxyScheduler::statusUpdate(SchedulerDriver* driver,
                                  const TaskStatus& status)
{
    CommandArgs args;
    PUSH_MSG(args, status, "TaskStatus");

    dispatcher_->send( MesosCommand("statusUpdate", args) );
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

    dispatcher_->send( MesosCommand("frameworkMessage", args) );
}

void ProxyScheduler::slaveLost(SchedulerDriver* driver, const SlaveID& slaveId)
{
    CommandArgs args;
    PUSH_MSG(args, slaveId, "SlaveID");

    dispatcher_->send( MesosCommand("slaveLost", args) );
}

void ProxyScheduler::executorLost(SchedulerDriver* driver,
                                  const ExecutorID& executorId,
                                  const SlaveID& slaveId,
                                  int status)
{
    CommandArgs args;
    PUSH_MSG(args, executorId, "ExecutorID");
    PUSH_MSG(args, slaveId, "SlaveID");
    // older compilers might not have std::to_string overloaded for int
    // so cast to long long int
    args.push_back(CommandArg(std::to_string(static_cast<long long int> (status))));

    dispatcher_->send( MesosCommand("executorLost", args) );
}

void ProxyScheduler::error(SchedulerDriver* driver, const std::string& message)
{
    CommandArgs args;
    args.push_back(CommandArg(message));

    dispatcher_->send( MesosCommand("error", args) );
}

} // namespace perl {
} // namespace mesos {
