use strict;
use warnings;
use blib;

use Error ':try';
use Net::DNS::Resolver::Programmable;
use Net::DNS::RR;

use Mail::SPF::Server;
use Mail::SPF::Request;

use Test::More tests => 12;

use constant valid_macrostring_text => '%{ir}.%{v}._spf.%{d2}';
use constant valid_macrostring_expanded
                                    => '1.0.168.192.in-addr._spf.example.com';

my $test_resolver = Net::DNS::Resolver::Programmable->new(
    records         => {}
);

my $server = Mail::SPF::Server->new(
    dns_resolver    => $test_resolver
);

my $request = Mail::SPF::Request->new(
    identity        => 'foo.example.com',
    ip_address      => '192.168.0.1'
);


#### Class Compilation ####

BEGIN { use_ok('Mail::SPF::MacroString') }


#### Early Context Instantiation ####

{
    my $macrostring = eval { Mail::SPF::MacroString->new(
        text    => valid_macrostring_text,
        server  => $server,
        request => $request
    ) };

    $@ eq '' and isa_ok($macrostring, 'Mail::SPF::MacroString', 'Early-context macro-string object')
        or BAIL_OUT("Early-context macro-string instantiation failed: $@");

    # Have options been interpreted correctly?
    is($macrostring->text,      valid_macrostring_text, 'Early-context macro-string text()');

    # Expansion:
    is($macrostring->expand, valid_macrostring_expanded, 'Early-context macro-string expand()');
    is($macrostring,         valid_macrostring_expanded, 'Early-context macro-string stringify() (+overloading)');
}


#### Late Context Instantiation ####

{
    my $macrostring = eval { Mail::SPF::MacroString->new(
        text    => '%{ir}.%{v}._spf.%{d2}'
    ) };

    $@ eq '' and isa_ok($macrostring, 'Mail::SPF::MacroString', 'Late-context macro-string object')
        or BAIL_OUT("Late-context macro-string instantiation failed: $@");

    # Context-less stringify():
    is($macrostring,            valid_macrostring_text, 'Late-context macro-string context-less stringify() (+overloading)');

    # Context-less expand():
    eval { $macrostring->expand };
    isa_ok($@, 'Mail::SPF::EMacroExpansionCtxRequired', 'Late-context macro-string context-less expand() illegal');

    # Expansion with on-the-fly context:
    is($macrostring->expand($server, $request),
                            valid_macrostring_expanded, 'Late-context macro-string expand(context)');
    is($macrostring,            valid_macrostring_text, 'Late-context macro-string context-less stringify() (+overloading) after expand(context)');

    # Expansion with permanent context:
    $macrostring->context($server, $request);
    is($macrostring->expand, valid_macrostring_expanded, 'Late-context macro-string context-ful expand()');
    is($macrostring,         valid_macrostring_expanded, 'Late-context macro-string context-ful stringify() (+overloading)');
}
