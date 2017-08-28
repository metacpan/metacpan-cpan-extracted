package Example::ArrayImps::Spider_v2;

use Mic;

Mic->define_class({
    interface => { 
        object => {
            crawl   => {},
            url     => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::ArrayImps::Acme::Spider',
});

package Example::ArrayImps::Acme::Spider;

use Mic::Impl
    has => { 
        URL => { property => 'url' }
    },
;

sub crawl { 
    my ($self, $e) = @_;
    sprintf 'Crawling over %s', $self->url;
}

1;
