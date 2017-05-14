#ifndef EXECUTOR_DRIVER_HPP_
#define EXECUTOR_DRIVER_HPP_

#include <mesos/executor.hpp>
#include <ProxyExecutor.hpp>
#include <MesosChannel.hpp>
#include <memory>

using namespace mesos;

namespace mesos {
namespace perl {

class ExecutorDriver
{
public:
    Status status_;
    ProxyExecutor* proxyExecutor_;

    ExecutorDriver(ProxyExecutor* proxyExecutor = (new ProxyExecutor));
    virtual ~ExecutorDriver();

    virtual Status start();
    virtual Status stop();
    virtual Status abort();
    virtual Status join();
    virtual Status run();
    virtual Status sendStatusUpdate(const TaskStatus& status);
    virtual Status sendFrameworkMessage(const std::string& data);

private:
    mesos::MesosExecutorDriver* driver_;
};

} // namespace perl {
} // namespace mesos {

#endif // EXECUTOR_DRIVER_HPP_
