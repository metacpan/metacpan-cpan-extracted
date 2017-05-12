package Test::Class::Hyper::Developer;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Hyper::Functions;

use File::Basename;

sub setup :Test(startup => 4) {
    use_ok 'Hyper::Singleton::Context';
    use_ok 'Hyper';
    my $base_path = Hyper::Functions::get_path_from_file(__FILE__);

    # TODO: reproduce context-setup Error
    #XXX print '__FILE__: ', __FILE__, ' $base_path: ', $base_path, "\n";

    open my $config, '<', \(my $config_scalar = <<"EOT");
[Global]
base_path=<<EOX
$base_path
EOX
template_class=Hyper::Template::HTC
namespace=TestSample

[Class]
translator=Hyper.Translator.Noop
application=Hyper.Singleton.Application

[Hyper::Application]
template=../../../var/Hyper/index.htc

[Hyper::Persistence]
cache_path=./tmp/

;[Hyper::Error]
;plain_template=../../../var/Hyper/Error/plain_error.htc
;html_template=../../../var/Hyper/Error/html_error.htc
EOT

    local $SIG{__WARN__} = sub {
        # Config::IniFiles line 522.
        return if $_[0] =~ m{\A \Qstat() on unopened filehandle\E}xms;
        warn @_;
    };
    ok( Hyper::Singleton::Context->new({
            file => $config,
        }) => 'Context setup'
    );
    ok( Hyper->new({
            service => 'none',
            usecase => 'none',
        }) => 'starting application'
    );
}

1;
