#include "../ForexConnectWrapper.h"
#include <stdio.h>

int main(int argc, char *argv[]) {
    const char *user = "GBD118836001";
    const char *password = "5358";
    const char *url = "http://www.fxcorporate.com/Hosts.jsp";
    const char *connection = "Demo";
    ForexConnectWrapper *tradeStation = NULL;

    try {
        tradeStation = new ForexConnectWrapper(user, password, connection, url);
        //tradeStation->setSubscriptionStatus("GBP/CAD", "T");
/*
        tradeStation->closeMarket("12914251", 3000);
        tradeStation->closeMarket("12914191", 3000);
        //tradeStation->openMarket("AUD/USD", "B", 3000);

        std::string trades = tradeStation->getTradesAsYAML();
        printf("%s\n", trades.c_str());
*/
    }

    catch(char const *error) {
        printf("%s\n", error);
    }

    if (tradeStation) {
        delete tradeStation;
    }
}
