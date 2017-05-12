#include <CommandChannel.hpp>

namespace mesos {
namespace perl {

CommandArg::CommandArg()
: scalar_data_(std::string("")), type_(std::string("String")),
  context_(context::SCALAR)
{

}

CommandArg::CommandArg(const std::string& data, const std::string type)
: scalar_data_(std::string(data)), type_(type),
  context_(context::SCALAR)
{

}

CommandArg::CommandArg(const std::vector<std::string>& data, const std::string type)
: array_data_(data), type_(type),
  context_(context::ARRAY)
{

}

MesosCommand::MesosCommand(const std::string& name, const CommandArgs& args)
: name_(name), args_(args)
{

}

MesosCommand::MesosCommand()
: name_(std::string("")), args_(CommandArgs())
{

}

CommandChannel::CommandChannel()
: pending_(new std::queue<MesosCommand>), mutex_(new std::mutex)
{

}

CommandChannel::~CommandChannel()
{
    delete pending_;
    delete mutex_;
}

void CommandChannel::send(const MesosCommand& command)
{
    mutex_->lock();
    pending_->push(command);
    mutex_->unlock();
}

const MesosCommand CommandChannel::recv()
{
    std::lock_guard<std::mutex> lock (*mutex_);
    if (pending_->size()) {
        const MesosCommand command = pending_->front();
        pending_->pop();
        return command;
    } else {
        return MesosCommand(std::string(), CommandArgs());
    }
}

size_t CommandChannel::size() {
    return pending_->size();
}

} // namespace perl {
} // namespace mesos {
