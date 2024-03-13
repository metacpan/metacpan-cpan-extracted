use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

# patch modules that hit the network, to be sure we don't do this during
# testing.

our %modules_and_responses;

{
    use HTTP::Tiny;
    package HTTP::Tiny;
    no warnings 'redefine';
    sub mirror { die "HTTP::Tiny::mirror called for $_[1]" }

    sub get ($self, $url) {
        ::note 'in monkeypatched HTTP::Tiny::get for ' . $url;
        my ($module) = reverse split('/', $url);
        return +{
            success => 1,
            status => '200',
            reason => 'OK',
            protocol => 'HTTP/1.1',
            url => $url,
            headers => {
                'content-type' => 'text/x-yaml',
            },
            content => exists $::modules_and_responses{$module} ? $::modules_and_responses{$module}
                : die "should not be checking for $module",
        };
        die 'should not be checking for ' . $module;
    }
}

sub patch_module_response (%mod_and_resp) {
    @modules_and_responses{keys %mod_and_resp} = values %mod_and_resp;
}

1;
