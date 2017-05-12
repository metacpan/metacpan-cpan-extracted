#include <InterruptDispatcher.hpp>

namespace mesos {
namespace perl  {

InterruptDispatcher::InterruptDispatcher(CommandChannel* channel,
                                         interrupt_cb_t  cb,
                                         void*           arg)
: interrupt_cb_(cb), interrupt_arg_(arg),
  CommandDispatcher(channel)
{

}

void InterruptDispatcher::notify()
{
    interrupt_cb_(interrupt_arg_, 0);
}

} // namespace perl  {
} // namespace mesos {

