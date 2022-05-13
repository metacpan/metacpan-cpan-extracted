package LaunchDarkly::Server;

use v5.18.2;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use LaunchDarkly::Server ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	LD_CLIENT_NOT_READY
	LD_CLIENT_NOT_SPECIFIED
	LD_ERROR
	LD_FALLTHROUGH
	LD_FLAG_NOT_FOUND
	LD_LOG_CRITICAL
	LD_LOG_DEBUG
	LD_LOG_ERROR
	LD_LOG_FATAL
	LD_LOG_INFO
	LD_LOG_TRACE
	LD_LOG_WARNING
	LD_MALFORMED_FLAG
	LD_NULL_KEY
	LD_OFF
	LD_OOM
	LD_PREREQUISITE_FAILED
	LD_RULE_MATCH
	LD_STORE_ERROR
	LD_TARGET_MATCH
	LD_UNKNOWN
	LD_USER_NOT_SPECIFIED
	LD_WRONG_TYPE
	LDAllFlags
	LDAllFlagsState
	LDAllFlagsStateFree
	LDAllFlagsStateGetDetails
	LDAllFlagsStateGetValue
	LDAllFlagsStateSerializeJSON
	LDAllFlagsStateToValuesMap
	LDAllFlagsStateValid
	LDArrayAppend
	LDArrayLookup
	LDArrayPush
	LDBoolVariation
	LDClientAlias
	LDClientClose
	LDClientFlush
	LDClientIdentify
	LDClientInit
	LDClientIsInitialized
	LDClientIsOffline
	LDClientTrack
	LDClientTrackMetric
	LDCollectionDetachIter
	LDCollectionGetSize
	LDConfigAddPrivateAttribute
	LDConfigFree
	LDConfigInlineUsersInEvents
	LDConfigNew
	LDConfigSetAllAttributesPrivate
	LDConfigSetBaseURI
	LDConfigSetEventsCapacity
	LDConfigSetEventsURI
	LDConfigSetFeatureStoreBackend
	LDConfigSetFeatureStoreBackendCacheTTL
	LDConfigSetFlushInterval
	LDConfigSetOffline
	LDConfigSetPollInterval
	LDConfigSetSendEvents
	LDConfigSetStream
	LDConfigSetStreamURI
	LDConfigSetTimeout
	LDConfigSetUseLDD
	LDConfigSetUserKeysCapacity
	LDConfigSetUserKeysFlushInterval
	LDConfigSetWrapperInfo
	LDDetailsClear
	LDDetailsInit
	LDDoubleVariation
	LDEvalErrorKindToString
	LDEvalReasonKindToString
	LDGetBool
	LDGetIter
	LDGetNumber
	LDGetText
	LDIntVariation
	LDIterKey
	LDIterNext
	LDJSONCompare
	LDJSONDeserialize
	LDJSONDuplicate
	LDJSONFree
	LDJSONGetType
	LDJSONSerialize
	LDJSONVariation
	LDNewArray
	LDNewBool
	LDNewNull
	LDNewNumber
	LDNewObject
	LDNewText
	LDObjectDeleteKey
	LDObjectDetachKey
	LDObjectLookup
	LDObjectMerge
	LDObjectSetKey
	LDReasonToJSON
	LDSetNumber
	LDStringVariation
	LDUserAddPrivateAttribute
	LDUserFree
	LDUserNew
	LDUserSetAnonymous
	LDUserSetAvatar
	LDUserSetCountry
	LDUserSetCustom
	LDUserSetCustomAttributesJSON
	LDUserSetEmail
	LDUserSetFirstName
	LDUserSetIP
	LDUserSetLastName
	LDUserSetName
	LDUserSetPrivateAttributes
	LDUserSetSecondary
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	LD_CLIENT_NOT_READY
	LD_CLIENT_NOT_SPECIFIED
	LD_ERROR
	LD_FALLTHROUGH
	LD_FLAG_NOT_FOUND
	LD_LOG_CRITICAL
	LD_LOG_DEBUG
	LD_LOG_ERROR
	LD_LOG_FATAL
	LD_LOG_INFO
	LD_LOG_TRACE
	LD_LOG_WARNING
	LD_MALFORMED_FLAG
	LD_NULL_KEY
	LD_OFF
	LD_OOM
	LD_PREREQUISITE_FAILED
	LD_RULE_MATCH
	LD_STORE_ERROR
	LD_TARGET_MATCH
	LD_UNKNOWN
	LD_USER_NOT_SPECIFIED
	LD_WRONG_TYPE
);

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&LaunchDarkly::Server::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('LaunchDarkly::Server', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

LaunchDarkly::Server - Perl server side SDK for LaunchDarkly

=head1 SYNOPSIS

  use LaunchDarkly::Server;

  my $config = LaunchDarkly::Server::LDConfigNew("my-sdk-key");
  my $timeout = 10000;
  my $debug = 0;
  my $default = 0;
  my $client = LaunchDarkly::Server::LDClientInit($config, $timeout);

  my $user = LaunchDarkly::Server::LDUserNew("user123");
  my result = LaunchDarkly::Server::LDBoolVariation($client, $user, "my-very-new-feature", $default, $debug);
  print LaunchDarkly::Server::LDDetailsToString() unless not $debug;
  LaunchDarkly::Server::LDUserFree($user);

  LaunchDarkly::Server::LDClientClose($client);

=head1 DESCRIPTION

See https://docs.launchdarkly.com/sdk/server-side/c-c--

=head2 EXPORT

None by default.

=head2 Exportable constants

  LD_CLIENT_NOT_READY
  LD_CLIENT_NOT_SPECIFIED
  LD_ERROR
  LD_FALLTHROUGH
  LD_FLAG_NOT_FOUND
  LD_LOG_CRITICAL
  LD_LOG_DEBUG
  LD_LOG_ERROR
  LD_LOG_FATAL
  LD_LOG_INFO
  LD_LOG_TRACE
  LD_LOG_WARNING
  LD_MALFORMED_FLAG
  LD_NULL_KEY
  LD_OFF
  LD_OOM
  LD_PREREQUISITE_FAILED
  LD_RULE_MATCH
  LD_STORE_ERROR
  LD_TARGET_MATCH
  LD_UNKNOWN
  LD_USER_NOT_SPECIFIED
  LD_WRONG_TYPE

=head2 Exportable functions

  void
LDSetLogLevel(int level)
  struct LDJSON *
LDAllFlags(struct LDClient *const client, const struct LDUser *const user)
  struct LDAllFlagsState *
LDAllFlagsState(struct LDClient *const client, const struct LDUser *const user, unsigned int options)
  void
LDAllFlagsStateFree(struct LDAllFlagsState *flags)
  struct LDDetails*
LDAllFlagsStateGetDetails(struct LDAllFlagsState* flags, const char* key)
  struct LDJSON*
LDAllFlagsStateGetValue(struct LDAllFlagsState* flags, const char* key)
  char*
LDAllFlagsStateSerializeJSON(struct LDAllFlagsState *flags)
  struct LDJSON*
LDAllFlagsStateToValuesMap(struct LDAllFlagsState* flags)
  LDBoolean
LDAllFlagsStateValid(struct LDAllFlagsState *flags)
  LDBoolean
LDArrayAppend(struct LDJSON *const prefix, const struct LDJSON *const suffix)
  struct LDJSON *
LDArrayLookup(const struct LDJSON *const array, const unsigned int index)
  LDBoolean
LDArrayPush(struct LDJSON *const array, struct LDJSON *const item)
  LDBoolean
LDBoolVariation(
    struct LDClient *const client,
    const struct LDUser *const user,
    const char *const key,
    const LDBoolean fallback,
    bool getDetails)
  LDBoolean
LDClientAlias(
    struct LDClient *const client,
    const struct LDUser *const currentUser,
    const struct LDUser *const previousUser)
  LDBoolean
LDClientClose(struct LDClient *const client)
  LDBoolean
LDClientFlush(struct LDClient *const client)
  LDBoolean
LDClientIdentify(
    struct LDClient *const client, const struct LDUser *const user)
LDClientInit(struct LDConfig *const config, const unsigned int maxwaitmilli)
  LDBoolean
LDClientIsInitialized(struct LDClient *const client)
  LDBoolean
LDClientIsOffline(struct LDClient *const client)
LDClientTrack(
    struct LDClient *const client,
    const char *const key,
    const struct LDUser *const user,
    struct LDJSON *const data)
LDClientTrackMetric(
    struct LDClient *const client,
    const char *const key,
    const struct LDUser *const user,
    struct LDJSON *const data,
    const double metric)
LDCollectionDetachIter(
    struct LDJSON *const collection, struct LDJSON *const iter)
  unsigned int
LDCollectionGetSize(const struct LDJSON *const collection)
  LDBoolean
LDConfigAddPrivateAttribute(
    struct LDConfig *const config, const char *const attribute)
  void
LDConfigFree(struct LDConfig *const config)
  void
LDConfigInlineUsersInEvents(
    struct LDConfig *const config, const LDBoolean inlineUsersInEvents)
  struct LDConfig *
LDConfigNew(const char *const key)
  void
LDConfigSetAllAttributesPrivate(
    struct LDConfig *const config, const LDBoolean allAttributesPrivate)
  LDBoolean
LDConfigSetBaseURI(struct LDConfig *const config, const char *const baseURI)
  void
LDConfigSetEventsCapacity(
    struct LDConfig *const config, const unsigned int eventsCapacity)
  LDBoolean
LDConfigSetEventsURI(
    struct LDConfig *const config, const char *const eventsURI)
  void
LDConfigSetFeatureStoreBackend(
    struct LDConfig *const config, struct LDStoreInterface *const backend)
  void
LDConfigSetFeatureStoreBackendCacheTTL(
    struct LDConfig *const config, const unsigned int milliseconds)
  void
LDConfigSetFlushInterval(
    struct LDConfig *const config, const unsigned int milliseconds)
  void
LDConfigSetOffline(struct LDConfig *const config, const LDBoolean offline)
  void
LDConfigSetPollInterval(
    struct LDConfig *const config, const unsigned int milliseconds)
  void
LDConfigSetSendEvents(
    struct LDConfig *const config, const LDBoolean sendEvents)
  void
LDConfigSetStream(struct LDConfig *const config, const LDBoolean stream)
  LDBoolean
LDConfigSetStreamURI(
    struct LDConfig *const config, const char *const streamURI)
  void
LDConfigSetTimeout(
    struct LDConfig *const config, const unsigned int milliseconds)
  void
LDConfigSetUseLDD(struct LDConfig *const config, const LDBoolean useLDD)
  void
LDConfigSetUserKeysCapacity(
    struct LDConfig *const config, const unsigned int userKeysCapacity)
  void
LDConfigSetUserKeysFlushInterval(
    struct LDConfig *const config, const unsigned int milliseconds)
  LDBoolean
LDConfigSetWrapperInfo(
    struct LDConfig *const config,
    const char *const wrapperName,
    const char *const wrapperVersion)
  void LDDetailsClear(struct LDDetails *const details)
  void LDDetailsInit(struct LDDetails *const details)
  double
LDDoubleVariation(
    struct LDClient *const client,
    const struct LDUser *const user,
    const char *const key,
    const double fallback,
    bool getDetails)
  const char *
LDEvalErrorKindToString(const enum LDEvalErrorKind kind)
  const char * LDEvalReasonKindToString(const enum LDEvalReason kind)
  LDBoolean LDGetBool(const struct LDJSON *const node)
  LDBoolean LDGetBool(const struct LDJSON *const node)
  struct LDJSON * LDGetIter(const struct LDJSON *const collection)
  struct LDJSON * LDGetIter(const struct LDJSON *const collection)
  double LDGetNumber(const struct LDJSON *const node)
  double LDGetNumber(const struct LDJSON *const node)
  const char * LDGetText(const struct LDJSON *const node)
  const char * LDGetText(const struct LDJSON *const node)
  int
LDIntVariation(
    struct LDClient *const client,
    const struct LDUser *const user,
    const char *const key,
    const int fallback,
    bool getDetails)
  const char *
LDIterKey(const struct LDJSON *const iter)
  struct LDJSON *
LDIterNext(const struct LDJSON *const iter)
  LDBoolean
LDJSONCompare(
    const struct LDJSON *const left, const struct LDJSON *const right)
  struct LDJSON *
LDJSONDeserialize(const char *const text)
  struct LDJSON *
LDJSONDuplicate(const struct LDJSON *const json)
  void
LDJSONFree(struct LDJSON *const json)
  LDJSONType
LDJSONGetType(const struct LDJSON *const json)
  char *
LDJSONSerialize(const struct LDJSON *const json)
  struct LDJSON *
LDJSONVariation(
    struct LDClient *const client,
    const struct LDUser *const user,
    const char *const key,
    const struct LDJSON *const fallback,
    bool getDetails)
  struct LDJSON *
LDNewArray(void)
  struct LDJSON *
LDNewBool(const LDBoolean boolean)
  struct LDJSON *
LDNewNull(void)
  struct LDJSON *
LDNewNumber(const double number)
  struct LDJSON *
LDNewObject(void)
  struct LDJSON *
LDNewText(const char *const text)
  void
LDObjectDeleteKey(struct LDJSON *const object, const char *const key)
  struct LDJSON *
LDObjectDetachKey(struct LDJSON *const object, const char *const key)
  struct LDJSON *
LDObjectLookup(const struct LDJSON *const object, const char *const key)
  LDBoolean
LDObjectMerge(struct LDJSON *const to, const struct LDJSON *const from)
  LDBoolean
LDObjectSetKey(
    struct LDJSON *const object,
    const char *const key,
    struct LDJSON *const item)
  struct LDJSON *
LDReasonToJSON(const struct LDDetails *const details)
  LDBoolean
LDSetNumber(struct LDJSON *const node, const double number)
  char *
LDStringVariation(
    struct LDClient *const client,
    const struct LDUser *const user,
    const char *const key,
    const char *const fallback,
    bool getDetails)
  LDBoolean
LDUserAddPrivateAttribute(
    struct LDUser *const user, const char *const attribute)
  void
LDUserFree(struct LDUser *const user)
  struct LDUser *
LDUserNew(const char *const key)
  void
LDUserSetAnonymous(struct LDUser *const user, const LDBoolean anon)
  LDBoolean
LDUserSetAvatar(struct LDUser *const user, const char *const avatar)
  LDBoolean
LDUserSetCountry(struct LDUser *const user, const char *const country)
  void
LDUserSetCustom(struct LDUser *const user, struct LDJSON *const custom)
  void
LDUserSetCustomAttributesJSON(
    struct LDUser *const user, struct LDJSON *const custom)
  LDBoolean
LDUserSetEmail(struct LDUser *const user, const char *const email)
  LDBoolean
LDUserSetFirstName(struct LDUser *const user, const char *const firstName)
  LDBoolean
LDUserSetIP(struct LDUser *const user, const char *const ip)
  LDBoolean
LDUserSetLastName(struct LDUser *const user, const char *const lastName)
  LDBoolean
LDUserSetName(struct LDUser *const user, const char *const name)
  void
LDUserSetPrivateAttributes(
    struct LDUser *const user, struct LDJSON *const privateAttributes)
  LDBoolean
LDUserSetSecondary(struct LDUser *const user, const char *const secondary)



=head1 SEE ALSO

=head1 AUTHOR

Miklos Tirpak, E<lt>miklos.tirpak@emnify.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by EMnify

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
