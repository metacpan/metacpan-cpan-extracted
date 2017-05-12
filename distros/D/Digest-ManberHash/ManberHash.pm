package Digest::ManberHash;

=head1 NAME

Digest::ManberHash - a Perl package to calculate Manber Hashes

=head1 SYNOPSIS

  use Digest::ManberHash;
  
  $instance = Digest::ManberHash::new($maskbits, $prime, $charcount);

  $hash1 = $instance->DoHash($filename1);
  $hash2 = $instance->DoHash($filename2);

  $similarity = $instance->Compare($hash1, $hash2);

=head1 DESCRIPTION

=head2 Initialization

Use C<Digest::ManberHash::new>.
Parameters:

=over 4

=item maskbits

range 1 .. 30, default 11.

=item prime

range 3 .. 65537, default 7.

=item charcount

range 8 .. 32768, default 64.

=back

For a detailed description please read http://citeseer.nj.nec.com/manber94finding.html.


=head2 Calculating hashes

  $hash = $instance->DoHash($filename);

This gives an object, which has an hash of hash values stored within.


=head2 Comparing hashes

  $similarity = $instance->Compare($hash1, $hash2);

This gives an value of 0.0 .. 1.0, depending on the similariness.
Help wanted: The calculation could do better than now!!


=cut

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our @EXPORT = qw(
    HashFile
    new
    Compare
    );
our $VERSION = '0.7';


sub new
{
  my($class, $maskbits, $prime, $charcount)=@_;
  my($x,%a);

  $prime||=7;
  $maskbits||=11;
  $charcount||=64;

  $x=Init($prime,$maskbits,$charcount);
  %a=( "settings" => $x );

  bless \%a;
}

sub DoHash
{
  my($self,$filename)=@_;
  my($e,$f,%a,%b);

  %b=();
  ManberHash($self->{"settings"}, $filename, \%b );
  %a= ( "data" => \%b, "base" => $self);

  while (($e, $f) = each(%b))
  {
    $self->{"max"}{$e}=$f if $self->{"max"}{$e} < $f;
  }
  
  bless \%a;
}

sub Compare
{
  my($self,$file1,$file2)=@_;
  my(%keys,$a,$k,$c,$v,$m);

  #return 0 if (ref($self) !~ /^HASH/);
  die if $self ne $file1->{"base"} ||
$self ne $file2->{"base"};


  %keys=map { $_,1; } (keys %{$file1->{"data"}}, keys %{$file2->{"data"}});  
  $c=$a=$m=0;
  for $k (keys %keys)
  {
    $v = ($file1->{"data"}->{$k} - $file2->{"data"}->{$k});
#    $m += $self->{"max"}{$k} * $self->{"max"}{$k};
    $a += $v*$v;
    $c++;
#    print "$k = ",$self->{$k}," - ",$other->{$k},"($c, $a)\n";
  }

  return 0 if !$c;
#  1 - 6*$a/($c*$c*$c - $c);
#  1-sqrt($a)/$c;
  1/(1.0+$a);
}

bootstrap Digest::ManberHash $VERSION;

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
# 


