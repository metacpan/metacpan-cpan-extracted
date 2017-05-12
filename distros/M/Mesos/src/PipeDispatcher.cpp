#include <PipeDispatcher.hpp>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

namespace mesos {
namespace perl  {

PipeDispatcher::PipeDispatcher(CommandChannel* channel)
: CommandDispatcher(channel)
{
    if (pipe(fd_) >= 0) {
        fcntl(fd_[0], F_SETFL, O_NONBLOCK);
        fcntl(fd_[1], F_SETFL, O_NONBLOCK);
    }
}

PipeDispatcher::~PipeDispatcher()
{
    close(fd_[0]);
    close(fd_[1]);
}

int PipeDispatcher::fd()
{
    return fd_[0];
}

int PipeDispatcher::read_pipe()
{
    char buf[1];
    return read(fd_[0], buf, 1);
}

int PipeDispatcher::write_pipe()
{
    return write(fd_[1], "", sizeof(char));
}

void PipeDispatcher::notify()
{
    write_pipe();
}

} // namespace perl  {
} // namespace mesos {

