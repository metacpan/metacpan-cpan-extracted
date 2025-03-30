#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef __cplusplus
}
#endif

#include <string>

// Perl declaration from handy.h conflicts with Value::Null
#undef Null
#include <launchdarkly/server_side/client.hpp>
#include <launchdarkly/server_side/config/config_builder.hpp>
#include <launchdarkly/context_builder.hpp>

#include "const-c.inc"

using namespace launchdarkly;
using namespace launchdarkly::server_side;

typedef AttributesBuilder<ContextBuilder, Context> attributesbuilder;
typedef std::future<bool> Future;
typedef std::future_status Status;

MODULE = LaunchDarkly::Server		PACKAGE = LaunchDarkly::Server::ConfigBuilder
PROTOTYPES: ENABLE

ConfigBuilder *
ConfigBuilder::new(std::string sdk_key)

void
ConfigBuilder::DESTROY()

Config *
ConfigBuilder::Build()
        const char * CLASS = "LaunchDarkly::Server::Config";
    CODE:
        auto res = THIS->Build();
        if (res)
            RETVAL = new ConfigBuilder::Result(std::move(res.value()));
        else
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

MODULE = LaunchDarkly::Server		PACKAGE = LaunchDarkly::Server::Config
PROTOTYPES: ENABLE

void
Config::DESTROY()

MODULE = LaunchDarkly::Server		PACKAGE = LaunchDarkly::Server::Client
PROTOTYPES: ENABLE

Client *
Client::new(Config *config)
    CODE:
        RETVAL = new Client(*config);
    OUTPUT:
        RETVAL

void
Client::DESTROY()

Future *
Client::StartAsync()
        const char * CLASS = "LaunchDarkly::Future";
    CODE:
        RETVAL = new std::future<bool>(THIS->StartAsync());
    OUTPUT:
        RETVAL

bool
Client::BoolVariation(Context *context, std::string key, bool default_value)
    CODE:
        RETVAL = THIS->BoolVariation(*context, key, default_value);
    OUTPUT:
        RETVAL

std::string
Client::StringVariation(Context *context, std::string key, std::string default_value)
    CODE:
        RETVAL = THIS->StringVariation(*context, key, default_value);
    OUTPUT:
        RETVAL

double
Client::DoubleVariation(Context *context, std::string key, double default_value)
    CODE:
        RETVAL = THIS->DoubleVariation(*context, key, default_value);
    OUTPUT:
        RETVAL

int
Client::IntVariation(Context *context, std::string key, int default_value)
    CODE:
        RETVAL = THIS->IntVariation(*context, key, default_value);
    OUTPUT:
        RETVAL

MODULE = LaunchDarkly::Server		PACKAGE = LaunchDarkly::Future
PROTOTYPES: ENABLE

void
Future::Wait()
    CODE:
        THIS->wait();

Status
Future::WaitFor(int milliseconds)
    CODE:
        RETVAL = THIS->wait_for(std::chrono::milliseconds(milliseconds));
    OUTPUT:
        RETVAL

void
Future::DESTROY()

MODULE = LaunchDarkly::Server		PACKAGE = LaunchDarkly::Status
PROTOTYPES: ENABLE

#define STATUS_READY    (int)std::future_status::ready
#define STATUS_TIMEOUT  (int)std::future_status::timeout
#define STATUS_DEFERRED (int)std::future_status::deferred

int
Ready()
    ALIAS:
        Ready = STATUS_READY
        Timeout = STATUS_TIMEOUT
        Deferred = STATUS_DEFERRED
    CODE:
        RETVAL = ix;
    OUTPUT:
        RETVAL


MODULE = LaunchDarkly::Server   PACKAGE = LaunchDarkly::ContextBuilder
PROTOTYPES: ENABLE

ContextBuilder *
ContextBuilder::new()

void
ContextBuilder::DESTROY()

attributesbuilder *
ContextBuilder::Kind(std::string kind, std::string key)
        const char * CLASS = "attributesbuilder";
    CODE:
        RETVAL = &THIS->Kind(kind, key);
    OUTPUT:
        RETVAL

Context *
ContextBuilder::Build()
        const char * CLASS = "LaunchDarkly::Context";
    CODE:
        RETVAL = new Context(std::move(THIS->Build()));
    OUTPUT:
        RETVAL

MODULE = LaunchDarkly   PACKAGE = attributesbuilder
PROTOTYPES: ENABLE

void
attributesbuilder::Set(std::string name, Value *value)
    CODE:
        if (value)
            THIS->Set(name, std::move(*value));

MODULE = LaunchDarkly   PACKAGE = LaunchDarkly::Value
PROTOTYPES: ENABLE

Value *
NewInt(int num)
        const char * CLASS = "LaunchDarkly::Value";
    CODE:
        RETVAL = new Value(num);
    OUTPUT:
        RETVAL

Value *
NewDouble(double num)
        const char * CLASS = "LaunchDarkly::Value";
    CODE:
        RETVAL = new Value(num);
    OUTPUT:
        RETVAL

Value *
NewString(std::string str)
        const char * CLASS = "LaunchDarkly::Value";
    CODE:
        RETVAL = new Value(str);
    OUTPUT:
        RETVAL

Value *
NewBool(bool b)
        const char * CLASS = "LaunchDarkly::Value";
    CODE:
        RETVAL = new Value(b);
    OUTPUT:
        RETVAL

void
Value::DESTROY()

MODULE = LaunchDarkly   PACKAGE = LaunchDarkly::Context
PROTOTYPES: ENABLE

void
Context::DESTROY()

MODULE = LaunchDarkly::Server   PACKAGE = LaunchDarkly::Server

INCLUDE: const-xs.inc

BOOT:
{
}

