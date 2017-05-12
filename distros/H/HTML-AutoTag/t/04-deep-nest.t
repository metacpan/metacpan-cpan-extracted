#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

use HTML::AutoTag;

my $auto = HTML::AutoTag->new( indent => '    ' );

is $auto->tag(
    tag => 'aaa',
    cdata => {
        tag => 'bbb',
        cdata => {
            tag => 'ccc',
            cdata => {
                tag => 'ddd',
                cdata => {
                    tag => 'eee',
                    cdata => {
                        tag => 'fff',
                        cdata => {
                            tag => 'ggg',
                            cdata => {
                                tag => 'hhh',
                                cdata => ':D',
                            }
                        }
                    }
                }
            }
        }
    }
), '<aaa>
    <bbb>
        <ccc>
            <ddd>
                <eee>
                    <fff>
                        <ggg>
                            <hhh>:D</hhh>
                        </ggg>
                    </fff>
                </eee>
            </ddd>
        </ccc>
    </bbb>
</aaa>
',
    "correct HTML";
