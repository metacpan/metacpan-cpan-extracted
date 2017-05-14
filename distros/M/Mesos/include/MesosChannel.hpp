#ifndef SCHEDULER_CHANNEL_
#define SCHEDULER_CHANNEL_

#include <mesos/scheduler.hpp>
#include <string>
#include <vector>
#include <queue>

#define PUSH_MSG(VEC, MSG, MSG_TYPE) VEC.push_back(CommandArg(MSG.SerializeAsString(), MSG_TYPE))

namespace mesos {
namespace perl {

enum class context : int { SCALAR, ARRAY };

class CommandArg {
public:
    std::string scalar_data_;
    std::vector<std::string> array_data_;
    std::string type_;
    context context_;
    CommandArg();
    CommandArg(const std::string& data, const std::string type = std::string("String"));
    CommandArg(const std::vector<std::string>& data, const std::string type = std::string("String"));
};

typedef std::vector<CommandArg> CommandArgs;
class MesosCommand
{
public:
    std::string name_;
    CommandArgs args_;

    MesosCommand();
    MesosCommand(const std::string& name, const CommandArgs& args);
};

class MesosChannel
{
public:
    virtual ~MesosChannel(){};
    virtual void send(const MesosCommand& command) = 0;
    virtual const MesosCommand recv() = 0;
    virtual MesosChannel* share() = 0;
    virtual size_t size() = 0;
};

} // namespace perl {
} // namespace mesos {

#endif // SCHEDULER_CHANNEL_
