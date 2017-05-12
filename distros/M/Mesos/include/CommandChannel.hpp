#ifndef COMMAND_CHANNEL_
#define COMMAND_CHANNEL_

#include <mesos/scheduler.hpp>
#include <mutex>
#include <queue>
#include <string>
#include <vector>

#define PUSH_MSG(VEC, MSG, MSG_TYPE) VEC.push_back(CommandArg(MSG.SerializeAsString(), MSG_TYPE))

namespace mesos {
namespace perl  {

enum class context : int { SCALAR, ARRAY };

class CommandArg {
public:
    std::string scalar_data_;
    std::vector<std::string> array_data_;
    context context_;
    std::string type_;
    CommandArg();
    CommandArg(const std::vector<std::string>& array_data, const std::string type = std::string("String"));
    CommandArg(const std::string& scalar_data, const std::string type = std::string("String"));
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

class CommandChannel
{
public:
    CommandChannel();
    ~CommandChannel();

    void send(const MesosCommand& command);
    const MesosCommand recv();
    size_t size();

private:
    std::queue<MesosCommand>* pending_;
    std::mutex* mutex_;
};

} // namespace perl {
} // namespace mesos {

#endif // COMMAND_CHANNEL_
