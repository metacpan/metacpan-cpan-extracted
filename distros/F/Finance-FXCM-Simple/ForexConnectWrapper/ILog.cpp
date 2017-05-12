#include "ILog.h"
#include <iostream>

ILog::ILog() {
}

ILog::~ILog() {
}

void ILog::log(std::string msg, int level) {
 std::cerr << "[ForexConnectWrapper] " << msg << std::endl;
}
