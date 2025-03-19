use strict;
use warnings;

use Test::More;

use File::Spec;
require File::Spec::Win32;
@File::Spec::ISA = qw(File::Spec::Win32); # pretend to be Win32
use ExtUtils::Depends;

sub make_fake {
  my ($name, $path) = @_;
  my @parts = split /::/, $name;
  push @parts, qw(Install Files);
  my $req_name = join('/', @parts).".pm";
  $INC{$req_name} = "$path/$req_name";
}
make_fake('FakeUNC', '//server/share/file');
my $hash = ExtUtils::Depends::load('FakeUNC');
my $s = '[\\/]';
like $hash->{instpath}, qr/^${s}${s}server${s}share${s}file${s}FakeUNC${s}Install${s}?$/, 'preserves UNC server';

my @fakes = qw(FakeSpace1 FakeSpace2);
make_fake($_, 'C:/program files/perl/lib') for @fakes;
my $eud = ExtUtils::Depends->new(qw(Mymod), @fakes);
$hash = {$eud->get_makefile_vars};
is $hash->{INC}, '-I"C:/program files/perl/lib/FakeSpace1/Install/"  -I"C:/program files/perl/lib/FakeSpace2/Install/" ', 'space-quoted stuff no lose parts';

done_testing;
