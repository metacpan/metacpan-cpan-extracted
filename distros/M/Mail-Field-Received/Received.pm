#!/usr/bin/perl -w
#
# Mail::Field::Received --
#   mostly RFC822-compliant parser of Received headers
#
# Copyright (c) 2000 Adam Spiers <adam@spiers.net>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Received.pm,v 1.28 2003/03/17 23:45:17 adams Exp $
#

require 5.005;

package Mail::Field::Received;

use strict;

use Mail::Field ();
use Carp;

use vars qw($VERSION @ISA @EXPORT_OK);
@ISA = qw(Exporter Mail::Field Mail::Field::Generic);
@EXPORT_OK = qw(%RC &diagnose);

$VERSION = '0.26';

=head1 NAME

Mail::Field::Received -- mostly RFC822-compliant parser of Received headers

=head1 SYNOPSIS

  use Mail::Field;

  my $received = Mail::Field->new('Received', $header);
  my $results = $received->parse_tree();
  my $parsed_ok = $received->parsed_ok();
  my $diagnostics = $received->diagnostics();

=head1 DESCRIPTION

I<Don't use this class directly!>  Instead ask Mail::Field for new
instances based on the field name!

Mail::Field::Received provides subroutines for parsing Received
headers from e-mails.  It mostly complies with RFC822, but deviates to
accomodate a number of broken MTAs which are in common use.  It also
attempts to extract useful information which MTAs often embed within
the C<(comments)>.

It is a subclass derived from the Mail::Field and Mail::Field::Generic
classes.

=head1 ROUTINES

=over 4

=cut

INIT: {
  bless([])->register('Received');
}

##

=item * B<debug>

Returns current debugging level obtained via the C<diagnostics> method.
If a parameter is given, the debugging level is changed.  The default
level is 3.

=cut

my $debug = 3;

sub debug {
  my $self = shift;
  if (@_) {
    $debug = shift;
  }
  return $debug;
}

##

=item * B<diagnose>

  $received->diagnose("foo", "\n");

Appends stuff to the parser's diagnostics buffer.

=cut

sub diagnose {
  my $self = shift;
  my (@msgs) = @_;
  $self->{Diags} .= join '', @msgs;
}

=item * B<diagnostics>

  my $diagnostics = $received->diagnostics();

Returns the contents of the parser's diagnostics buffer.

=cut

sub diagnostics {
  my $self = shift;
  return $self->{Diags} || '';
}

##

# Here be all the roughly (!) RFC822-compliant regexps.  They
# sometimes deviate from RFC822 to allow for many common MTAs which
# don't comply either.
#
# N.B. we need lots of butt-ugly extra ()s to avoid a nasty bug with
# (?-x:) in many recent Perls (fixed by 5.005_63 it seems, maybe earlier).

use vars qw(%RC);
%RC = ();

# Atoms consist of all CHARs except SPACE, CTLs, and SPECIALs.
$RC{atom}        = qr/(?:[\041\043-\047\052\053\055-\071\075\077\101-\132\136-\176]+)/;

$RC{ctext}       = qr/[\000-\014\016-\047\052-\133\135-\177]/;
$RC{dtext}       = qr/[\000-\014\016-\132\136-\177]/;
$RC{quoted_pair} = qr/(?:\\[\000-\177])/;
$RC{qtext}       = qr/[\000-\014\016-\041\043-\133\135-\177]/;
$RC{quoted_str}  = qr/(?:"(?:$RC{qtext}|$RC{quoted_pair})*")/;

# Comments can be arbitrarily nested but I can't be bothered to
# support that here; it's too much effort and no-one will nest more than
# once ... I hope!
$RC{comment_base}= qr/(\((?:$RC{ctext}|$RC{quoted_pair})*\))/;
$RC{comment}     = qr/(\((?:$RC{ctext}|$RC{quoted_pair}|$RC{comment_base})*\))/;

$RC{word}        = qr/(?:$RC{atom}|$RC{quoted_str})/;
$RC{words}       = qr/($RC{atom}(\s+$RC{atom})*|$RC{quoted_str})/;

# ' 1' isn't 2DIGIT according to RFC822 but some MTAs use it anyway
$RC{TWO_DIGIT}   = qr/((?:\d|(?<= )| )\d)/;
 
# This could be improved upon.  I left the common triples in, even 
# though [A-Z]{3} makes them redundant.
$RC{zone_name}   = qr/(UT|GMT|[CEMPW][DES]T|[A-Z]|[A-Z]{3})/;

$RC{zone}        = qr/(
                       ([+-]?[01]\d(?:00|15|30|45))(?:
                         )(?:\s(?:$RC{zone_name}|\($RC{zone_name}\)))?
                       |
                        (?:$RC{zone_name})(?:
                      ))/x;
$RC{hms}         = qr/($RC{TWO_DIGIT}:(\d\d)(?::(\d\d))?)/;
# Note: case-insensitivity is not RFC-compliant here, but some MTAs
# write days/months in all lower case.
$RC{month}       = qr/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/i;
$RC{week_day}    = qr/(Mon|Tue|Wed|Thu|Fri|Sat|Sun)/i;
$RC{year}        = qr/((?:19|20)?\d{2}|100)/;  # god-DAMN the incompetence!
$RC{year_day1}   = qr/(?:$RC{TWO_DIGIT}\s$RC{month})/;
$RC{year_day2}   = qr/(?:$RC{month}\s$RC{TWO_DIGIT})/;
$RC{day_of_year} = qr/(?:$RC{year_day1}|$RC{year_day2})/;
$RC{date_time1}  = qr/(?:$RC{hms}\s+$RC{year}\s+(?:$RC{zone})?)/;
$RC{date_time2}  = qr/(?:$RC{hms}\s+$RC{zone}\s+$RC{year})/;
$RC{date_time3}  = qr/(?:$RC{year}\s+$RC{hms}\s+(?:$RC{zone})?)/;
$RC{date_time}   = qr/(
                       (?: $RC{week_day} ,? \s* )?
                       ($RC{day_of_year}) \s+
                       ($RC{date_time1}|$RC{date_time2}|$RC{date_time3})
                      )/x;

$RC{ipv4_addr}   = qr/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
# check valid with inet_aton()

$RC{domain_lit}  = qr/(?:\[(?:$RC{dtext}|$RC{quoted_pair})*\])/;
$RC{sub_domain}  = qr/(?:$RC{atom}|$RC{domain_lit})/;
$RC{domain}      = qr/(?:$RC{sub_domain}(?:\.$RC{sub_domain})*)/;
$RC{local_part}  = qr/(?:$RC{word}(?:\.$RC{word})*)/;

# This is the RFC822 addr-spec ...
$RC{addr_spec}   = qr/($RC{local_part})\@($RC{domain})/;

# ... but many MTAs are non-compliant:
$RC{addr_spec2}  = qr/($RC{local_part})(?:\@($RC{domain}))?/;
$RC{addr_spec3}  = qr/$RC{addr_spec2}|($RC{domain})/;
$RC{addr_spec4}  = qr/((?:$RC{words}\s+)?<$RC{addr_spec3}>|$RC{addr_spec3})
                      (?:,\s?\.\.\.)?/x;
$RC{addr_spec5}  = qr/(?:(?:($RC{local_part})\@)?($RC{domain}))/;

# RFC822 dictates that msg-id is "<" addr-spec ">" but in practice
# many MTAs do not adhere to this for the "id" part of Received headers.
$RC{msg_id}      = qr/(<$RC{addr_spec2}>|\#?[\w\.-]+)/;

$RC{from1}   = qr/((?i:from) \s+     (<$RC{addr_spec}>))/x;
$RC{from2}   = qr/((?i:from) \s+      ($RC{addr_spec5})?)/x;
$RC{by}      = qr/((?i:by)   \s+      ($RC{domain}))/x;
$RC{via}     = qr/((?i:via)  \s+      ($RC{atom}))/x;
$RC{with}    = qr/((?i:with) \s       ($RC{atom})?)/x; # sometimes empty atom
$RC{id}      = qr/((?i:id)   \s+       $RC{msg_id}(?::(\d+))?)/x;
$RC{for}     = qr/((?i:for)  \s+       $RC{addr_spec4})/x;
$RC{sent_by} = qr/((?i:sent \s by) \s+ $RC{addr_spec4})/x;
$RC{convert} = qr/((?i:convert) \s+   ($RC{atom}))/x;

##

sub set {
  my $self = shift;
  return $self;
}

##

=item * B<parse>

The actual parser.  Returns the object (Mail::Field barfs otherwise).

=cut

sub parse {
  my ($self, $recv) = @_;

  $self->{Text} = $recv;
  $self->{Diags} = '';

  my %parsed = (whole => $recv);

  # \234 sometimes crops up for some unknown reason.  Huh?!
  $recv =~ tr/\234//d;

  # From RFC822:
  #     received    =  "Received"    ":"            ; one per relay
  #                       ["from" domain]           ; sending host
  #                       ["by"   domain]           ; receiving host
  #                       ["via"  atom]             ; physical path
  #                      *("with" atom)             ; link/mail protocol
  #                       ["id"   msg-id]           ; receiver msg id
  #                       ["for"  addr-spec]        ; initial form
  #                        ";"    date-time         ; time received
  #
  # Sadly many many MTAs are broken, however, so we have to deal with
  # a lot of special cases.  Improvements to this section are very welcome.

  my %expecting = map { $_ => 1 }
                      (qw/from by via with id convert for sent_by date_time/);

  for ($recv) {
    my $last_section = '';

   TOKEN:
    while (1) {
      $self->diagnose("---- Expecting: ", (join ' ', sort keys %expecting),
                      "\n") if $debug >= 5;
      $self->diagnose("---- Last section: $last_section\n")
        if $debug >= 6;

      if (/\G$RC{comment}/cg) {
        my $comment = $1;
        $self->diagnose("Got comment $comment\n") if $debug >= 4;

        push @{$parsed{$last_section}{comments}}, $comment
          if $last_section;
        push @{$parsed{comments}}, $comment;

        if ($last_section eq 'from') {
         FROMCOMMENT:
          {
            if ($comment =~ /\(
                                (?:(?:($RC{local_part})\@)?($RC{domain})\s+)?
                                (?:\[ $RC{ipv4_addr} \])(?:
                            )\)/x)
            {
              if ($1) {
                $self->diagnose("Got `from' ident in comments: $1\n")
                  if $debug >= 3;
                $parsed{from}{ident} = $1;
              }

              if ($2) {
                $self->diagnose("Got `from' domain in comments: $2\n")
                  if $debug >= 3;
                $parsed{from}{domain} = $2;
              }

              if ($3) {
                $self->diagnose("Got `from' IP address in comments: $3\n")
                  if $debug >= 3;
                $parsed{from}{address} = $3;
              }

              last FROMCOMMENT;
            }

            if ($comment =~ /(HELO|EHLO)(?:\s+|=)($RC{domain})/i) {
              # HELO domain is in comments, not outside, so swap
              $self->diagnose("Got `from' $1 domain in comments: $2\n")
                if $debug >= 3;
              @{$parsed{from}}{qw/domain HELO/}
                = ($parsed{from}{HELO}, $2);
            }

            if ($comment =~ /$RC{ipv4_addr}\]?(?::(\d{1,5}))?/) {
              $self->diagnose("Got `from' IP address in comments: $1\n")
                if $debug >= 3;

              $parsed{from}{address} = $1;

              if ($2) {
                $parsed{from}{port} = $2;
                $self->diagnose("Got `from' port in comments: $1\n")
                  if $debug >= 3;
              }
            }
          }
          $parsed{from}{whole} .= " $comment\n";
        }

        next TOKEN;
      }
      
      if (/\G(\s+)/cg) {
        $self->diagnose("Got whitespace: <$1>\n") if $debug >= 7;
        next TOKEN;
      }
      
      if ($expecting{from} and /\G$RC{from1}/cg) {
        print map { ($_ || '__undef__') . "\n---\n" } $1, $2, $3, $4, $5, $6;
        $self->diagnose("Got from type1: $1\n") if $debug >= 2;
        $last_section = 'from';
        
        $parsed{from}{whole} = $1;
        $parsed{from}{from}  = $2;
        $parsed{from}{ident} = $3 if $3;
        $parsed{from}{HELO}  = $4;

        delete $expecting{from};
        delete @expecting{grep /^after_/, keys %expecting};
        $expecting{after_from}++;
        next TOKEN;
      }
      
      if ($expecting{from} and /\G$RC{from2}/cg) {
        $self->diagnose("Got from type2: $1\n") if $debug >= 2;
        $last_section = 'from';

        $parsed{from}{whole} = $1;
        $parsed{from}{from}  = $2;
        $parsed{from}{ident} = $3 if $3;
        $parsed{from}{HELO}  = $4;

        delete $expecting{from};
        delete @expecting{grep /^after_/, keys %expecting};
        $expecting{after_from}++;
        next TOKEN;
      }
      
      if ($expecting{after_from} and /\G($RC{domain_lit})/cg) {
        $self->diagnose("Got address from bad `from': $1\n") if $debug >= 3;
        $parsed{from}{address} = $1;
        delete $expecting{after_from};
        next TOKEN;
      }

      if ($expecting{after_from} and $parsed{from}{whole} eq 'from mail' and
          /\G(pickup service)/cg) {
        $self->diagnose("Got bad `from': appending: $1\n")
          if $debug >= 3;
        $parsed{from}{whole} .= $1;
        delete $expecting{after_from};
        next TOKEN;
      }

      # Deal with incompetence from the fucking /imbeciles/ at M$.
      if ($expecting{after_from} and $parsed{whole} =~ /Microsoft SMTPSVC/ and
          /\G-\s+$RC{ipv4_addr}/cg) {
        $self->diagnose("Got IP from bad M\$ from: $1\n") if $debug >= 3;
        $parsed{from}{address} = $1;
        delete $expecting{after_from};
        next TOKEN;
      }

      if ($expecting{after_from} and /\G, claiming to be ($RC{word})/cg) {
        $self->diagnose("Got HELO: $1 from brain-dead MTA\n") if $debug >= 3;
        $parsed{allow_parse_fail}++;       # More brain-dead MTAs
        $parsed{from}{HELO} = $1;
        delete $expecting{after_from};
        next TOKEN;
      }

      if ($expecting{by} and /\G$RC{by},?/cg) {
        $self->diagnose("Got by: $1\n") if $debug >= 2;
        $last_section = 'by';

        $parsed{by}{whole}  = $1;
        $parsed{by}{domain} = $2;

        delete @expecting{qw/by/};
        delete @expecting{grep /^after_/, keys %expecting};
        $expecting{after_by}++;
        next TOKEN;
      }

      if ($expecting{after_by} and /\G($RC{domain_lit})/cg) {
        $self->diagnose("Got address from bad `by': $1\n") if $debug >= 3;
        $parsed{by}{address} = $1;
        delete $expecting{after_by};
        next TOKEN;
      }

      if ($expecting{after_by} and /\G(Sendmail)/cg) {
        $self->diagnose("Got MTA from bad `by': $1\n") if $debug >= 3;
        $parsed{by}{MTA} = $1;

        if ($expecting{via}) {
          $parsed{via}{via} = $1;
        }
        
        delete $expecting{after_by};
        next TOKEN;
      }

      if ($expecting{via} and /\G$RC{via}/cg) {
        $self->diagnose("Got via: $1\n") if $debug >= 2;
        $last_section = 'via';

        $parsed{via}{whole} = $1;
        $parsed{via}{via}   = $2;

        delete $expecting{via};
        delete @expecting{grep /^after_/, keys %expecting};
        $expecting{after_via}++;
        next TOKEN;
      }

      if ($expecting{after_via} and /\G\[$RC{ipv4_addr}\]/cg) {
        $self->diagnose("Got address from bad `via': $1\n") if $debug >= 3;
        $parsed{via}{address} = $1;
        delete $expecting{after_via};
        next TOKEN;
      }

      if (! $expecting{from} and /\Gfrom\s+stdin/cg) {
        $self->diagnose("Got `from stdin'\n") if $debug >= 3;
        $parsed{from}{stdin} = 'yep';
        next TOKEN;
      }

      if ($expecting{with} and
          m!
            \G((?i:with) \s
            (P:(stdio|smtp)/R:(inet|bind)_hosts/T:(smtp|inet_zone_bind_smtp)))
           !cgx) {
        $self->diagnose("Got weird with: $1\n") if $debug >= 2;
        $last_section = 'with';

        $parsed{with}{whole} = $1;
        $parsed{with}{with}  = $2;

        delete @expecting{grep /^after_/, keys %expecting};
        $expecting{after_with}++;
        # I've seen the `from' bit come after the `with' bit sometimes.
        # Why oh why ...
        $expecting{from}++;
        next TOKEN;
      }

      if ($expecting{with} and /\G$RC{with}/cg) {
        $self->diagnose("Got with: $1\n") if $debug >= 2;
        $last_section = 'with';

        $parsed{with}{whole} = $1;
        $parsed{with}{with}  = $2;
        $parsed{with}{with} .= $3 if $3;

        delete @expecting{grep /^after_/, keys %expecting};
        $expecting{after_with}++;
        # I've seen the `from' bit come after the `with' bit sometimes.
        # Why oh why ...
        $expecting{from}++;
        next TOKEN;
      }

      if ($expecting{after_with} && $parsed{with}{with}) {

        # Microsoft SMTPSVC uses two atoms -- yet /another/ example of
        # Microsoft not following standards ... *gasp*

        if ($parsed{with}{with} eq 'Microsoft') {
          if (/\GSMTPSVC(?:\(([\d\.]+)\))?/cg) {
            $self->diagnose("Got M\$ SMTPSVC version from bad `with'",
                            $1 ? ": $1" : '',
                            "\n")
              if $debug >= 3;
            delete $expecting{after_with};
            next TOKEN;
          }
          elsif (/\GMAPI/cg) {
            $self->diagnose("Got Microsoft MAPI from bad `with'\n")
              if $debug >= 3;
            delete $expecting{after_with};
            next TOKEN;
          }
        }

        # More brain damage ...

        if ($parsed{with}{with} eq 'Internet' and
            /\GMail Service\s*\(([\d\.]+)\)/cg) {
          $self->diagnose("Got Internet Mail Service version from bad `with': $1\n")
            if $debug >= 3;
          delete $expecting{after_with};
          next TOKEN;
        }

        if ($parsed{with}{with} eq 'WorldClient' and
            /\G($RC{domain_lit})/cg) {
          $self->diagnose("Got WorldClient address from bad `with': $1\n")
            if $debug >= 3;
          delete $expecting{after_with};
          next TOKEN;
        }

        if ($parsed{with}{with} eq 'Local' and
            /\GSMTP/cg) {
          $self->diagnose("Got Local SMTP from bad `with'\n")
            if $debug >= 3;
          delete $expecting{after_with};
          next TOKEN;
        }

      }

      if ($expecting{id} and /\G$RC{id}/cg) {
        $self->diagnose("Got id: $1\n") if $debug >= 2;
        $last_section = 'id';
        
        $parsed{id}{whole} = $1;
        $parsed{id}{id}    = $2;
        $parsed{id}{port}  = $3 if $3;

        delete @expecting{qw/by via with/};
        delete @expecting{grep /^after_/, keys %expecting};
        next TOKEN;
      }

      if ($expecting{convert} and /\G$RC{convert}/cg) {
        $self->diagnose("Got convert: $1\n") if $debug >= 2;
        $last_section = 'convert';
        
        $parsed{convert}{whole} = $1;
        
        delete @expecting{qw/from by via with convert/};
        delete @expecting{grep /^after_/, keys %expecting};
        next TOKEN;
      }

      if ($expecting{for} and
          /\G$RC{for}(\s+bugtraq\@securityfocus\.com)?/cgi) {
        $self->diagnose("Got for: $1\n") if $debug >= 2;
        $last_section = 'for';

        $parsed{for}{whole} = $1;
        $parsed{for}{for}   = $2;
        $parsed{for}{bugtraq} = $3 if $3;

        delete @expecting{qw/from by convert for/};
        delete @expecting{grep /^after_/, keys %expecting};
        next TOKEN;
      }

      if ($expecting{sent_by} and /\G$RC{sent_by}/cg) {
        $self->diagnose("Got sent by: $1\n") if $debug >= 2;
        $last_section = 'sent_by';        

        $parsed{sent_by}{whole}   = $1;
        $parsed{sent_by}{sent_by} = $2;

        delete @expecting{qw/from by via with convert for sent_by/};
        delete @expecting{grep /^after_/, keys %expecting};
        next TOKEN;
      }

      if ($expecting{date_time} and /\G((?:on\s+)?$RC{date_time})/cg) {
        $self->diagnose("Got date_time: $1\n") if $debug >= 2;
        $last_section = 'date_time';
        
        # Eugh.  This is horrible.  Maybe I should have used
        # Parse::RecDescent after all ...

        @{$parsed{date_time}}{qw/whole date_time week_day day_of_year rest/}
          = ($1, $2, $3, $4, $9);

        if (" $parsed{date_time}{day_of_year}" =~ $RC{year_day1}) {
          @{$parsed{date_time}}{qw/month_day month/} = ($1, $2);
        }
        elsif (" $parsed{date_time}{day_of_year}" =~ $RC{year_day2}) {
          @{$parsed{date_time}}{qw/month month_day/} = ($1, $2);
        }
        else {
          $self->diagnose("Couldn't parse day_of_year: <$parsed{date_time}{day_of_year}>");
          $parsed{parse_failed}++;
        }
        
        if ($parsed{date_time}{rest} =~ $RC{date_time1}) {
          @{$parsed{date_time}}{qw/hms hour minute second year/}
            = ($1, $2, $3, $4, $5);
          $parsed{date_time}{zone} = $6 if defined $6;
        }
        elsif ($parsed{date_time}{rest} =~ $RC{date_time2}) {
          @{$parsed{date_time}}{qw/hms hour minute second zone year/}
            = ($1, $2, $3, $4, $5, $10);
        }
        elsif ($parsed{date_time}{rest} =~ $RC{date_time3}) {
          @{$parsed{date_time}}{qw/year hms hour minute second/}
            = ($1, $2, $3, $4, $5);
          $parsed{date_time}{zone} = $6 if defined $6;
        }
        else {
          $self->diagnose("Couldn't parse rest of date_time: <$parsed{date_time}{rest}>");
          $parsed{parse_failed}++;
        }
          
        %expecting = (after_date_time => 1);
        next TOKEN;
      }

      if ($expecting{after_date_time} and /\G((mail.from|env.from).+)/cg) {
        $self->diagnose("Got random crap after date: $1\n") if $debug >= 3;
        $parsed{after_date_time} = $1;
        next TOKEN;
      }

      # Reluctantly allow semi-colons in random places
      if (/\G(;\s+)/cg) {
        $self->diagnose("Got semi-colon: <$1>\n") if $debug >= 7;
        next TOKEN;
      }

      my $old_pos = pos() || 0;
      my @start  = ($old_pos - 35, $old_pos);
      $start[0] = 0 if $start[0] < 0;
      my $length = $old_pos - $start[0];
      if (/\G(.{1,35})/cg) {
        $self->diagnose("** Ran out of things to match at position $old_pos:\n",
                        substr($_, $start[0], $length), "<<<\n",
                        ' ' x ($length - 3), ">>>$1\n\n")
          if $debug >= 1;
        $parsed{parse_failed}++;
      }
      last TOKEN;
    }
  }

  $self->{parse_tree} = \%parsed;

  my $failed = $parsed{parse_failed} && ! $parsed{allow_parse_fail};
  $self->{parsed_ok} = $failed ? 0 : 1;
  return $self;
}

##

=item * B<parsed_ok>

  if ($received->parsed_ok()) {
    ...
  }

Returns true if the parse succeed, or if it failed, but was permitted
to fail for some reason, such as encountering evidence of a known
broken (non-RFC822-compliant) format mid-parse.

=cut

sub parsed_ok {
  my $self = shift;
  croak "Header not parsed yet" unless $self->{parse_tree};
  return $self->{parsed_ok};
}

##

=item * B<parse_tree>

  my $parse_tree = $received->parse_tree();

Returns the actual parse tree, which is where you get all the useful
information.  It is returned as a hashref whose keys are strings like
`from', `by', `with', `id', `via' etc., corresponding to the
components of Received headers as defined by RFC822:

  received    =  "Received"    ":"            ; one per relay
                    ["from" domain]           ; sending host
                    ["by"   domain]           ; receiving host
                    ["via"  atom]             ; physical path
                   *("with" atom)             ; link/mail protocol
                    ["id"   msg-id]           ; receiver msg id
                    ["for"  addr-spec]        ; initial form
                     ";"    date-time         ; time received

The corresponding values are more hashrefs which are mini-parse-trees
for these individual components.  A typical parse tree looks something
like:

  {
   'by' => {
            'domain' => 'host5.hostingcheck.com',
            'whole' => 'by host5.hostingcheck.com',
            'comments' => [
                           '(8.9.3/8.9.3)'
                          ],
           },
   'date_time' => {
                   'year' => 2000,
                   'week_day' => 'Tue',
                   'minute' => 57,
                   'day_of_year' => '1 Feb',
                   'month_day' => ' 1',
                   'zone' => '-0500',
                   'second' => 18,
                   'hms' => '21:57:18',
                   'date_time' => 'Tue, 1 Feb 2000 21:57:18 -0500',
                   'hour' => 21,
                   'month' => 'Feb',
                   'rest' => '2000 21:57:18 -0500',
                   'whole' => 'Tue, 1 Feb 2000 21:57:18 -0500'
                  },
   'with' => {
              'with' => 'ESMTP',
              'whole' => 'with ESMTP'
             },
   'from' => {
              'domain' => 'mediacons.tecc.co.uk',
              'HELO' => 'tr909.mediaconsult.com',
              'from' => 'tr909.mediaconsult.com',
              'address' => '193.128.6.132',
              'comments' => [
                             '(mediacons.tecc.co.uk [193.128.6.132])',
                            ],
              'whole' => 'from tr909.mediaconsult.com (mediacons.tecc.co.uk [193.128.6.132])
'  
             },
   'id' => {
            'id' => 'VAA24164',
            'whole' => 'id VAA24164'
           },
   'comments' => [
                  '(mediacons.tecc.co.uk [193.128.6.132])',
                  '(8.9.3/8.9.3)'
                 ],
   'for' => {
             'for' => '<adam@spiers.net>',
             'whole' => 'for <adam@spiers.net>'
            },
   'whole' => 'from tr909.mediaconsult.com (mediacons.tecc.co.uk [193.128.6.132]) by host5.hostingcheck.com (8.9.3/8.9.3) with ESMTP id VAA24164 for <adam@spiers.net>; Tue, 1 Feb 2000 21:57:18 -0500'
  }

=cut

sub parse_tree {
  my $self = shift;
  croak "Header not parsed yet" unless $self->{parse_tree};
  return $self->{parse_tree};
}

=back

=head1 BUGS

Doesn't use Parse::RecDescent, which it maybe should.  

Doesn't offer a `strict RFC822' parsing mode.  To implement that would
be a royal pain in the arse, unless we move to Parse::RecDescent.

=head1 SEE ALSO

L<Mail::Field>, L<Mail::Header>

=head1 AUTHOR

Adam Spiers <adam@spiers.net>

=head1 LICENSE

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
