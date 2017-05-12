# $Id: AcceptLanguage.pm,v 1.8 2004/05/14 21:40:03 cgilmore Exp $
#
# Author          : Christian Gilmore
# Created On      : Wed Sep 25 17:10:19 CDT 2002
#
# PURPOSE
#     Matches language preference to available languages.
#
###############################################################################
#
# IBM Public License Version 1.0
#
# THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS IBM
# PUBLIC LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION OR
# DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF
# THIS AGREEMENT.
#
# 1. DEFINITIONS
#
# "Contribution" means:
#
#   a) in the case of International Business Machines Corporation
#   ("IBM"), the Original Program, and
#
#   b) in the case of each Contributor,
#
#   i) changes to the Program, and
#
#   ii) additions to the Program;
#
#   where such changes and/or additions to the Program originate from
#   and are distributed by that particular Contributor. A Contribution
#   'originates' from a Contributor if it was added to the Program by
#   such Contributor itself or anyone acting on such Contributor's
#   behalf. Contributions do not include additions to the Program
#   which: (i) are separate modules of software distributed in
#   conjunction with the Program under their own license agreement,
#   and (ii) are not derivative works of the Program.
#
# "Contributor" means IBM and any other entity that distributes the
# Program.
#
# "Licensed Patents " mean patent claims licensable by a Contributor
# which are necessarily infringed by the use or sale of its
# Contribution alone or when combined with the Program.
#
# "Original Program" means the original version of the software
# accompanying this Agreement as released by IBM, including source
# code, object code and documentation, if any.
#
# "Program" means the Original Program and Contributions.
#
# "Recipient" means anyone who receives the Program under this
# Agreement, including all Contributors.
#
# 2. GRANT OF RIGHTS
#
#   a) Subject to the terms of this Agreement, each Contributor hereby
#   grants Recipient a non-exclusive, worldwide, royalty-free
#   copyright license to reproduce, prepare derivative works of,
#   publicly display, publicly perform, distribute and sublicense the
#   Contribution of such Contributor, if any, and such derivative
#   works, in source code and object code form.
#
#   b) Subject to the terms of this Agreement, each Contributor hereby
#   grants Recipient a non-exclusive, worldwide, royalty-free patent
#   license under Licensed Patents to make, use, sell, offer to sell,
#   import and otherwise transfer the Contribution of such
#   Contributor, if any, in source code and object code form. This
#   patent license shall apply to the combination of the Contribution
#   and the Program if, at the time the Contribution is added by the
#   Contributor, such addition of the Contribution causes such
#   combination to be covered by the Licensed Patents. The patent
#   license shall not apply to any other combinations which include
#   the Contribution. No hardware per se is licensed hereunder.
#
#   c) Recipient understands that although each Contributor grants the
#   licenses to its Contributions set forth herein, no assurances are
#   provided by any Contributor that the Program does not infringe the
#   patent or other intellectual property rights of any other entity.
#   Each Contributor disclaims any liability to Recipient for claims
#   brought by any other entity based on infringement of intellectual
#   property rights or otherwise. As a condition to exercising the
#   rights and licenses granted hereunder, each Recipient hereby
#   assumes sole responsibility to secure any other intellectual
#   property rights needed, if any. For example, if a third party
#   patent license is required to allow Recipient to distribute the
#   Program, it is Recipient's responsibility to acquire that license
#   before distributing the Program.
#
#   d) Each Contributor represents that to its knowledge it has
#   sufficient copyright rights in its Contribution, if any, to grant
#   the copyright license set forth in this Agreement.
#
# 3. REQUIREMENTS
#
# A Contributor may choose to distribute the Program in object code
# form under its own license agreement, provided that:
#
#   a) it complies with the terms and conditions of this Agreement;
#
# and
#
#   b) its license agreement:
#
#   i) effectively disclaims on behalf of all Contributors all
#   warranties and conditions, express and implied, including
#   warranties or conditions of title and non-infringement, and
#   implied warranties or conditions of merchantability and fitness
#   for a particular purpose;
#
#   ii) effectively excludes on behalf of all Contributors all
#   liability for damages, including direct, indirect, special,
#   incidental and consequential damages, such as lost profits;
#   iii) states that any provisions which differ from this Agreement
#   are offered by that Contributor alone and not by any other party;
#   and
#
#   iv) states that source code for the Program is available from such
#   Contributor, and informs licensees how to obtain it in a
#   reasonable manner on or through a medium customarily used for
#   software exchange.
#
# When the Program is made available in source code form:
#
#   a) it must be made available under this Agreement; and
#
#   b) a copy of this Agreement must be included with each copy of the
#   Program.
#
# Each Contributor must include the following in a conspicuous
# location in the Program:
#
#   Copyright © {date here}, International Business Machines
#   Corporation and others. All Rights Reserved.
#
# In addition, each Contributor must identify itself as the originator
# of its Contribution, if any, in a manner that reasonably allows
# subsequent Recipients to identify the originator of the
# Contribution.
#
# 4. COMMERCIAL DISTRIBUTION
#
# Commercial distributors of software may accept certain
# responsibilities with respect to end users, business partners and
# the like. While this license is intended to facilitate the
# commercial use of the Program, the Contributor who includes the
# Program in a commercial product offering should do so in a manner
# which does not create potential liability for other Contributors.
# Therefore, if a Contributor includes the Program in a commercial
# product offering, such Contributor ("Commercial Contributor") hereby
# agrees to defend and indemnify every other Contributor ("Indemnified
# Contributor") against any losses, damages and costs (collectively
# "Losses") arising from claims, lawsuits and other legal actions
# brought by a third party against the Indemnified Contributor to the
# extent caused by the acts or omissions of such Commercial
# Contributor in connection with its distribution of the Program in a
# commercial product offering. The obligations in this section do not
# apply to any claims or Losses relating to any actual or alleged
# intellectual property infringement. In order to qualify, an
# Indemnified Contributor must: a) promptly notify the Commercial
# Contributor in writing of such claim, and b) allow the Commercial
# Contributor to control, and cooperate with the Commercial
# Contributor in, the defense and any related settlement negotiations.
# The Indemnified Contributor may participate in any such claim at its
# own expense.
#
# For example, a Contributor might include the Program in a commercial
# product offering, Product X. That Contributor is then a Commercial
# Contributor. If that Commercial Contributor then makes performance
# claims, or offers warranties related to Product X, those performance
# claims and warranties are such Commercial Contributor's
# responsibility alone. Under this section, the Commercial Contributor
# would have to defend claims against the other Contributors related
# to those performance claims and warranties, and if a court requires
# any other Contributor to pay any damages as a result, the Commercial
# Contributor must pay those damages.
#
# 5. NO WARRANTY
#
# EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE PROGRAM IS
# PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION,
# ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT,
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Each Recipient
# is solely responsible for determining the appropriateness of using
# and distributing the Program and assumes all risks associated with
# its exercise of rights under this Agreement, including but not
# limited to the risks and costs of program errors, compliance with
# applicable laws, damage to or loss of data, programs or equipment,
# and unavailability or interruption of operations.
#
# 6. DISCLAIMER OF LIABILITY
#
# EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, NEITHER RECIPIENT
# NOR ANY CONTRIBUTORS SHALL HAVE ANY LIABILITY FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING WITHOUT LIMITATION LOST PROFITS), HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OR DISTRIBUTION OF THE PROGRAM OR THE EXERCISE OF ANY RIGHTS
# GRANTED HEREUNDER, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGES.
#
# 7. GENERAL
#
# If any provision of this Agreement is invalid or unenforceable under
# applicable law, it shall not affect the validity or enforceability
# of the remainder of the terms of this Agreement, and without further
# action by the parties hereto, such provision shall be reformed to
# the minimum extent necessary to make such provision valid and
# enforceable.
#
# If Recipient institutes patent litigation against a Contributor with
# respect to a patent applicable to software (including a cross-claim
# or counterclaim in a lawsuit), then any patent licenses granted by
# that Contributor to such Recipient under this Agreement shall
# terminate as of the date such litigation is filed. In addition, If
# Recipient institutes patent litigation against any entity (including
# a cross-claim or counterclaim in a lawsuit) alleging that the
# Program itself (excluding combinations of the Program with other
# software or hardware) infringes such Recipient's patent(s), then
# such Recipient's rights granted under Section 2(b) shall terminate
# as of the date such litigation is filed.
#
# All Recipient's rights under this Agreement shall terminate if it
# fails to comply with any of the material terms or conditions of this
# Agreement and does not cure such failure in a reasonable period of
# time after becoming aware of such noncompliance. If all Recipient's
# rights under this Agreement terminate, Recipient agrees to cease use
# and distribution of the Program as soon as reasonably practicable.
# However, Recipient's obligations under this Agreement and any
# licenses granted by Recipient relating to the Program shall continue
# and survive.
#
# IBM may publish new versions (including revisions) of this Agreement
# from time to time. Each new version of the Agreement will be given a
# distinguishing version number. The Program (including Contributions)
# may always be distributed subject to the version of the Agreement
# under which it was received. In addition, after a new version of the
# Agreement is published, Contributor may elect to distribute the
# Program (including its Contributions) under the new version. No one
# other than IBM has the right to modify this Agreement. Except as
# expressly stated in Sections 2(a) and 2(b) above, Recipient receives
# no rights or licenses to the intellectual property of any
# Contributor under this Agreement, whether expressly, by implication,
# estoppel or otherwise. All rights in the Program not expressly
# granted under this Agreement are reserved.
#
# This Agreement is governed by the laws of the State of New York and
# the intellectual property laws of the United States of America. No
# party to this Agreement will bring a legal action under this
# Agreement more than one year after the cause of action arose. Each
# party waives its rights to a jury trial in any resulting litigation.
#
###############################################################################


# Package name
package I18N::AcceptLanguage;


# Required packages
use 5.006001;
use strict;
use warnings;
use vars qw($VERSION);


# Global variables
$VERSION = '1.04';


###############################################################################
###############################################################################
# new: class object initialization
###############################################################################
###############################################################################
sub new {
  my $self = shift;
  my $type = ref($self) || $self;
  my $obj = bless {}, $type;
  my %arg = @_;

  $obj->debug($arg{debug} || 0);
  $obj->defaultLanguage($arg{defaultLanguage} || '');
  defined $arg{strict} ? $obj->strict($arg{strict}) : $obj->strict(1);

  return $obj;
}

###############################################################################
###############################################################################
# debug: get/set method for debug messages
###############################################################################
###############################################################################
sub debug {
  my $acceptor = shift;

  $acceptor->{debug} = shift if @_;
  return $acceptor->{debug};
}

###############################################################################
###############################################################################
# defaultLanguage: get/set method for the server default language
###############################################################################
###############################################################################
sub defaultLanguage {
  my $acceptor = shift;

  $acceptor->{defaultLanguage} = shift if @_;
  return $acceptor->{defaultLanguage};
}

###############################################################################
###############################################################################
# strict: get/set method for strict protocol conformance
###############################################################################
###############################################################################
sub strict {
  my $acceptor = shift;

  $acceptor->{strict} = shift if @_;
  return $acceptor->{strict};
}

###############################################################################
###############################################################################
# accepts: determines what the highest priority commonly known language
#   between client and server is.
###############################################################################
###############################################################################
sub accepts {
  my ($acceptor, $clientPreferences, $supportedLanguages) = @_;

  # Basic sanity check
  if (not $clientPreferences or ref($supportedLanguages) ne 'ARRAY') {
    return $acceptor->defaultLanguage();
  }

  # There should be no whitespace anways, but a cleanliness/sanity check
  $clientPreferences =~ s/\s//g;
  print "Client preferences are $clientPreferences\n" if $acceptor->debug();

  # Prepare the list of client-acceptable languages
  my @languages = ();
  foreach my $tag (split(/,/, $clientPreferences)) {
    my ($language, $quality) = split(/\;/, $tag);
    $quality =~ s/^q=//i if $quality;
    $quality = 1 unless $quality;
    next if $quality <= 0;
    # We want to force the wildcard to be last
    $quality = 0 if ($language eq '*');
    # Pushing lowercase language here saves processing later
    push(@languages, { quality => $quality,
		       language => $language,
		       lclanguage => lc($language) });
  }

  # Prepare the list of server-supported languages
  my %supportedLanguages = ();
  my %secondaryLanguages = ();
  foreach my $language (@$supportedLanguages) {
    print "Added language $language (lower-cased) to supported hash\n"
      if $acceptor->debug();
    $supportedLanguages{lc($language)} = $language;
    if ($language =~ /^([^-]+)-?/) {
      print "Added language $1 (lower-cased) to secondary hash\n"
	if $acceptor->debug();
      $secondaryLanguages{lc($1)} = $language;
    }
  }

  # Reverse sort the list, making best quality at the front of the array
  @languages = sort { $b->{quality} <=> $a->{quality} } @languages;

  my $secondaryMatch = '';
  foreach my $tag (@languages) {
    print "Matching ", $tag->{lclanguage}, "\n" if $acceptor->debug();
    if (exists($supportedLanguages{$tag->{lclanguage}})) {
      # Client en-us eq server en-us
      print "Returning language ", $supportedLanguages{$tag->{language}}, "\n"
	if $acceptor->debug();
      return $supportedLanguages{$tag->{language}}
	if exists($supportedLanguages{$tag->{language}});
      return $supportedLanguages{$tag->{lclanguage}};
    } elsif (exists($secondaryLanguages{$tag->{lclanguage}})) {
      # Client en eq server en-us
      print "Returning language ", $secondaryLanguages{$tag->{language}}, "\n"
	if $acceptor->debug();
      return $secondaryLanguages{$tag->{language}}
	if exists($secondaryLanguages{$tag->{language}});
      return $supportedLanguages{$tag->{lclanguage}};
    } elsif (!($acceptor->strict()) &&
	     $tag->{lclanguage} =~ /^([^-]+)-/ &&
	     exists($secondaryLanguages{$1}) &&
	     $secondaryMatch eq '') {
      # Client en-gb eq server en-us
      print "Setting supported secondaryMatch of $1 for ", $tag->{lclanguage}, "\n"
	if $acceptor->debug();
      $secondaryMatch = $secondaryLanguages{$1};
    } elsif ($tag->{lclanguage} =~ /^([^-]+)-/ &&
	     exists($secondaryLanguages{$1}) &&
	     $secondaryMatch eq '') {
      # Client en-us eq server en
      print "Setting secondary secondaryMatch of $1 for ", $tag->{lclanguage}, "\n"
	if $acceptor->debug();
      $secondaryMatch = $supportedLanguages{$1};
    } elsif ($tag->{lclanguage} eq '*') {
      # * matches every language not already specified.
      # It doesn't care which we pick, so let's pick the default,
      # if available, then the first in the array.
      print "Setting default for *\n" if $acceptor->debug();
      return $acceptor->defaultLanguage() if $acceptor->defaultLanguage();
      return $supportedLanguages->[0];
    }
  }

  # No primary matches. Secondary? (ie, en-us requested and en supported)
  print "Testing for secondaryMatch\n" if $acceptor->debug();
  return $secondaryMatch if $secondaryMatch;

  # No matches. Let's return the default, if set.
  print "Returning default, if any\n" if $acceptor->debug();
  return $acceptor->defaultLanguage();
}

1;

__END__

###############################################################################
###############################################################################
# Documentation - try 'pod2text AcceptLanguage.pm'
###############################################################################
###############################################################################

=head1 NAME

I18N::AcceptLanguage - Matches language preference to available
languages

=head1 SYNOPSIS

  use I18N::AcceptLanguage;

  my $supportedLanguages = [( 'en-us', 'fr' )];

  my $acceptor = I18N::AcceptLanguage->new();
  my $language = $acceptor->accepts($ENV{HTTP_ACCEPT_LANGUAGE},
                                    $supportedLanguages);

=head1 DESCRIPTION

B<I18N::AcceptLanguage> matches language preference to available
languages per rules defined in RFC 2616, section 14.4: HTTP/1.1 -
Header Field Definitions - Accept-Language.

=head1 PUBLIC METHODS

=over 2

=item accepts( CLIENT_PREFERENCES, SUPPORTED_LANGUAGES )

Returns the highest priority common language between client and
server. If no common language is found, the defaultLanguage is
returned. If defaultLanuage is also not set, an empty string is
returned. The method expects two arguments:

=over 2

=item CLIENT_PREFERENCES

A string in the same format defined in RFC 2616, quoted here:

  1#( ( ( 1*8ALPHA *( "-" 1*8ALPHA ) ) | "*" ) [ "'" "q" "=" qvalue ] )

Examples:

  da, en-gb;q=0.8, en;q=0.7

  en-us, ja, *

=item SUPPORTED_LANGUAGES

A reference to a list of language ranges supported by the server.

=back

=item new( [ OPTIONS ] )

Returns a new I18N::AcceptLanguage object. The method accepts the
following key/value pair options:

=over 2

=item debug

A boolean set to either 0 or 1. When set to 1, debug messages will be
printed to STDOUT. The value of debug defaults to 0.

=item defaultLanguage

A string representing the server's default language choice. The value
of defaultLanguage defaults to an empty string.

=item strict

A boolean set to either 0 or 1. When set to 1, the software strictly
conforms to the protocol specification. When set to 0, the software
will perform a secondary, aggressive language match regardless of
country (ie, a client asking for only en-gb will get back en-us if the
server does not accept en-gb or en but does accept en-us). The last
matching language in the supported languages list will be chosen. The
value of strict defaults to 1.

=back

=back

=head1 PRIVATE METHODS

=over 2

=item debug( [ BOOLEAN ] )

A get/set method that returns the value of debug, set by the optional
method argument.

=item defaultLanguage( [ LANGUAGE ] )

A get/set method that returns the value of defaultLanguage, set by the
optional method argument.

=item strict( [ BOOLEAN ] )

A get/set method that returns the value of strict, set by the optional
method argument.

=back

=head1 NOTES

=over 2

=item Case Sensitivity

Language matches are done in a case-insensitive manner but results are
case-sensitive to the value found in the SUPPORTED_LANGUAGES list.

=back

=head1 AVAILABILITY

This module is available on CPAN worldwide and requires perl version
5.6.1 or higher be installed.

=head1 AUTHORS

Christian Gilmore <cag@us.ibm.com>

=head1 SEE ALSO

RFC 2616

=head1 COPYRIGHT

Copyright (C) 2003, 2004 International Business Machines Corporation
and others. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of the IBM Public License.

=cut
