package MyStripScripts;

use strict;
use warnings FATAL => 'all';

use HTML::StripScripts::Parser();
our @ISA = qw(HTML::StripScripts::Parser);


### NOTE - When changing the values of any of these hashes, first copy the hash
###        and THEN change the values. For instance: 
###
###           my %head = %{$Context{Head}};
###           $head{meta} = 'EMPTY';
###           $Context{Head} = \%head
###
###        This will ensure that the original
###        HTML::StripScripts will still work as expected.

our (%Context,%Attrib);

### Add <meta> and <link> tags to <head>
sub init_context_whitelist {
    my ($self) = @_;
    unless (%Context) {
        %Context       = %{$self->SUPER::init_context_whitelist};
        my %head       = %{$Context{Head}};
        $head{meta}    = 'EMPTY';
        $head{link}    = 'EMPTY';
        $Context{Head} = \%head;
    }
    return \%Context;
}

### Add attributes for the <meta> and <link> tags
sub init_attrib_whitelist  {
    my ($self) = @_;
    unless (%Attrib) {
        %Attrib     = %{$self->SUPER::init_attrib_whitelist};
        $Attrib{meta} = {
            'name'          => 'word',
            'http-equiv'    => 'word',
            'content'       => 'text',
            'lang'          => 'word',
        };
        $Attrib{link} = {
            'href'          => 'href',
            'type'          => 'text',
            'rel'           => 'word',
        };
    }
    return \%Attrib;
}


1;
