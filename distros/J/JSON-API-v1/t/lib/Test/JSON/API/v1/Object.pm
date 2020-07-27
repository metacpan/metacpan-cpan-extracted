package Test::JSON::API::v1::Object;
use warnings;
use strict;

use Exporter qw(import);

our @EXPORT = qw(
    new_resource
    new_toplevel
    new_link
    new_error
    new_attribute
    new_relationship
    new_meta
);

sub new_resource {
    require JSON::API::v1::Resource;
    return JSON::API::v1::Resource->new(@_);
}

sub new_toplevel {
    require JSON::API::v1;
    return JSON::API::v1->new(@_);
}

sub new_link {
    require JSON::API::v1::Links;
    return JSON::API::v1::Links->new(@_);
}

sub new_error {
    require JSON::API::v1::Error;
    return JSON::API::v1::Error->new(@_);
}

sub new_attribute {
    require JSON::API::v1::Attribute;
    return JSON::API::v1::Attribute->new(@_);
}

sub new_relationship {
    require JSON::API::v1::Relationship;
    return JSON::API::v1::Relationship->new(@_);
}

sub new_meta {
    require JSON::API::v1::MetaObject;
    return JSON::API::v1::MetaObject->new(@_);
}


1;

__END__

=head1 DESCRIPTION

A testing module that has syntaxtic suger to create a new object quickly.

=head1 SYNOPSIS

    use Test::Lib;
    use Test::JSON::API::v1 # load us via the main module
    use Test::JSON::API::v1::JSON; # or load us via other means

    my $resource      = new_resource();
    my $toplevel      = new_toplevel();
    my $links         = new_link();
    my $error         = new_error();
    my $new_attribute = new_attribute();
    my $relationship  = new_relationship();
