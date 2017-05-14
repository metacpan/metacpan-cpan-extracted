#ifndef PROXY_EXECUTOR_HPP_
#define PROXY_EXECUTOR_HPP_
#include <string>
#include <vector>
#include <memory>
#include <mesos/executor.hpp>
#include <PipeChannel.hpp>

using namespace mesos;

namespace mesos {
namespace perl {

class ProxyExecutor : public Executor
{
public:
    MesosChannel* channel_;

    ProxyExecutor(MesosChannel* channel = (new PipeChannel)): channel_(channel) {};
    virtual ~ProxyExecutor(){};

    virtual void registered(ExecutorDriver* driver,
                            const ExecutorInfo& executorInfo,
                            const FrameworkInfo& frameworkInfo,
                            const SlaveInfo& slaveInfo);
    virtual void reregistered(ExecutorDriver* driver,
                              const SlaveInfo& slaveInfo);
    virtual void disconnected(ExecutorDriver* driver);

    virtual void launchTask(ExecutorDriver* driver,
                            const TaskInfo& task);

    virtual void killTask(ExecutorDriver* driver, const TaskID& taskId);

    virtual void frameworkMessage(ExecutorDriver* driver,
                                  const std::string& data);

    virtual void shutdown(ExecutorDriver* driver);

    virtual void error(ExecutorDriver* driver, const std::string& message);
};

} // namespace perl {
} // namespace mesos {

#endif // PROXY_EXECUTOR_HPP_
