package Email::Address::Loose::EmailValidLoose;

# Note:
# The following code were copied from Email::Valid::Loose 0.05.
# http://search.cpan.org/perldoc?Email::Valid::Loose
# To make same behavior with Email::Valid::Loose about local-part.





use strict;
our $VERSION = '0.05';

# use Email::Valid 0.17; # Note: don't need
# use base qw(Email::Valid); # Note: don't need

# This is BNF from RFC822
my $esc         = '\\\\';
my $period      = '\.';
my $space       = '\040';
my $open_br     = '\[';
my $close_br    = '\]';
my $nonASCII    = '\x80-\xff';
my $ctrl        = '\000-\037';
my $cr_list     = '\n\015';
my $qtext       = qq/[^$esc$nonASCII$cr_list\"]/; # "
my $dtext       = qq/[^$esc$nonASCII$cr_list$open_br$close_br]/;
my $quoted_pair = qq<$esc>.qq<[^$nonASCII]>;
my $atom_char   = qq/[^($space)<>\@,;:\".$esc$open_br$close_br$ctrl$nonASCII]/;	# "
my $atom        = qq<$atom_char+(?!$atom_char)>;
my $quoted_str  = qq<\"$qtext*(?:$quoted_pair$qtext*)*\">; # "
my $word        = qq<(?:$atom|$quoted_str)>;
my $domain_ref  = $atom;
my $domain_lit  = qq<$open_br(?:$dtext|$quoted_pair)*$close_br>;
my $sub_domain  = qq<(?:$domain_ref|$domain_lit)>;
my $domain      = qq<$sub_domain(?:$period$sub_domain)*>;
my $local_part  = qq<$word(?:$word|$period)*>; # This part is modified

# Finally, the address-spec regex (more or less)
use vars qw($Addr_spec_re);
$Addr_spec_re   = qr<$local_part\@$domain>;

sub peek_local_part { qr/$local_part/ } # Note: added by Email::Address::Loose
1;
