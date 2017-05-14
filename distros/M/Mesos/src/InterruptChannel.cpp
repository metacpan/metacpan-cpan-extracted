#include <InterruptChannel.hpp>

namespace mesos      {
namespace perl       {

InterruptChannel::InterruptChannel(interrupt_cb_t interrupt_cb, void* interrupt_arg)
: pending_(new std::queue<MesosCommand>), count_(new int(1)), mutex_(new std::mutex),
  interrupt_cb_(interrupt_cb), interrupt_arg_(interrupt_arg)
{

}

InterruptChannel::~InterruptChannel()
{
    if (--*count_ == 0) {
        delete pending_;
        delete count_;
        delete mutex_;
    }
}

MesosChannel* InterruptChannel::share()
{
    ++*count_;
    InterruptChannel* to_share = new InterruptChannel(*this);
    return to_share;
}

void InterruptChannel::send(const MesosCommand& command)
{
    mutex_->lock();
    pending_->push(command);
    mutex_->unlock();
    interrupt_cb_(interrupt_arg_, 0);
}

const MesosCommand InterruptChannel::recv()
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

size_t InterruptChannel::size() {
    return pending_->size();
}
} // namespace perl  {
} // namespace mesos {
