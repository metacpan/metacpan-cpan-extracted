#include <PipeChannel.hpp>
#include <unistd.h>

namespace mesos        {
namespace perl         {

PipeChannel::PipeChannel()
: pending_(new std::queue<MesosCommand>), count_(new int(1)),
  mutex_(new std::mutex)
{
    int fds[2];
    pipe(fds);
    in_ = fdopen(fds[0], "r");
    out_ = fdopen(fds[1], "w");
    setvbuf(in_, NULL, _IONBF, 0);
    setvbuf(out_, NULL, _IONBF, 0);
}

PipeChannel::~PipeChannel()
{
    if (--*count_ == 0) {
        fclose(in_);
        fclose(out_);
        delete pending_;
        delete count_;
        delete mutex_;
    }
}

MesosChannel* PipeChannel::share()
{
    ++*count_;
    PipeChannel* to_share = new PipeChannel(*this);
    return to_share;
}

void PipeChannel::send(const MesosCommand& command)
{
    std::lock_guard<std::mutex> lock (*mutex_);
    pending_->push(command);
    fprintf(out_, "%s\n", command.name_.c_str());
}

const MesosCommand PipeChannel::recv()
{
    std::lock_guard<std::mutex> lock (*mutex_);
    char str[100];
    if (fgets(str, 100, in_) != NULL) {
        const MesosCommand command = pending_->front();
        pending_->pop();
        return command;
    } else {
        return MesosCommand(std::string(), CommandArgs());
    }
}

size_t PipeChannel::size() {
    return pending_->size();
}

int PipeChannel::fd() {
    return fileno(in_);
}

} // namespace perl         {
} // namespace mesos        {
