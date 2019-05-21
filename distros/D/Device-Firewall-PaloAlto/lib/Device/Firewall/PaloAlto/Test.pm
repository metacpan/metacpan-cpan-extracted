package Device::Firewall::PaloAlto::Test;
$Device::Firewall::PaloAlto::Test::VERSION = '0.1.6';
use Device::Firewall::PaloAlto::Test::Rulebase;
use Device::Firewall::PaloAlto::Test::NATPolicy;

use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Test module for Palo Alto firewalls


sub new {
    my $class = shift;
    my ($fw) = @_;

    return bless { fw => $fw }, $class;
}


sub interfaces {
    my $self = shift;
    my (@test_interfaces) = @_;

    my $interfaces = $self->{fw}->op->interfaces or return;

    for my $test_int (@test_interfaces) {
        my $real_int = $interfaces->interface($test_int);

        return unless $real_int and $real_int->state eq 'up';
    }

    return 1;
}



sub arp {
    my $self = shift;
    my (@test_arp_entries) = @_;

    my $arp_entries = $self->{fw}->op->arp_table;

    for my $test_arp (@test_arp_entries) {
        my $real_arp = $arp_entries->entry($test_arp);
        return unless $real_arp and ($real_arp->status eq 'static' or $real_arp->status eq 'complete');
    }

    return 1;
}



sub rulebase {
    my $self = shift;
    my (%args) = @_;
    my %tags;

    # Some of the tags are long, so we translate between the argument to the sub ('arg') and the eventual
    # XML tag ('tag'). We also determine the default value.
    my @tag_translation = (
        { tag => 'from', default => 'any' },
        { tag => 'to', default => 'any' },
        { arg => 'src', tag => 'source', default => '' },
        { arg => 'dst', tag => 'destination', default => '' },
        { tag => 'protocol', default => 6 },
        { arg => 'port', tag => 'destination-port', default => 80 },
        { arg => 'app', tag => 'application', default => 'any' },
        { tag => 'category', default => 'any' },
        { arg => 'user', tag => 'source-user', default => 'any' },
    );

    for my $xlate (@tag_translation) {
        # The arg to the sub is either a custom value or 
        # it's the actual tag.
        my $arg = $xlate->{arg} // $xlate->{tag};

        # Set a default value if not supplied to the sub.
        $tags{ $xlate->{tag} } = $args{$arg} // $xlate->{default};
    }

    return Device::Firewall::PaloAlto::Test::Rulebase->_new(
        $self->{fw}->_send_request(type => 'op', cmd => _gen_test_xml('security-policy-match', %tags))
    );
}



sub nat_policy {
    my $self = shift;
    my (%args) = @_;
    my %tags;

    # Some of the tags are long, so we translate between the argument to the sub ('arg') and the eventual
    # XML tag ('tag'). We also determine the default value.
    my @tag_translation = (
        { tag => 'from', default => 'any' },
        { tag => 'to', default => 'any' },
        { arg => 'src_ip', tag => 'source', default => '' },
        { arg => 'dst_ip', tag => 'destination', default => '' },
        { arg => 'src_port', tag => 'source-port', default => 49152 },
        { arg => 'dst_port', tag => 'destination-port', default => 80 },
        { tag => 'protocol', default => 6 },
        { arg => 'egress_interface', tag => 'to-interface', default => undef },

    );

    for my $xlate (@tag_translation) {
        # The arg to the sub is either a custom value or 
        # it's the actual tag.
        my $arg = $xlate->{arg} // $xlate->{tag};

        # If we haven't specified the argument and the default is undef,
        # it's not mandatory and we can skip the tag
        if ( !$args{$arg} and !defined $xlate->{default} ) {
            next;
        }

        # Set a default value if not supplied to the sub.
        $tags{ $xlate->{tag} } = $args{$arg} // $xlate->{default};
    }

    return Device::Firewall::PaloAlto::Test::NATPolicy->_new(
        $self->{fw}->_send_request(type => 'op', cmd => _gen_test_xml('nat-policy-match', %tags))
    );
}



sub _gen_rulebase_test_xml {
    my (%tags) = @_;

    my $xml_doc = XML::LibXML::Document->new(); 
    my $policy_tag = $xml_doc->createElement('security-policy-match');

    for my $tag (keys %tags) {
        my $text = $xml_doc->createTextNode($tags{$tag});
        my $node = $xml_doc->createElement($tag);
        $node->appendChild($text);
        $policy_tag->appendChild($node);
    }

    my $root = $xml_doc->createElement('test');
    $root->appendChild($policy_tag);

    return $root->toString;
}

# Generates the XML for an operational test. The first argument should be the
# tag that determines the type of test, the second is a hashref with the tags and
#
sub _gen_test_xml {
    # The first argument is the tag determinging the type of test
    my $type_tag = shift;
    # The rest of the arguments is the tag name/value hash
    my %child_tags = @_;

    my $xml_doc = XML::LibXML::Document->new(); 
    my $type = $xml_doc->createElement($type_tag);

    for my $tag (keys %child_tags) {
        my $text = $xml_doc->createTextNode($child_tags{$tag});
        my $node = $xml_doc->createElement($tag);
        $node->appendChild($text);
        $type->appendChild($node);
    }

    my $root = $xml_doc->createElement('test');
    $root->appendChild($type);

    return $root->toString;
}





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Test - Test module for Palo Alto firewalls

=head1 VERSION

version 0.1.6

=head1 SYNOPSIS

    use Test::More;
    my $test = Device::Firewall::PaloAlto->new(username => 'admin', password => 'admin')->auth->test;
    ok( $test->interfaces(['ethernet1/1', 'ethernet1/2']), 'Interfaces are up' );

    # Test whether a flow would pass through the firewall
    my $result = $fw->test->rulebase(
        from => 'Trust',
        to => 'Untrust',
        source => '192.0.2.1',
        to => '203.0.113.0',
        destination-p

=head1 DESCRIPTION

This module holds methods that perform tests on the current state of the firewall.

=head1 METHODS

=head2 new

The C<new()> method can be used, but in general it's easier to call the C<test()> method from the L<Device::Firewall::PaloAlto> module.

    # Can use it in this manner
    my $fw = Device::Firewall::PaloAlto->new(username => 'admin', password => 'admin');
    $fw->auth or croak "Could not authenticate to the firewall";
    my $test = Device::Firewall::PaloAlto::Test->new($fw);

    # Generally better to use it in this manner
    my $test = Device::Firewall::PaloAlto->new(username => 'admin', password => 'admin')->auth->test or croak "Could not create test module";

=head2 interfaces

Takes a list of interface names and returns true if all interfaces are up, or false if any interfaces are down.

Returns false if the operation to retreive the interfaces fails.

    ok( $fw->test->interfaces('ethernet1/1'), 'Internet interface' );

=head2 arp

Takes a list of IP address and returns true if all of them have entries in the ARP table. Returns false if any IP does not have and entry.

ARP entries are considered valid if their state is 'static' or 'complete'.

=head2 rulebase

This function takes arguments related to a traffic flow through the firewall and determines the action the security rulebase would have taken on the flow.

It returns a L<Device::Firewall::PaloAlto::Test::Rulebase> object.

    my $result = $fw->test->rulebase(
        from => 'Trust',
        to => 'Untrust',
        src => '192.0.2.1',
        dst => '203.0.113.1',
        protocol => 6,
        port => 443,
        app => 'any',
        category => 'any',
        user => 'test\test_user'
    );

=head2 nat_policy

This function takes arguments related to a traffic flow through the firewall and determines the action the NAT rulebase would have taken on the flow.

It returns a L<Device::Firewall::PaloAlto::Test::NATPolicy> object.

    my $result = $fw->test->nat_policy(
        from => 'Trust',
        to => 'Untrust',
        src_ip => '192.0.2.1',
        dst_ip => '203.0.113.1',
        src_port => 40514,
        dst_port => 443,
        protocol => 6,
        egress_interface => 'ethernet1/1'
    );

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
