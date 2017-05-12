package mvhashUtil;
use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Exporter();
use Hash::AutoHash::MultiValued;
use autohashUtil;

our @ISA=qw(Exporter);
our @EXPORT=qw(cmp_mvhash _cmp_mvhash test_class_methods @COMMON_SPECIAL_KEYS $VERBOSE);

# test contents of wrapper and external hash or object
# NG 09-07-29: generalize to allow any actual autohash or correct value
sub cmp_mvhash {
  my $pass=_cmp_mvhash(@_);
  pass($_[0]) if $pass && !$VERBOSE; # print if all tests passed and tests didn't print passes
  $pass;
}

sub _cmp_mvhash {
  # cmp_autohash does everything except test access via methods in array context
  my $pass=_cmp_autohash(@_);
  my($label,$actual,$correct)=@_;
  $label.=' via methods in array context';
  my(@ok,@fail);
  for my $key (keys %$correct) {
    my @actual_val=$actual->$key;
    my $correct_val=$correct->{$key};
    eq_deeply(\@actual_val,$correct_val)? push(@ok,$key): push(@fail,$key);
  }
#  $pass&&=report($label,@ok,@fail);
  $pass&&=_report($label,@ok,@fail);
  $pass;
}
1;
