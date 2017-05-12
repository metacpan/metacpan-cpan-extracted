#include <CommandDispatcher.hpp>

namespace mesos {
namespace perl  {

CommandDispatcher::CommandDispatcher(CommandChannel* channel)
: channel_(channel)
{

}

void CommandDispatcher::send(const MesosCommand& command)
{
    channel_->send(command);
    notify();
}

const MesosCommand CommandDispatcher::recv()
{
    const MesosCommand command = channel_->recv();
    notify();
    return command;
}

} // namespace perl  {
} // namespace mesos {

