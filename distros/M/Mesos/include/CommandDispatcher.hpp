#ifndef COMMAND_DISPATCHER_
#define COMMAND_DISPATCHER_

#include <CommandChannel.hpp>

namespace mesos {
namespace perl  {

class CommandDispatcher
{
public:
    CommandChannel* channel_;

    CommandDispatcher(CommandChannel* channel);
    ~CommandDispatcher(){};

    void send(const MesosCommand& command);
    const MesosCommand recv();

    virtual void notify() = 0;
};

} // namespace perl  {
} // namespace mesos {

#endif // COMMAND_DISPATCHER_ 
