package Example::ArrayImps::Spider;

use Mic ();

Mic->assemble({
    interface => { 
        object => {
            crawl   => {},
            set_url => {},
            url     => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::ArrayImps::Acme::Spider',
});

package Example::ArrayImps::Acme::Spider;

use Mic::ArrayImpl
    has => { 
        URL => { reader => 'url', writer => 'set_url'  }
    },
;

sub crawl { 
    my ($self, $e) = @_;
    sprintf 'Crawling over %s', $self->url;
}

1;
