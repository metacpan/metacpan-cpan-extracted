#include <ProxyExecutor.hpp>

namespace mesos {
namespace perl {

ProxyExecutor::ProxyExecutor(CommandDispatcher* dispatcher)
: dispatcher_(dispatcher)
{

}

void ProxyExecutor::registered(ExecutorDriver* driver,
                               const ExecutorInfo& executorInfo,
                               const FrameworkInfo& frameworkInfo,
                               const SlaveInfo& slaveInfo)
{
    CommandArgs args;
    PUSH_MSG(args, executorInfo, "ExecutorInfo");
    PUSH_MSG(args, frameworkInfo, "FrameworkInfo");
    PUSH_MSG(args, slaveInfo, "SlaveInfo");
    dispatcher_->send( MesosCommand("registered", args) );
}

void ProxyExecutor::reregistered(ExecutorDriver* driver,
                                 const SlaveInfo& slaveInfo)
{
    CommandArgs args;
    PUSH_MSG(args, slaveInfo, "SlaveInfo");
    dispatcher_->send( MesosCommand("reregistered", args) );
}

void ProxyExecutor::disconnected(ExecutorDriver* driver)
{
    CommandArgs args;
    dispatcher_->send( MesosCommand("disconnected", args) );
}

void ProxyExecutor::launchTask(ExecutorDriver* driver,
                               const TaskInfo& task)
{
    CommandArgs args;
    PUSH_MSG(args, task, "TaskInfo");
    dispatcher_->send( MesosCommand("launchTask", args) );

}

void ProxyExecutor::killTask(ExecutorDriver* driver, const TaskID& taskId)
{
    CommandArgs args;
    PUSH_MSG(args, taskId, "TaskID");
    dispatcher_->send( MesosCommand("killTask", args) );
}

void ProxyExecutor::frameworkMessage(ExecutorDriver* driver,
                                     const std::string& data)
{
    CommandArgs args;
    args.push_back(CommandArg(data));
    dispatcher_->send( MesosCommand("frameworkMessage", args) );
}

void ProxyExecutor::shutdown(ExecutorDriver* driver)
{
    CommandArgs args;
    dispatcher_->send( MesosCommand("shutdown", args) );
}

void ProxyExecutor::error(ExecutorDriver* driver, const std::string& message)
{
    CommandArgs args;
    args.push_back(CommandArg(message));
    dispatcher_->send( MesosCommand("error", args) );
}


} // namespace perl {
} // namespace mesos {
