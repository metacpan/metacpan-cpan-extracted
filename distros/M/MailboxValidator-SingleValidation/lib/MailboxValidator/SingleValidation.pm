# Copyright (C) 2013-2018 MailboxValidator.com
# All Rights Reserved
#
# This library is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; If not, see <http://www.gnu.org/licenses/>.

package MailboxValidator::SingleValidation;

use strict;
use vars qw(@ISA $VERSION @EXPORT);
use LWP::Simple;
use URI::Escape;
use JSON::Parse 'parse_json';

$VERSION = '1.11';

require Exporter;
@ISA = qw(Exporter);

sub Init
{
	my ($class, $apikey) = @_;
	my $self = {
		api_key  => $apikey
	};
	return bless $self, $class;
}

sub ValidateEmail
{
	my ($self, $email) = @_;
	my $url = 'http://api.mailboxvalidator.com/v1/validation/single?key=' . uri_escape($self->{api_key}) . '&format=json&email=' . uri_escape($email);
	
	my $contents = get($url);
	
	if (defined($contents))
	{
		return parse_json($contents);
	}
	else
	{
		return; # error calling API
	}
}

sub DisposableEmail
{
	my ($self, $email) = @_;
	my $url = 'http://api.mailboxvalidator.com/v1/email/disposable?key=' . uri_escape($self->{api_key}) . '&format=json&email=' . uri_escape($email);
	
	my $contents = get($url);
	
	if (defined($contents))
	{
		return parse_json($contents);
	}
	else
	{
		return; # error calling API
	}
}

sub FreeEmail
{
	my ($self, $email) = @_;
	my $url = 'http://api.mailboxvalidator.com/v1/email/free?key=' . uri_escape($self->{api_key}) . '&format=json&email=' . uri_escape($email);
	
	my $contents = get($url);
	
	if (defined($contents))
	{
		return parse_json($contents);
	}
	else
	{
		return; # error calling API
	}
}

1;

__END__

=head1 NAME

MailboxValidator::SingleValidation - Email verification module for Perl using MailboxValidator API. It validates if the email is valid, from a free provider, contains high-risk keywords, whether it's a catch-all address and so much more.

=head1 SYNOPSIS

	use MailboxValidator::SingleValidation;
	
	my $mbv = MailboxValidator::SingleValidation->Init('PASTE_YOUR_API_KEY_HERE');
	
	my $results = $mbv->ValidateEmail('example@example.com');
	
	if (!defined($results))
	{
		print "Error connecting to API.\n";
	}
	elsif ($results->{error_code} eq '')
	{
		print 'email_address = ' . $results->{email_address} . "\n";
		print 'domain = ' . $results->{domain} . "\n";
		print 'is_free = ' . $results->{is_free} . "\n";
		print 'is_syntax = ' . $results->{is_syntax} . "\n";
		print 'is_domain = ' . $results->{is_domain} . "\n";
		print 'is_smtp = ' . $results->{is_smtp} . "\n";
		print 'is_verified = ' . $results->{is_verified} . "\n";
		print 'is_server_down = ' . $results->{is_server_down} . "\n";
		print 'is_greylisted = ' . $results->{is_greylisted} . "\n";
		print 'is_disposable = ' . $results->{is_disposable} . "\n";
		print 'is_suppressed = ' . $results->{is_suppressed} . "\n";
		print 'is_role = ' . $results->{is_role} . "\n";
		print 'is_high_risk = ' . $results->{is_high_risk} . "\n";
		print 'is_catchall = ' . $results->{is_catchall} . "\n";
		print 'mailboxvalidator_score = ' . $results->{mailboxvalidator_score} . "\n";
		print 'time_taken = ' . $results->{time_taken} . "\n";
		print 'status = ' . $results->{status} . "\n";
		print 'credits_available = ' . $results->{credits_available} . "\n";
	}
	else
	{
		print 'error_code = ' . $results->{error_code} . "\n";
		print 'error_message = ' . $results->{error_message} . "\n";
	}
	
	my $results = $mbv->DisposableEmail('example@example.com');
	
	if (!defined($results))
	{
		print "Error connecting to API.\n";
	}
	elsif ($results->{error_code} eq '')
	{
		print 'email_address = ' . $results->{email_address} . "\n";
		print 'is_disposable = ' . $results->{is_disposable} . "\n";
		print 'credits_available = ' . $results->{credits_available} . "\n";
	}
	else
	{
		print 'error_code = ' . $results->{error_code} . "\n";
		print 'error_message = ' . $results->{error_message} . "\n";
	}
	
	my $results = $mbv->FreeEmail('example@example.com');
	
	if (!defined($results))
	{
		print "Error connecting to API.\n";
	}
	elsif ($results->{error_code} eq '')
	{
		print 'email_address = ' . $results->{email_address} . "\n";
		print 'is_free = ' . $results->{is_free} . "\n";
		print 'credits_available = ' . $results->{credits_available} . "\n";
	}
	else
	{
		print 'error_code = ' . $results->{error_code} . "\n";
		print 'error_message = ' . $results->{error_message} . "\n";
	}

=head1 DESCRIPTION

This Perl module provides an easy way to call the MailboxValidator API which validates if an email address is a valid one.

This module can be used in many types of projects such as:

 - validating a user's email during sign up
 - cleaning your mailing list prior to an email marketing campaign
 - a form of fraud check

Go to L<MailboxValidator API documentation page|https://www.mailboxvalidator.com/api-single-validation> for more info.

=head1 DEPENDENCIES

An API key is required for this module to function.

Go to L<MailboxValidator API plans page|https://www.mailboxvalidator.com/plans#api> to sign up for FREE API plan and you'll be given an API key.


=head1 CLASS METHODS

=over 4

=item $mbv = MailboxValidator::SingleValidation->Init('PASTE_YOUR_API_KEY_HERE');

Constructs a new MailboxValidator::SingleValidation object with the specified API key.

=back

=head1 OBJECT METHODS

=over 4

=item $results = $mbv->ValidateEmail('example@example.com');

Returns the MailboxValidator Email Validation API validation results. See L<MailboxValidator Email Validation API documentation|https://www.mailboxvalidator.com/api-single-validation> for more details.

=back

=over 4

=item $results = $mbv->DisposableEmail('example@example.com');

Returns the MailboxValidator Disposable Email API results. See L<MailboxValidator Disposable Email API documentation|https://www.mailboxvalidator.com/api-email-disposable> for more details.

=back

=over 4

=item $results = $mbv->FreeEmail('example@example.com');

Returns the MailboxValidator Free Email API results. See L<MailboxValidator Free Email API documentation|https://www.mailboxvalidator.com/api-email-free> for more details.

=back

=head1 SEE ALSO

L<MailboxValidator Website|https://www.mailboxvalidator.com>

=head1 VERSION

1.11

=head1 AUTHOR

Copyright (c) 2018 MailboxValidator.com

All rights reserved. This package is free software; It is licensed under the GPL.

=cut
