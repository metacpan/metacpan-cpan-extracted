#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib ../lib};
use JavaScript::Minifier qw/minify/;

my $JS = get_js();
print minify(input => $JS) . "\n";

sub get_js {
return <<'END_JS';
function setup_sample_form_data() {
    var els, i, l;
    els = $$('.sample_form_data');

    for ( i = 0, l = els.length; i < l; i++ ) {
        els[i].set(
            'data-sample-form-data',
            els[i].get('data-sample-form-data').replace('\\n', "\n")
        );

        if ( els[i].get('value') == '' ) {
            els[i].set('value', els[i].get('data-sample-form-data'));
        }
        else if ( els[i].get('value') != els[i].get('data-sample-form-data') ) {
            els[i].removeClass('sample_form_data');
        }

        var funct_clear_sample_data = function() {
            var i, l, els = this.getElements('.sample_form_data');
            for ( i = 0, l = els.length; i < l; i++ ) {
                els[i].set('value', '');
            }
        }
        els[i].getParent('form').removeEvent('submit', funct_clear_sample_data );
        els[i].getParent('form').addEvent('submit', funct_clear_sample_data );

        els[i].addEvent('focus', function() {
            if ( this.get('value') == this.get('data-sample-form-data') ) {
                this.set('value', '');
                this.removeClass('sample_form_data');
            }
        });

        els[i].addEvent('blur', function() {
            if ( this.value == '' ) {
                this.set('value', this.get('data-sample-form-data'));
                this.addClass('sample_form_data');
            }
        });
    }
}
END_JS
}