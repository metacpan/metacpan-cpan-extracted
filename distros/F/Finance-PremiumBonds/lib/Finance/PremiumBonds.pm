package Finance::PremiumBonds;

# $Id$

use 5.005000;
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Carp;

our $VERSION = '0.07';
our $checker_url  = 'http://www.nsandi.com/premium-bonds-have-i-won-ajax';
our $agent_string = "Perl/Finance::PremiumBonds $VERSION";
our $holdernumfield = '';

sub has_won {

    my $holdernum = shift
        or carp "No holder number supplied" and return;

    my $period = shift || 'this_month';

    my $ua = LWP::UserAgent->new( agent => $agent_string );
    my $resp = $ua->post(
        $checker_url,
        {
            field_premium_bond_number => $holdernum,
            field_premium_bond_period => $period || 'this_month',
        }
    );

    if (!$resp->is_success) {
        warn "Request failed - " . $resp->status_line;
        return;
    }

    my $resp_data = JSON::from_json($resp->decoded_content);

    if ($resp_data->{holder_number} eq 'is_invalid') {
        carp "Holder number not recognised by NS+I";
        return;
    }

    # TODO: it'd be nice to know what the status is for a win (just 'win'?) but
    # I've never won, so I don't know - so for now, just treat the absence of
    # 'no_win' as a win.
    return $resp_data->{status} eq 'no_win' ? 0 : 1;
}



1;
__END__

=head1 NAME

Finance::PremiumBonds - Perl extension to check Premium Bond holder's numbers

=head1 SYNOPSIS

  use Finance::PremiumBonds;
  
  if (defined(my $won = Finance::PremiumBonds::has_won($holder_number))) 
  {
      print "Looks like you " . ($won)? 'may have won' : 'have not won';
  } else {
      warn "An error occurred.";
  }
  

=head1 DESCRIPTION

Quick way to look up a Premium Bond holder's number on the National Savings
and Investments website to determine whether the holder has won any prizes
recently.

Now uses the AJAX interface the NS&I site uses, which returns some JSON so we
don't have to screen-scrape.

I've never won anything, so I don't know what the win response looks like
(if you have, please do help me by letting me know!), so it treats the absence
of the no_win status in the response as a win - this means it's possible that
it could falsely report positive if there are other statuses, e.g. "failed to
check" or similar.


=head1 FUNCTIONS

=over 4

=item has_won($holder_number, $period)

Checks whether $holder_number has won any prizes in the specified period.
Returns 1 if it looks like you've won, 0 if you haven't, or undef if it
failed to check.

The period is any period recognised by the NS&I site - at the time of writing,
that's C<this_month>, C<last_six_month>, C<unclaimed_prize>.  If it's not given,
then C<this_month> is used as a sensible default.

=back


=head1 AUTHOR

David Precious, E<lt>davidp@preshweb.co.ukE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2016 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=head1 LIMITATIONS

Currently, the module detects lack of a recognised "losing" response rather
than the presence of a winning response; without a holder's number which has
won something, I can't see what the winning responses look like.  Maybe my
meagre Premium Bonds investment will win something one day, then I can update
this module :)


=cut
