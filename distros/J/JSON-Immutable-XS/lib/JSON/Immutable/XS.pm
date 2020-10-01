package JSON::Immutable::XS;
use parent 'Export::XS';
use 5.020;
use strict;
use warnings;
use XS::Framework;

=head1 NAME

JSON::Immutable::XS

=cut

our $VERSION = '0.1.3';
XS::Loader::bootstrap();

=head1 DESCRIPTION

Fast and simple abstract node-tree based storage with JSON support. Usefull for reading JSON configs, keeping it in the memory and don't worrying about mutability. Has XPath-like interface for data accessing. Easy to use with XS and C/C++ modules.
It use RapidJSON as JSON parser. L<https://rapidjson.org/>

=cut

=head1 SYNOPSIS

    use JSON::Immutable::XS;

    # you can provide this variable to XS and use it there
    my $dict = JSON::Immutable::XS->new('example/dict.json');

    # get subnode by path ( any node is JSON::Immutable::XS ref)
    my $node = $dict->get( 'path', 2, 'node'); # similar to ->{path}[2]{node}

    # get() returns undef on not existed path
    my $data = $node->get_value('this', 'is', 'the', 'way'); # data could be an any Perl Sv structure ( scalar, hash or array )

    # unless path will found - it'll return undef
    # it possible to get keys from node as well

    for ( @{$dict->keys()} ){
    ...
    }

    # use slice to get exactly that you need without unnecessary data ( detail description below )>
    $dict->slice( 'path' );

    # see more features below

=cut

=head1 PERL INTERFACE

B<new()>
Creating of new instance. You can provide filename - it will be parsed as JSON

B<get()>
Finding a node by path (may be empty) and returning instance of node as ref 'JSON::Immutable::XS'. May be use any functions of this interface

B<get_value()>
Finding a node by path (may be empty) and returning Perl Sv. It could be Hash or Array or Scalar.

B<keys()>
Get keys of hash for node. Can use path.

B<exists()>
Checking of path existing.

B<slice()>
Get value by path for every key of hash or element of array.

B<export()>
Same as get_value() without path

=cut

=head1 AUTHOR

Vladimir Melnichenko <melnichenkovv@gmail.com>, Crazy Panda, CP Decision LTD

L<https://github.com/VMELNICHENKO/JSON-Immutable-XS>

=cut

=head1 LICENSE

You may distribute this code under the same terms as RapidJSON itself. L<https://rapidjson.org/>

=cut

1;
