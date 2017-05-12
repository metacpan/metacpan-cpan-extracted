# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################


use Test;
BEGIN { plan tests => 122 };
use Mail::Verp;
ok(1); # If we made it this far, we're ok.

#########################

my $x = Mail::Verp->new;

ok(defined($x) && $x->isa('Mail::Verp'));


my $sender = 'local@source.com';
my @recipients = (
  'standard@example.com', [qw(local standard=example.com@source.com)],
  'remote+foo@example.com',  [qw(local remote+2Bfoo=example.com@source.com)],
  'node42!ann@old.example.com', [qw(local node42+21ann=old.example.com@source.com)],
  '=@example.com', [qw(local ==example.com@source.com)],
);

=pod

print STDERR "$s $r1 encodes -> ", $x->encode($s, $r1), "\n";
print STDERR "$s $r2 encodes -> ", $x->encode($s, $r2), "\n";

=cut

#Test various address types
for (my $i = 0; $i < @recipients; $i += 2) {
  my ($recipient, $verp) = @recipients[$i, $i+1];

  #test various separators, including default separator
  for my $sep (undef, qw(- +)) {

    #test use of object method and class method calls.
    my @refs = ('object' => $x, 'class' => 'Mail::Verp');

    for (my $j = 0; $j < @refs; $j += 2) {
      my ($encoder_name, $encoder) = @refs[$j, $j+1];

      my $expected = join(defined($sep) ? $sep : $encoder->separator, @$verp);
      $encoder->separator($sep) if defined $sep;
      
      my $sep_str = $sep || '';

      my $encoded = $encoder->encode($sender, $recipient);

      ok($encoded, $expected,
         "encoded address using $encoder_name instance with separator [$sep_str]");

      #decode each encoding with both an object and class method call.
      for (my $k = 0; $k < @refs; $k += 2) {
        my ($decoder_name, $decoder) = @refs[$k, $k+1];

        $decoder->separator($sep) if defined $sep;
        my ($decoded_sender, $decoded_recipient) = $decoder->decode($encoded);

        ok($decoded_sender, $sender,
          "encoded with $encoder_name and separator [$sep_str], decoded sender with $decoder_name");

        ok($decoded_recipient, $recipient,
          "encoded with $encoder_name and separator [$sep_str], decoded recipient with $decoder_name");
      }
    }
  }
}
