#include <ExecutorDriver.hpp>

namespace mesos {
namespace perl {

ExecutorDriver::ExecutorDriver(ProxyExecutor* proxyExecutor)
: proxyExecutor_(proxyExecutor),
  driver_(new MesosExecutorDriver(proxyExecutor_))
{

}

ExecutorDriver::~ExecutorDriver()
{
    delete driver_;
    delete proxyExecutor_;
}

Status ExecutorDriver::start()
{
    return status_ = driver_->start();
}

Status ExecutorDriver::stop()
{
    return status_ = driver_->stop();
}

Status ExecutorDriver::abort()
{
    return status_ = driver_->abort();
}

Status ExecutorDriver::join()
{
    return status_ = driver_->join();
}

Status ExecutorDriver::run()
{
    return status_ = driver_->run();
}

Status ExecutorDriver::sendStatusUpdate(const TaskStatus& status)
{
    return status_ = driver_->sendStatusUpdate(status);
}

Status ExecutorDriver::sendFrameworkMessage(const std::string& data)
{
    return status_ = driver_->sendFrameworkMessage(data);
}

} // namespace perl {
} // namespace mesos {
