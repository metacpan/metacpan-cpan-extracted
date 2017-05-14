#include <MesosChannel.hpp>

namespace mesos {
namespace perl {

CommandArg::CommandArg()
: scalar_data_(std::string("")), array_data_(std::vector<std::string>()),
  type_(std::string("String")), context_(context::SCALAR)
{

}

CommandArg::CommandArg(const std::string& data, const std::string type)
: scalar_data_(data), array_data_(std::vector<std::string>()), type_(type), context_(context::SCALAR)
{

}

CommandArg::CommandArg(const std::vector<std::string>& data, const std::string type)
: scalar_data_(std::string("")), array_data_(data), type_(type), context_(context::ARRAY)
{

}

MesosCommand::MesosCommand(const std::string& name, const CommandArgs& args)
: name_(name), args_(args)
{

}

MesosCommand::MesosCommand()
: name_(std::string("")), args_(CommandArgs())
{

}


} // namespace perl {
} // namespace mesos {
