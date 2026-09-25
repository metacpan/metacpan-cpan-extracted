use strict;
use warnings;

use Test::RequiresInternet 'cpan.org' => 80;
use Test::More;

# Net::DNS < 1.10 can't find nameservers on Windows when the IP is
# DHCP-assigned (fixed in Net::DNS 1.10), so mxcheck always fails there.
if ( $^O eq 'MSWin32'
    && !eval { require Net::DNS; Net::DNS->VERSION('1.10'); 1 } )
{
    plan skip_all => 'Net::DNS >= 1.10 required for mxcheck on Windows';
}

plan tests => 3;

use HTML::FormFu;

{

    my $form = HTML::FormFu->new;

    $form->element('Text')->name('foo')->constraint('Email')
        ->options('mxcheck');

    # Valid - Scalar
    {

        $form->process( { foo => 'cfranks@cpan.org' } );

        ok( $form->valid('foo'), 'foo valid - mxcheck scalar' );

    }

}

{

    my $form = HTML::FormFu->new;

    $form->element('Text')->name('foo')->constraint('Email')
        ->options( ['mxcheck'] );

    # Valid - Array
    {

        $form->process( { foo => 'djzort@cpan.org' } );

        ok( $form->valid('foo'), 'foo valid - mxcheck array' );

    }

}

{

    my $form = HTML::FormFu->new;

    $form->element('Text')->name('foo')->constraint('Email')
        ->options( { 'mxcheck' => 1 } );

    # Valid - Hash
    {

        $form->process(
            { foo => 'djzort@cpan.org', options => { 'mxcheck' => 1 } } );

        ok( $form->valid('foo'), 'foo valid - mxcheck hash' );

    }

}
