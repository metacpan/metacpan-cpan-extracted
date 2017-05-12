---
tags: release
title: Release v0.009
---

This release basically rewrites the inner workings of Mercury with no
changes to its functionality. Mercury is now divided into a few
different parts:

1. The [Mercury broker](/pod/mercury) which is a standalone application
   providing a message broker over WebSockets.
2. Mercury::Controller classes which establish WebSocket connections
   allow you to build a custom message broker using
   [Mojolicious](http://mojolicious.org) and
   [Mojolicious::Plugin::Mercury](/pod/Mojolicious/Plugin/Mercury).
   Your custom broker can add authentication, logging, access control,
   and other features.
3. Mercury::Pattern classes which allow you to build your own messaging
   patterns. This includes combining existing patterns to have a job
   queue that also sends event notifications, for example. See
   [Mojolicious::Plugin::Mercury](/pod/Mojolicious/Plugin/Mercury) for
   more details.

This new architecture should make it easy to enhance Mercury with new
features, and to add it into your own application.

There are still lots of features I want to add to the broker, including
administrative APIs, pluggable authentication, and access control. If
you'd like to help, [join us on irc.perl.org #statocles](https://chat.mibbit.com/?channel=%23statocles&server=irc.perl.org).

Full changelog inside...

---

* [add documentation for the new architecture](https://github.com/preaction/Mercury/commit/0cdbde144ac0ace07e61d4eb12f99f40755071b0)
* [move bus pattern into controller/pattern object](https://github.com/preaction/Mercury/commit/b1ef48ceb3dd9611d30c5ee282551ed312158e87) ([#34](https://github.com/preaction/Mercury/issues/34))
* [move cascading pub/sub into controller](https://github.com/preaction/Mercury/commit/1b4b5c8e78d355260d25d29d1bb07d391ba9ade2) ([#34](https://github.com/preaction/Mercury/issues/34))
* [add simple pubsub controller and pattern](https://github.com/preaction/Mercury/commit/108c2eebeb68342002d0316a604a2a7d6e84403b) ([#34](https://github.com/preaction/Mercury/issues/34))
* [refactor push/pull into composable parts](https://github.com/preaction/Mercury/commit/38ea8f2fe46b3bcfe0f7a4040048db38cecb7953) ([#34](https://github.com/preaction/Mercury/issues/34))
