#ifndef PIPE_DISPATCHER_
#define PIPE_DISPATCHER_

#include <CommandDispatcher.hpp>

namespace mesos {
namespace perl  {

class PipeDispatcher : public CommandDispatcher
{
public:
    int fd();
    int read_pipe();
    int write_pipe();

    PipeDispatcher(CommandChannel* channel);
    virtual ~PipeDispatcher();
    virtual void notify();

private:
    int fd_[2];
};

} // namespace perl  {
} // namespace mesos {

#endif // PIPE_DISPATCHER_
