#pragma once
#include <string>

class ILog {
    private:
    protected:
        void log(std::string msg, int level = 0);
    public:
        ILog();
        ~ILog();
};
