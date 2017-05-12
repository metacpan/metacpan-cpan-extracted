# LWP::UserAgent::Caching::Simple
Using LWP::UserAgent with a built-in Cache - speedy and simple

Wher LWP::UserAgent::Caching will have quite some features that one can use and some parameters that one can pass in, this module makes life realy simple.

just use

    my $ua = LWP::UserAgent::Caching::Simple->new;
    my $resp = $ua->GET('http://www.example.com');th
    
that's it folks

for more info, see LWP::UserAgent::Caching and HTTP::Caching itself
