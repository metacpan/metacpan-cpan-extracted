requires perl => '5.010000';

# Common
requires 'Text::Shorten';
requires 'JSON';
requires 'Module::Runtime';
requires 'Data::OptList';
requires 'Mouse';
requires 'Log::Pony';

# Provider::IRC
requires 'AnyEvent::IRC::Client';

# Provider::Lingr
requires 'Plack';
requires 'Twiggy';

# Handler::URLFetcher
requires 'Furl';
requires 'HTTP::Response::Encoding';
requires 'HTML::Entities';

# Handler::LLEval
requires 'URI::Escape';

# Handler::PerldocJP
requires 'Pod::PerldocJp';

# Handler::Karma
requires 'DB_File';

on 'test' => sub {
    requires 'Test::AllModules';
};
