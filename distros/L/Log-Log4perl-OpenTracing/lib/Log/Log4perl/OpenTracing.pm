package Log::Log4perl::OpenTracing;

use strict;
use warnings;

our $VERSION = 'v0.1.0';

use Log::Log4perl::Layout::PatternLayout;
use OpenTracing::GlobalTracer;

use Hash::Fold qw/flatten/;

do {
    local $Log::Log4perl::ALLOW_CODE_IN_CONFIG_FILE =
        $Log::Log4perl::ALLOW_CODE_IN_CONFIG_FILE +1;
    
    Log::Log4perl::Layout::PatternLayout::add_global_cspec(
        O =>  \&get_opentracing_context_with_curlies
    );
};

sub get_opentracing_context_with_curlies {
    my ($layout, $message, $category, $priority, $caller_level) = @_;
    
    my $curlies = $layout->{curlies};
    my $context = get_opentracing_context();
    
    return flatten( $context )->{$curlies}
}

sub get_opentracing_context {
    OpenTracing::GlobalTracer->get_global_tracer->inject_context( {} );
}

1;
