use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan(skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage") if $@;
plan(tests => 2);
pod_coverage_ok("Math::Complex", { trustme => [qr/^(abs|sqrt|cbrt|exp|log|sin|cos|tan|atan|atan2|Re|Im|arg|log10|logn|ln|csc|sec|cot|asin|acos|atan|acsc|asec|acot|sinh|cosh|tanh|csch|sech|coth|asinh|acosh|atanh|acsch|asech|acoth|acosec|acosech|acotan|acotanh|cosec|cosech|cotan|cotanh|cplx|cplxe|make|emake|i|root|theta|rho|new|display_format|pi|pi2|pi4|pip2|pip4)$/] });
pod_coverage_ok("Math::Trig");

