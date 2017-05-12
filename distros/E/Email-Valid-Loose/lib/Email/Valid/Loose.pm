package Email::Valid::Loose;

use strict;
our $VERSION = '0.05';

use Email::Valid 0.17;
use base qw(Email::Valid);

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

sub rfc822 {
    my $self = shift;
    my %args = $self->_rearrange([qw( address )], \@_);

    my $addr = $args{address} or return $self->details('rfc822');
    $addr = $addr->address if UNIVERSAL::isa($addr, 'Mail::Address');

    return $self->details('rfc822') unless $addr =~ m/^$Addr_spec_re$/o;
    return 1;
}
1;
__END__

=head1 NAME

Email::Valid::Loose - Email::Valid which allows dot before at mark

=head1 SYNOPSIS

  use Email::Valid::Loose;

  # same as Email::Valid
  my $addr     = 'read_rfc822.@docomo.ne.jp';
  my $is_valid = Email::Valid::Loose->address($addr);

=head1 DESCRIPTION

Email::Valid::Loose is a subclass of Email::Valid, which allows
. (dot) before @ (at-mark). It is invalid in RFC822, but is commonly
used in some of mobile phone addresses in Japan (like docomo.ne.jp or
jp-t.ne.jp).

=head1 IMPLEMENTATION

This module overrides C<rfc822> method in Email::Valid.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Email::Valid>, L<Mail::Address::MobileJp>

=cut
