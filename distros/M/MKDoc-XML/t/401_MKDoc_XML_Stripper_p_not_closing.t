#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Stripper;


# let's test this _node_to_tag business
{    
    my $stripper = new MKDoc::XML::Stripper;
    $stripper->allow (qw /p class id/);

    my $ugly = '<p class="para" style="color:red">Hello, <strong>World</strong>!</p>';
    my $neat = $stripper->process_data ($ugly);
    is ($neat, '<p class="para">Hello, World!</p>');
}


1;


__END__
