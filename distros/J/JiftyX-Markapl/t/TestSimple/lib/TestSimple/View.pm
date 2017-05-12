package TestSimple::View;
use common::sense;
use Markapl;
use JiftyX::Markapl::Helpers;

template '/hi' => sub {
    h1 { "HI" };
};

template '/hi1' => sub {
    h1 { "HI One" };

    Jifty->web->region(
        name => "hi2",
        path => "/hi2"
    );
};

template '/hi2' => sub {
    h1 { "HI Two" };
};


1;
