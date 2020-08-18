requires            "Log::Log4perl";
requires            "OpenTracing::GlobalTracer";

requires            "Hash::Fold";

on 'test' => sub {
    requires        "Test::Most";
    requires        "OpenTracing::Implementation::NoOp";
};

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

