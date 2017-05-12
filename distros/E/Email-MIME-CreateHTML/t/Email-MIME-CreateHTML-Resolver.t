#!/usr/local/bin/perl

#
# Unit test for Email::MIME::CreateHTML::Resolver
#
# -t Trace
# -T Deep trace
#

use strict;
use Test::Assertions::TestScript;

#Compilation
require Email::MIME::CreateHTML::Resolver;
ASSERT($INC{'Email/MIME/CreateHTML/Resolver.pm'}, "Compiled Email::MIME::CreateHTML::Resolver version $Email::MIME::CreateHTML::Resolver::VERSION");

#Try some different URLs
my $obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('http://www.bbc.co.uk/');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::LWP', 'HTTP URL');

$obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('https://ssl.bbc.co.uk/');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::LWP', 'HTTPS URL');

$obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('ftp://www.bbc.co.uk/');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::LWP', 'FTP URL');

$obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('/absolute/filepath/file.extension');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::Filesystem', 'absolute filepath');

$obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('some/filepath/file.extension');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::Filesystem', 'relative filepath');

$obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('\\server\filepath\file.extension');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::Filesystem', 'UNC filepath');

$obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('c:\some\filepath\file.extension');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::Filesystem', 'windows-style filepath');

$obj = Email::MIME::CreateHTML::Resolver->new()->_select_resolver('file://some/filepath/file.extension');
ASSERT(ref $obj eq 'Email::MIME::CreateHTML::Resolver::Filesystem', 'file URL');

#Try custom resolver
my $resolver = new UnitTestResolver;
$obj = Email::MIME::CreateHTML::Resolver->new({resolver => $resolver})->_select_resolver('http://www.bbc.co.uk/');
ASSERT(ref $obj eq 'UnitTestResolver', 'Custom resolver');

#Error checking
ASSERT(DIED(sub { Email::MIME::CreateHTML::Resolver->new()->get_resource('')}) && $@ =~ /get_resource without a URI/, "No URI");
ASSERT(DIED(sub { Email::MIME::CreateHTML::Resolver->new({resolver => 1})->_select_resolver('abc')}), "Resolver not an object");
ASSERT(DIED(sub { Email::MIME::CreateHTML::Resolver->new({resolver => new Dummy()})->_select_resolver('abc')}) && $@ =~ /resolver does not seem to use the expected interface/, "Resolver doesn't have get_resource method");
ASSERT(DIED(sub { Email::MIME::CreateHTML::Resolver->new({object_cache => new Dummy()})->_select_resolver('abc')}) && $@ =~ /object_cache does not seem to use the expected cache interface/, "Dodgy object cache");

# Dummy object for error checking
package Dummy;
sub new {
	return bless({}, shift);
}

#######################################################
#
# Trivial resource resolver for testing
#
#######################################################

package UnitTestResolver;

sub new {
	return bless({}, shift());	
}

sub get_resource {
	return ("invariant value","invariant-name","text/plain","iso8859-1");	
}

1;
