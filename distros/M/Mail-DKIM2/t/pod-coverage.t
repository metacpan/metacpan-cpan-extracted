use strict;
use warnings;
use Test::More;
eval { require Test::Pod::Coverage; Test::Pod::Coverage->import; 1 }
    or plan skip_all => 'Test::Pod::Coverage required for testing POD coverage';

# Every public method is documented. The streaming hooks a subclass overrides
# and Perl's tie entry point are documented once, on Mail::DKIM2::HeaderParser.
# The authentication_milter handlers can only be loaded where that framework
# is installed; elsewhere they are skipped, not failed.
my $hooks = qr/^(?:PRINT|CLOSE|TIEHANDLE|init|handle_header|finish_header|finish_body|known_options)$/;
for my $module (all_modules('lib')) {
    SKIP: {
        unless (eval "require $module; 1") {
            skip "$module needs a module that is not installed here", 1
                if $@ =~ /^Can't locate (\S+)\.pm in \@INC/ && $1 !~ /^Mail\/DKIM2/;
            die $@;
        }
        pod_coverage_ok($module, { also_private => [$hooks] });
    }
}
done_testing;
