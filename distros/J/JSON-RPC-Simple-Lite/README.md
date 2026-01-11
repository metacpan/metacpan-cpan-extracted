# NAME

JSON::RPC::Simple::Lite - A simple and lite JSON-RPC client.

# DESCRIPTION

`JSON::RPC::Simple::Lite` provides a simple interface for JSON-RPC APIs.
It uses `HTTP::Tiny` for the backend transfer and supports all the
interfaces that library does.

# USAGE

```perl
JSON::RPC::Simple::Lite;

my $api_url = "https://www.perturb.org/api/json-rpc/";
my $opts    = { debug => 0 };
my $json    = JSON::RPC::Simple::Lite->new($api_url, $opts);

# Direct using _call()
my $resp = $json->_call($method, @params);

# OOP style using chaining and AUTOLOAD magic
my $str = $json->echo_data("Hello world!");
my $num = $json->math->sum(1, 4);

# Get the curl command for this call
my $curl_str = $json->curl_call($method, @params);
```

# FUNCTIONS

## \_call($method, @params)

Call the remote function `$method` passing it `@params`. The return value is
the response from the server.

## curl\_call($method, @params)

Returns a string that represents a command line Curl call of `$method`.
This can be useful for debugging and testing.

# OBJECT ORIENTED INTERFACE

`JSON::RPC::Simple::Lite` allows a pseudo OOP interface using AUTOLOAD.
This allows you to chain calls in different namespaces together which gets
mapped to the correct method name before calling.

```perl
$json->user->email->login($user, $pass); # Maps to method 'user.email.login'
```

This format can make your code cleaner and easier to read.

**Note:** This does require that
your final method include **some** parameter. If your function does not require
any params pass `undef` or use the explicit `_call()` method.

# DEBUG

If debug is passed in via the constructor options JSON information will be
printed to `STDOUT`.

# AUTHORS

Scott Baker - https://www.perturb.org/
