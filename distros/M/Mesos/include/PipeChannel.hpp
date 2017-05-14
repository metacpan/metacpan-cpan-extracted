#ifndef MESOS_PIPE_CHANNEL_
#define MESOS_PIPE_CHANNEL_
#include <MesosChannel.hpp>
#include <cstdio>
#include <mutex>

namespace mesos        {
namespace perl         {

class PipeChannel : public MesosChannel
{
public:
    std::queue<MesosCommand>* pending_;

    PipeChannel();
    ~PipeChannel();
    void send(const MesosCommand& command);
    const MesosCommand recv();
    MesosChannel* share();
    size_t size();
    int fd ();

private:
    int* count_;
    std::mutex* mutex_;
    FILE* in_;
    FILE* out_;
};

} // namespace perl         {
} // namespace mesos        {

#endif // MESOS_PIPE_CHANNEL_
