#ifndef INTERRUPT_DISPATCHER_
#define INTERRUPT_DISPATCHER_
#include <CommandDispatcher.hpp>

typedef void (*interrupt_cb_t) (void *, int);

namespace mesos {
namespace perl  {

class InterruptDispatcher : public CommandDispatcher
{
public:
    InterruptDispatcher(CommandChannel*, interrupt_cb_t, void*);
    virtual void notify();

private:
    interrupt_cb_t interrupt_cb_;
    void*          interrupt_arg_;
};

} // namespace perl         {
} // namespace mesos        {

#endif // INTERRUPT_DISPATCHER_
