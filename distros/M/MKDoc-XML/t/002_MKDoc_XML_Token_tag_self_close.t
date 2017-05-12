#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Token;

my $data  = qq |<a petal:replace="string:REPLACE" />|;
my $token = new MKDoc::XML::Token ($data);
my $node  = $token->tag_self_close();
is ($node->{_tag}, 'a');
ok (defined $node->{'petal:replace'});


1;


__END__
