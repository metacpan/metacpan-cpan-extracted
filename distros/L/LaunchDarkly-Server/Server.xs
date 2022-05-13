#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <launchdarkly/client.h>
#include <launchdarkly/variations.h>
#include <launchdarkly/logging.h>


/* Global Data */

#define MY_CXT_KEY "LaunchDarkly::_guts" XS_VERSION


typedef struct {
    struct LDDetails details;
} my_cxt_t;

START_MY_CXT

#include "const-c.inc"

#define variation(func) \
    struct LDDetails *	details = NULL; \
    if (getDetails) { \
        dMY_CXT; \
        details = &MY_CXT.details; \
        LDDetailsInit(details); \
    } \
    RETVAL = func(client, user, key, fallback, details); \

MODULE = LaunchDarkly::Server		PACKAGE = LaunchDarkly::Server
PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
    LDBasicLoggerThreadSafeInitialize();
    LDConfigureGlobalLogger(LD_LOG_ERROR, LDBasicLoggerThreadSafe);
    LDDetailsInit(&MY_CXT.details);
}

# Set the log level, see:
# https://github.com/launchdarkly/c-server-sdk/blob/master/c-sdk-common/include/launchdarkly/logging.h#L10-L20
void
LDSetLogLevel(level)
        int level
    CODE:
        level = (level < LD_LOG_FATAL) ? LD_LOG_FATAL : ((level > LD_LOG_TRACE) ? LD_LOG_TRACE : level);
        LDConfigureGlobalLogger(level, LDBasicLoggerThreadSafe);

struct LDJSON *
LDAllFlags(client, user)
	struct LDClient *	client
	const struct LDUser *	user

struct LDAllFlagsState *
LDAllFlagsState(client, user, options)
	struct LDClient *	client
	const struct LDUser *	user
	unsigned int	options

void
LDAllFlagsStateFree(flags)
	struct LDAllFlagsState *	flags

struct LDDetails *
LDAllFlagsStateGetDetails(flags, key)
	struct LDAllFlagsState *	flags
	const char *	key

struct LDJSON *
LDAllFlagsStateGetValue(flags, key)
	struct LDAllFlagsState *	flags
	const char *	key

char *
LDAllFlagsStateSerializeJSON(flags)
	struct LDAllFlagsState *	flags

struct LDJSON *
LDAllFlagsStateToValuesMap(flags)
	struct LDAllFlagsState *	flags

LDBoolean
LDAllFlagsStateValid(flags)
	struct LDAllFlagsState *	flags

LDBoolean
LDArrayAppend(prefix, suffix)
	struct LDJSON *	prefix
	const struct LDJSON *	suffix

struct LDJSON *
LDArrayLookup(array, index)
	const struct LDJSON *	array
	unsigned int	index

LDBoolean
LDArrayPush(array, item)
	struct LDJSON *	array
	struct LDJSON *	item

LDBoolean
LDBoolVariation(client, user, key, fallback, getDetails)
        struct LDClient *	client
        const struct LDUser *	user
        const char *	key
        LDBoolean	fallback
        bool getDetails
    CODE:
        variation(LDBoolVariation)
    OUTPUT:
        RETVAL
        

LDBoolean
LDClientAlias(client, currentUser, previousUser)
	struct LDClient *	client
	const struct LDUser *	currentUser
	const struct LDUser *	previousUser

LDBoolean
LDClientClose(client)
	struct LDClient *	client

LDBoolean
LDClientFlush(client)
	struct LDClient *	client

LDBoolean
LDClientIdentify(client, user)
	struct LDClient *	client
	const struct LDUser *	user

struct LDClient *
LDClientInit(config, maxwaitmilli)
	struct LDConfig *	config
	unsigned int	maxwaitmilli

LDBoolean
LDClientIsInitialized(client)
	struct LDClient *	client

LDBoolean
LDClientIsOffline(client)
	struct LDClient *	client

LDBoolean
LDClientTrack(client, key, user, data)
	struct LDClient *	client
	const char *	key
	const struct LDUser *	user
	struct LDJSON *	data

LDBoolean
LDClientTrackMetric(client, key, user, data, metric)
	struct LDClient *	client
	const char *	key
	const struct LDUser *	user
	struct LDJSON *	data
	double	metric

struct LDJSON *
LDCollectionDetachIter(collection, iter)
	struct LDJSON *	collection
	struct LDJSON *	iter

unsigned int
LDCollectionGetSize(collection)
	const struct LDJSON *	collection

LDBoolean
LDConfigAddPrivateAttribute(config, attribute)
	struct LDConfig *	config
	const char *	attribute

void
LDConfigFree(config)
	struct LDConfig *	config

void
LDConfigInlineUsersInEvents(config, inlineUsersInEvents)
	struct LDConfig *	config
	LDBoolean	inlineUsersInEvents

struct LDConfig *
LDConfigNew(key)
	const char *	key

void
LDConfigSetAllAttributesPrivate(config, allAttributesPrivate)
	struct LDConfig *	config
	LDBoolean	allAttributesPrivate

LDBoolean
LDConfigSetBaseURI(config, baseURI)
	struct LDConfig *	config
	const char *	baseURI

void
LDConfigSetEventsCapacity(config, eventsCapacity)
	struct LDConfig *	config
	unsigned int	eventsCapacity

LDBoolean
LDConfigSetEventsURI(config, eventsURI)
	struct LDConfig *	config
	const char *	eventsURI

void
LDConfigSetFeatureStoreBackend(config, backend)
	struct LDConfig *	config
	struct LDStoreInterface *	backend

void
LDConfigSetFeatureStoreBackendCacheTTL(config, milliseconds)
	struct LDConfig *	config
	unsigned int	milliseconds

void
LDConfigSetFlushInterval(config, milliseconds)
	struct LDConfig *	config
	unsigned int	milliseconds

void
LDConfigSetOffline(config, offline)
	struct LDConfig *	config
	LDBoolean	offline

void
LDConfigSetPollInterval(config, milliseconds)
	struct LDConfig *	config
	unsigned int	milliseconds

void
LDConfigSetSendEvents(config, sendEvents)
	struct LDConfig *	config
	LDBoolean	sendEvents

void
LDConfigSetStream(config, stream)
	struct LDConfig *	config
	LDBoolean	stream

LDBoolean
LDConfigSetStreamURI(config, streamURI)
	struct LDConfig *	config
	const char *	streamURI

void
LDConfigSetTimeout(config, milliseconds)
	struct LDConfig *	config
	unsigned int	milliseconds

void
LDConfigSetUseLDD(config, useLDD)
	struct LDConfig *	config
	LDBoolean	useLDD

void
LDConfigSetUserKeysCapacity(config, userKeysCapacity)
	struct LDConfig *	config
	unsigned int	userKeysCapacity

void
LDConfigSetUserKeysFlushInterval(config, milliseconds)
	struct LDConfig *	config
	unsigned int	milliseconds

LDBoolean
LDConfigSetWrapperInfo(config, wrapperName, wrapperVersion)
	struct LDConfig *	config
	const char *	wrapperName
	const char *	wrapperVersion

void
LDDetailsClear(details)
	struct LDDetails *	details

# No Need to call this function explicitly
#void
#LDDetailsInit(details)
#	struct LDDetails *	details

SV *
LDDetailsToString()
    CODE:
        dMY_CXT;
        struct LDDetails * details = &MY_CXT.details;

        RETVAL = newSVpv(LDEvalReasonKindToString(details->reason), 0);
        switch (details->reason) {
        case LD_ERROR:
            sv_catpvf(RETVAL, ", errorKind=%s", LDEvalReasonKindToString(details->extra.errorKind));
            break;
        case LD_PREREQUISITE_FAILED:
            sv_catpvf(RETVAL, ", prerequisiteKey=%s", details->extra.prerequisiteKey);
            break;
        case LD_RULE_MATCH:
            sv_catpvf(RETVAL, ", ruleIndex=%u, ruleId=%s, inExperiment=%d",
                details->extra.rule.ruleIndex, details->extra.rule.id, details->extra.rule.inExperiment);
            break;
        case LD_FALLTHROUGH:
            sv_catpvf(RETVAL, ", inExperiment=%d", details->extra.fallthrough.inExperiment);
            break;
        }
        if (details->hasVariation) {
            sv_catpvf(RETVAL, ", variationIndex=%u", details->variationIndex);
        }
    OUTPUT:
        RETVAL

double
LDDoubleVariation(client, user, key, fallback, getDetails)
        struct LDClient *	client
        const struct LDUser *	user
        const char *	key
        double	fallback
        bool getDetails
    CODE:
        variation(LDDoubleVariation)
    OUTPUT:
        RETVAL

#const char *
#LDEvalErrorKindToString(kind)
#	enum LDEvalErrorKind	kind

#const char *
#LDEvalReasonKindToString(kind)
#	enum LDEvalReason	kind

LDBoolean
LDGetBool(node)
	const struct LDJSON *	node

struct LDJSON *
LDGetIter(collection)
	const struct LDJSON *	collection

double
LDGetNumber(node)
	const struct LDJSON *	node

const char *
LDGetText(node)
	const struct LDJSON *	node

int
LDIntVariation(client, user, key, fallback, getDetails)
    	struct LDClient *	client
	    const struct LDUser *	user
    	const char *	key
	    int	fallback
        bool getDetails
    CODE:
        variation(LDIntVariation)
    OUTPUT:
        RETVAL

const char *
LDIterKey(iter)
	const struct LDJSON *	iter

struct LDJSON *
LDIterNext(iter)
	const struct LDJSON *	iter

LDBoolean
LDJSONCompare(left, right)
	const struct LDJSON *	left
	const struct LDJSON *	right

struct LDJSON *
LDJSONDeserialize(text)
	const char *	text

struct LDJSON *
LDJSONDuplicate(json)
	const struct LDJSON *	json

void
LDJSONFree(json)
	struct LDJSON *	json

LDJSONType
LDJSONGetType(json)
	const struct LDJSON *	json

char *
LDJSONSerialize(json)
	const struct LDJSON *	json

struct LDJSON *
LDJSONVariation(client, user, key, fallback, getDetails)
        struct LDClient *	client
        const struct LDUser *	user
        const char *	key
        const struct LDJSON *	fallback
        bool getDetails
    CODE:
        variation(LDJSONVariation)
    OUTPUT:
        RETVAL

struct LDJSON *
LDNewArray()

struct LDJSON *
LDNewBool(boolean)
	LDBoolean	boolean

struct LDJSON *
LDNewNull()

struct LDJSON *
LDNewNumber(number)
	double	number

struct LDJSON *
LDNewObject()

struct LDJSON *
LDNewText(text)
	const char *	text

void
LDObjectDeleteKey(object, key)
	struct LDJSON *	object
	const char *	key

struct LDJSON *
LDObjectDetachKey(object, key)
	struct LDJSON *	object
	const char *	key

struct LDJSON *
LDObjectLookup(object, key)
	const struct LDJSON *	object
	const char *	key

LDBoolean
LDObjectMerge(to, from)
	struct LDJSON *	to
	const struct LDJSON *	from

LDBoolean
LDObjectSetKey(object, key, item)
	struct LDJSON *	object
	const char *	key
	struct LDJSON *	item

struct LDJSON *
LDReasonToJSON(details)
	const struct LDDetails *	details

LDBoolean
LDSetNumber(node, number)
	struct LDJSON *	node
	double	number

char *
LDStringVariation(client, user, key, fallback, getDetails)
        struct LDClient *	client
        const struct LDUser *	user
        const char *	key
        const char *	fallback
        bool getDetails
    CODE:
        variation(LDStringVariation)
    OUTPUT:
        RETVAL

LDBoolean
LDUserAddPrivateAttribute(user, attribute)
	struct LDUser *	user
	const char *	attribute

void
LDUserFree(user)
	struct LDUser *	user

struct LDUser *
LDUserNew(key)
	const char *	key

void
LDUserSetAnonymous(user, anon)
	struct LDUser *	user
	LDBoolean	anon

LDBoolean
LDUserSetAvatar(user, avatar)
	struct LDUser *	user
	const char *	avatar

LDBoolean
LDUserSetCountry(user, country)
	struct LDUser *	user
	const char *	country

void
LDUserSetCustom(user, custom)
	struct LDUser *	user
	struct LDJSON *	custom

void
LDUserSetCustomAttributesJSON(user, custom)
	struct LDUser *	user
	struct LDJSON *	custom

LDBoolean
LDUserSetEmail(user, email)
	struct LDUser *	user
	const char *	email

LDBoolean
LDUserSetFirstName(user, firstName)
	struct LDUser *	user
	const char *	firstName

LDBoolean
LDUserSetIP(user, ip)
	struct LDUser *	user
	const char *	ip

LDBoolean
LDUserSetLastName(user, lastName)
	struct LDUser *	user
	const char *	lastName

LDBoolean
LDUserSetName(user, name)
	struct LDUser *	user
	const char *	name

void
LDUserSetPrivateAttributes(user, privateAttributes)
	struct LDUser *	user
	struct LDJSON *	privateAttributes

LDBoolean
LDUserSetSecondary(user, secondary)
	struct LDUser *	user
	const char *	secondary
