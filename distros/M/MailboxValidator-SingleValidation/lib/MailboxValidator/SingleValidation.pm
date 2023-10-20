# Copyright (c) 2023 MailboxValidator.com

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

package MailboxValidator::SingleValidation;

use strict;
use vars qw(@ISA $VERSION @EXPORT);
use LWP::Simple;
use URI::Escape;
use JSON::PP;

$VERSION = '2.00';

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
	my $url = 'http://api.mailboxvalidator.com/v2/validation/single?key=' . uri_escape($self->{api_key}) . '&format=json&email=' . uri_escape($email);
	
	my $contents = get($url);
	
	if (defined($contents))
	{
		return decode_json $contents;
	}
	else
	{
		return; # error calling API
	}
}

sub DisposableEmail
{
	my ($self, $email) = @_;
	my $url = 'http://api.mailboxvalidator.com/v2/email/disposable?key=' . uri_escape($self->{api_key}) . '&format=json&email=' . uri_escape($email);
	
	my $contents = get($url);
	
	if (defined($contents))
	{
		return decode_json $contents;
	}
	else
	{
		return; # error calling API
	}
}

sub FreeEmail
{
	my ($self, $email) = @_;
	my $url = 'http://api.mailboxvalidator.com/v2/email/free?key=' . uri_escape($self->{api_key}) . '&format=json&email=' . uri_escape($email);
	
	my $contents = get($url);
	
	if (defined($contents))
	{
		return decode_json $contents;
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

Copyright (c) 2023 MailboxValidator.com

All rights reserved. This package is free software; It is licensed under MIT.

=cut
